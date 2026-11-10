package dev.healthassistant.app

import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
// Pro 期手表连接（health 插件回归）时，requestAuthorization 依赖
// ComponentActivity 的 registerForActivityResult；FlutterActivity 不在其
// 继承链上会导致授权弹窗永远不弹（W1 实证），故保留 FragmentActivity 基类。
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private lateinit var sensorManager: SensorManager
    private var pendingPermissionReply: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        // L4 正式采集通道：App 存活期持续监听 Step Detector，逐步推送 tick。
        // 有监听者时注册、取消时注销（EventChannel 语义），无常驻后台承诺。
        // （W1 时代的 debug/steps 诊断探针已完成使命移除，平台定论见
        // StepSessionStreamHandler 注释与 internal/任务看板 2026-11-04 条目。）
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "steps/session")
            .setStreamHandler(StepSessionStreamHandler())
        // 身体活动权限申请通道（W2：新装用户应用内自愈，免手动去系统设置）。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "steps/permission")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "request" -> {
                        if (checkSelfPermission(PERM) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        if (pendingPermissionReply != null) {
                            result.error("BUSY", "上一个权限请求尚未返回", null)
                            return@setMethodCallHandler
                        }
                        pendingPermissionReply = result
                        requestPermissions(arrayOf(PERM), REQUEST_PERMISSION_CODE)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_PERMISSION_CODE) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermissionReply?.success(granted)
        pendingPermissionReply = null
    }

    /// `steps/session` 流处理器：L4 步数采集的正式通道。
    ///
    /// 平台结论（2026-11-04 真机实证，代办 9a）：
    /// - 两个 Step Counter 变体均为死实现（恒 0）→ 无硬件累计值可用
    /// - Step Detector 逐 tick 可靠，与 MIUI 计步精确一致 → 走累加路线
    /// - 两个 Detector 变体对同一步同步 tick → 只监听单个变体，避免重计
    /// - 覆盖边界 = 本监听存续期间（进程死亡期间步数不补采）
    private inner class StepSessionStreamHandler : EventChannel.StreamHandler {
        private var sink: EventChannel.EventSink? = null
        private var listener: SensorEventListener? = null

        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
            if (checkSelfPermission(PERM) != PackageManager.PERMISSION_GRANTED) {
                events.error(
                    "PERMISSION_DENIED",
                    "缺少 ACTIVITY_RECOGNITION，请在系统设置中授予本应用身体活动权限",
                    null,
                )
                return
            }
            val sensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
            if (sensor == null) {
                events.error("NO_SENSOR", "TYPE_STEP_DETECTOR 对本应用不可见", null)
                return
            }
            listener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    // payload = 事件时间戳（开机纳秒），Dart 侧按 tick 计数
                    sink?.success(event.timestamp)
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
            }.also {
                val ok = sensorManager.registerListener(
                    it, sensor, SensorManager.SENSOR_DELAY_UI,
                )
                Log.i(TAG, "steps/session register [${describe(sensor)}] → $ok")
                if (!ok) {
                    listener = null
                    events.error("REGISTER_FAILED", "registerListener 返回 false", null)
                }
            }
        }

        override fun onCancel(arguments: Any?) {
            listener?.let { sensorManager.unregisterListener(it) }
            listener = null
            sink = null
            Log.i(TAG, "steps/session cancelled")
        }
    }

    private fun describe(sensor: Sensor?): String {
        if (sensor == null) return "null"
        // 注意：Sensor.getHandle() 已从新 SDK 公开 API 移除，不能引用；
        // 名称本身可唯一区分（dumpsys 按名称对照）。
        return sensor.name
    }

    private companion object {
        const val TAG = "StepSession"
        const val PERM = "android.permission.ACTIVITY_RECOGNITION"
        const val REQUEST_PERMISSION_CODE = 10421
    }
}
