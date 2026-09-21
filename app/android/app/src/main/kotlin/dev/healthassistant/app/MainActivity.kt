package dev.healthassistant.app

// health 插件的 requestAuthorization 依赖 ComponentActivity 的
// registerForActivityResult；FlutterActivity 不在 ComponentActivity
// 继承链上，会导致权限启动器创建失败（授权弹窗永远不弹）。
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
