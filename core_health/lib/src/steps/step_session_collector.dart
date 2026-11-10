import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L4 步数会话采集器（2026-11-04 真机平台定论的正式落地，代办 P2a-9）。
///
/// 平台事实（小米 HyperOS 3.0.15 / UNISOC，一手实证）：
/// - Step Counter 两个变体均为死实现（恒 0）→ 无硬件累计值兜底
/// - Step Detector 逐步 tick 可靠且与 MIUI 计步精确一致 → 本采集器的源头
/// - 覆盖边界 = 采集器存续期间；进程死亡期间步数不补采（UI 需诚实标注）
///
/// 数据流（2026-11-09 起 v5 口径，与 Health Connect 解耦）：
/// Detector tick（EventChannel `steps/session`）
///   ├→ 实时：[todaySteps] 推送「本地当日累计 + 本次存活期 tick」
///   └→ 落盘：缓冲达到步数阈值或静默超时 → 当日累计写入 SharedPreferences，
///            重启后从该基线续计，跨日自动清零
///
/// 基线不再读写健康中枢：正式版零 HC 依赖、零系统授权弹窗；
/// Pro 期手表连接上线后，基线可升级为健康中枢读回（吸收穿戴设备写入）。
@LazySingleton()
class StepSessionCollector {
  StepSessionCollector();

  static const EventChannel _channel = EventChannel('steps/session');
  static const MethodChannel _permissionChannel =
      MethodChannel('steps/permission');

  /// 落盘键：`{date: 'yyyy-MM-dd', steps: 当日累计}`。
  static const String _prefsKey = 'l4_step_baseline';

  /// 落盘阈值：当前缓冲达到该步数即写入本地基线。
  static const int _flushStepThreshold = 10;

  /// 落盘阈值：静默达到该时长即把当前缓冲写入本地基线（收尾一段步行）。
  static const Duration _flushGap = Duration(seconds: 30);

  final StreamController<int> _todayStepsController =
      StreamController<int>.broadcast();

  StreamSubscription<dynamic>? _tickSub;
  Timer? _gapTimer;

  int _persistedToday = 0;
  int _liveTicks = 0;
  int _buffer = 0;
  DateTime? _bufferStart;
  String _dayKey = '';
  bool _running = false;

  /// 今日步数推送流（本地当日累计 + 本次存活期全部 tick）。
  Stream<int> get todaySteps => _todayStepsController.stream;

  /// 是否已启动（App 存活期常开，幂等）。
  bool get isRunning => _running;

  /// 本次计程起点（null = 未启动）。
  ///
  /// 平台无硬件累计值兜底（Counter 死实现），无法回溯监听启动前的步数；
  /// UI 必须展示该起点以诚实标注口径。
  DateTime? get startedAt => _startedAt;

  DateTime? _startedAt;

  /// 启动采集：恢复本地当日基线 → 订阅 Detector tick 流。
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _startedAt = DateTime.now();
    _dayKey = _dayKeyOf(DateTime.now());
    await _restoreBaseline(emit: false);
    if (!_running) return; // await 期间可能已被 stop
    _emit();
    _tickSub = _channel.receiveBroadcastStream().listen(
      (_) => _onTick(),
      onError: (Object error) {
        AppLogger.error('Detector tick 流错误', tag: 'step_collector', error: error);
        if (!_todayStepsController.isClosed) {
          _todayStepsController.addError(error);
        }
      },
    );
    AppLogger.info('L4 采集启动（本地当日基线 $_persistedToday）', tag: 'step_collector');
  }

  /// 刷新基线（下拉刷新入口）：重读本地当日累计；读取失败保持现值。
  Future<void> refreshBaseline() async {
    await _restoreBaseline(emit: true);
  }

  Future<void> _restoreBaseline({required bool emit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dayKeyOf(DateTime.now());
      if (prefs.getString(_prefsKey) == today) {
        _persistedToday = prefs.getInt(_prefsKey) ?? 0;
      } else {
        // 跨日：昨日累计清零。
        _persistedToday = 0;
      }
      _dayKey = today;
      if (emit) _emit();
    } catch (error) {
      // 基线读取失败（如测试环境无插件）→ 保持现值起步，不影响实时计步。
      AppLogger.error('今日步数基线读取失败，保持现值', tag: 'step_collector', error: error);
    }
  }

  void _onTick() {
    final today = _dayKeyOf(DateTime.now());
    if (today != _dayKey) {
      // 跨日边界：累计与缓冲归零，当天从本 tick 重新起算。
      _dayKey = today;
      _persistedToday = 0;
      _liveTicks = 0;
      _buffer = 0;
      _bufferStart = null;
    }
    _bufferStart ??= DateTime.now();
    _liveTicks++;
    _buffer++;
    _emit();
    _gapTimer?.cancel();
    if (_buffer >= _flushStepThreshold) {
      _flush(reason: '步数阈值');
    } else {
      _gapTimer = Timer(_flushGap, () => _flush(reason: '静默超时'));
    }
  }

  Future<void> _flush({required String reason}) async {
    _gapTimer?.cancel();
    _gapTimer = null;
    final start = _bufferStart;
    final count = _buffer;
    _buffer = 0;
    _bufferStart = null;
    if (count <= 0 || start == null) return;
    _persistedToday += count;
    final end = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _dayKey);
      await prefs.setInt(_prefsKey, _persistedToday);
      AppLogger.debug(
        'L4 会话落盘($reason)：$count 步 '
        '${start.hour}:${start.minute.toString().padLeft(2, '0')} → '
        '${end.hour}:${end.minute.toString().padLeft(2, '0')} '
        '当日累计=$_persistedToday',
        tag: 'step_collector',
      );
    } catch (error) {
      // 写入失败不回滚计数：今日步数展示不受影响（内存累计照常推进），
      // 损失仅限重启后续计基线少一段。
      AppLogger.error(
        'L4 当日累计落盘失败（重启后可能少计 $count 步）',
        tag: 'step_collector',
        error: error,
      );
    }
  }

  void _emit() {
    if (!_todayStepsController.isClosed) {
      _todayStepsController.add(_persistedToday + _liveTicks);
    }
  }

  /// 当日键（yyyy-MM-dd，本地时区）。
  String _dayKeyOf(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  /// 申请「身体活动」权限（新装用户应用内自愈；已授权直接返回 true）。
  Future<bool> ensurePermission() async {
    try {
      return await _permissionChannel.invokeMethod<bool>('request') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 重启采集（权限授予后重新订阅 Detector 流）。
  Future<void> restart() async {
    await _tickSub?.cancel();
    _tickSub = null;
    _running = false;
    await start();
  }

  /// 停止采集（App 退出/测试用；常驻单例场景无需调用）。
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _tickSub?.cancel();
    _tickSub = null;
    await _flush(reason: 'stop');
    await _todayStepsController.close();
  }
}
