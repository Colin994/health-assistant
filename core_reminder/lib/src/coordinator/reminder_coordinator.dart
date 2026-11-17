import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:core_model/core_model.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../copy/reminder_copy_provider.dart';
import '../engine/reminder_engine.dart';
import '../notify/reminder_notification_service.dart';

/// schedule-next 编排（技术设计文档 §9.5）：
///
/// - App 存活期：引擎 tick 到点 → 立即弹通知；
/// - 同时每类只排「下一次」系统闹钟（被杀期兜底；触发/变更/开屏重排）；
/// - 通知 payload 即携带 kind/advice_id（W3 深链直接复用）；
/// - 生命周期 paused → 引擎全量落盘；resumed → 重读设置重算。
@LazySingleton()
class ReminderCoordinator with WidgetsBindingObserver {
  ReminderCoordinator(this._engine, this._notif, this._copy);

  final ReminderEngine _engine;
  final ReminderNotificationService _notif;
  final ReminderCopyProvider _copy;

  StreamSubscription<FireSignal>? _fireSub;
  StreamSubscription<EngineState>? _stateSub;
  final Map<ReminderKind, int> _lastScheduledMinute = {};
  var _started = false;

  static int _idOf(ReminderKind kind) => switch (kind) {
        ReminderKind.sedentary => ReminderNotificationIds.sedentaryId,
        ReminderKind.water => ReminderNotificationIds.waterId,
        ReminderKind.eye => ReminderNotificationIds.eyeId,
      };

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _notif.init();
    await _notif.requestExactAlarmsIfNeeded();
    WidgetsBinding.instance.addObserver(this);

    _fireSub = _engine.fires.listen((f) {
      // App 存活期到点：立即通知 + 引擎已自动排下一轮，重排闹钟。
      unawaited(
        _notif.showNow(
          id: _idOf(f.kind),
          title: f.copy.title,
          body: f.copy.body,
          payload: buildReminderPayload(f.kind.name, f.adviceId),
        ),
      );
      unawaited(_rescheduleAll());
    });

    _stateSub = _engine.states.listen((_) => unawaited(_rescheduleAll()));

    await _engine.start();
  }

  /// 设置变更入口（设置页/演示节奏切换后调用）。
  Future<void> onSettingsChanged() async {
    await _engine.onSettingsChanged();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_engine.persistAll());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_engine.onSettingsChanged());
    }
  }

  Future<void> _rescheduleAll() async {
    final state = _engine.state;
    final schedulable = {
      ReminderPhase.counting,
      ReminderPhase.pausedMute,
      ReminderPhase.cooldown,
      ReminderPhase.snoozed,
    };
    for (final kind in ReminderKind.values) {
      final snap = state.kinds[kind];
      final id = _idOf(kind);
      if (snap == null || !schedulable.contains(snap.phase) ||
          snap.nextFireAt == null) {
        _lastScheduledMinute.remove(kind);
        await _notif.cancel(id);
        continue;
      }
      final at = snap.nextFireAt!;
      final minuteKey = at.millisecondsSinceEpoch ~/ 60000;
      if (_lastScheduledMinute[kind] == minuteKey) continue; // 未变不重排。
      _lastScheduledMinute[kind] = minuteKey;
      final copy = _engineCopy(kind);
      await _notif.scheduleAt(
        id: id,
        at: at,
        title: copy.title,
        body: copy.body,
        payload: buildReminderPayload(kind.name, 'scheduled'),
      );
    }
  }

  ReminderCopy _engineCopy(ReminderKind kind) {
    // 排程时的预置文案（无标签上下文的兜底；触发瞬间若 App 存活，
    // showNow 会带按标签匹配的文案覆盖展示）。
    return _copy.copyFor(kind, const {});
  }

  Future<void> shutdown() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _fireSub?.cancel();
    await _stateSub?.cancel();
    await _engine.stop();
    AppLogger.info('协调器已停止', tag: 'coordinator');
  }
}
