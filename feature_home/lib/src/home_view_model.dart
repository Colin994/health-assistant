import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:core_health/core_health.dart';
import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'home_intent.dart';
import 'home_state.dart';

/// HomeScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
///
/// 数据流：
/// - 步数：L4 传感器直读（StepSessionCollector）；
/// - 提醒：ReminderEngine 状态流（下次提醒/chips 与实际触发同源）+
///   reminder_log 计数流；
/// - 渠道差异：L4 等开发字样仅 dev 渠道展示。
class HomeViewModel extends Notifier<HomeState> {
  StreamSubscription<int>? _stepsSub;
  StreamSubscription<EngineState>? _engineSub;
  StreamSubscription<({int fired, int done})>? _countsSub;
  ReminderEngine? _engine;
  var _permissionAutoRetried = false;

  @override
  HomeState build() {
    ref.onDispose(() {
      _stepsSub?.cancel();
      _stepsSub = null;
      _engineSub?.cancel();
      _engineSub = null;
      _countsSub?.cancel();
      _countsSub = null;
      // Home provider 常驻 IndexedStack，销毁即应用关闭：
      // 停引擎（取消周期 Timer + 全量落盘）。测试环境由此满足
      // 「无挂起 Timer」约束。
      try {
        _engine?.stop();
      } catch (_) {
        // 引擎不可用/已停止：忽略。
      }
    });
    _connectStepCollector();
    _connectReminderEngine();
    return HomeState(
      dataSourceLabel:
          isDevBuild ? '正在连接数据源（L4）…' : '正在获取今日步数…',
    );
  }

  /// 接入 L4 采集器：先订阅（避免错过启动时的基线推送）再启动。
  Future<void> _connectStepCollector() async {
    final collector = GetIt.I<StepSessionCollector>();
    _stepsSub = collector.todaySteps.listen(
      (steps) {
        if (!ref.mounted) return;
        if (state.todaySteps != steps ||
            !state.dataSourceLabel.contains('更新中')) {
          state = state.copyWith(
            todaySteps: steps,
            dataSourceLabel: _sourceLabel(collector),
          );
        }
      },
      onError: (Object error) async {
        if (!ref.mounted) return;
        final permDenied =
            error is PlatformException && error.code == 'PERMISSION_DENIED';
        state = state.copyWith(
          dataSourceLabel: permDenied
              ? (isDevBuild
                  ? '数据源异常：缺身体活动权限（点右侧刷新申请）'
                  : '步数权限未开启，点击右侧开启')
              : (isDevBuild
                  ? '数据源异常，下拉重试（$error）'
                  : '步数暂不可用，点击重试'),
        );
        // 应用内自愈（W2）：首次权限缺失自动申请一次，获批即重启采集。
        if (permDenied && !_permissionAutoRetried) {
          _permissionAutoRetried = true;
          final ok = await GetIt.I<StepSessionCollector>().ensurePermission();
          if (ok && ref.mounted) {
            await GetIt.I<StepSessionCollector>().restart();
          }
        }
      },
    );
    await collector.start();
    await collector.refreshBaseline();
    _watchActivityBursts();
  }

  /// 活动打断（验收 #3）：60 秒内 ≥10 步判定为走动 → 重置久坐倒计时。
  final List<DateTime> _recentTicks = [];
  void _watchActivityBursts() {
    // StepSessionCollector.todaySteps 每推一值即一个 Detector tick（≈1 步）。
    // 引擎 onActivityBurst 幂等（仅久坐类重置），无需节流。
    _stepsSub?.onData((steps) {
      _onStepTick();
    });
  }

  void _onStepTick() {
    final now = DateTime.now();
    _recentTicks.add(now);
    _recentTicks.removeWhere((t) => now.difference(t) > const Duration(seconds: 60));
    if (_recentTicks.length >= 10) {
      _engine?.onActivityBurst();
      _recentTicks.clear();
    }
  }

  /// 接入提醒引擎：状态流 → chips/下次提醒；日志流 → 计数卡。
  Future<void> _connectReminderEngine() async {
    final ReminderEngine engine;
    try {
      engine = GetIt.I<ReminderEngine>();
    } catch (_) {
      return; // DI 未就绪（理论不可达）：保持占位不影响其余模块。
    }
    _engine = engine;
    if (!engine.isRunning) {
      await engine.start();
    }
    _engineSub = engine.states.listen((s) => _applyEngineState(engine, s));
    _applyEngineState(engine, engine.state);

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    _countsSub = GetIt.I<ReminderPersistence>()
        .watchDayCounts(dayStart)
        .listen((c) {
      if (!ref.mounted) return;
      state = state.copyWith(reminderCount: c.fired, completedCount: c.done);
    });
  }

  void _applyEngineState(ReminderEngine engine, EngineState s) {
    // provider 可能在异步间隙被重建（如时钟跳变触发的 rebuild）：
    // 未初始化窗口写 state 会抛「uninitialized provider」。
    if (!ref.mounted) return;
    final chips = <ReminderChipView>[];
    final nexts = <NextReminderView>[];
    final now = DateTime.now();
    for (final kind in ReminderKind.values) {
      final snap = s.kinds[kind];
      if (snap == null) continue;
      final name = _kindLabel(kind);
      switch (snap.phase) {
        case ReminderPhase.off:
        case ReminderPhase.disabled:
          continue; // 关闭/禁用：chip 与下次提醒行都不出现。
        case ReminderPhase.mutedToday:
          chips.add(ReminderChipView(
            kind: kind,
            label: name,
            sub: '今天已免打扰',
            dimmed: true,
          ));
          nexts.add(NextReminderView(
            kind: kind,
            label: name,
            timeText: '今天已免打扰',
          ));
        case ReminderPhase.snoozed:
          final at = snap.nextFireAt;
          chips.add(ReminderChipView(
            kind: kind,
            label: name,
            sub: '已稍后',
            dimmed: true,
          ));
          nexts.add(NextReminderView(
            kind: kind,
            label: name,
            timeText: '已稍后 · ${_hm(at ?? now)}',
          ));
        case ReminderPhase.pausedMute:
          final at = snap.nextFireAt;
          chips.add(ReminderChipView(
            kind: kind,
            label: name,
            sub: '静音中',
            dimmed: true,
          ));
          nexts.add(NextReminderView(
            kind: kind,
            label: name,
            timeText: '静音中 · ${_hm(at ?? now)} 前后恢复',
          ));
        case ReminderPhase.cooldown:
          chips.add(ReminderChipView(
            kind: kind,
            label: name,
            sub: '冷却中',
            dimmed: true,
          ));
          nexts.add(NextReminderView(
            kind: kind,
            label: name,
            timeText: _timeText(snap.nextFireAt, now),
          ));
        case ReminderPhase.counting:
          chips.add(ReminderChipView(
            kind: kind,
            label: '$name · ${_remainingText(snap.nextFireAt, now)}',
            sub: null,
            dimmed: false,
          ));
          nexts.add(NextReminderView(
            kind: kind,
            label: name,
            timeText: _timeText(snap.nextFireAt, now),
          ));
      }
    }
    state = state.copyWith(
      chips: chips,
      nextReminders: nexts,
      showDeEscalationBanner:
          s.deEscalated && engine.config.deEscalationAckDay != _dayKey(now),
    );
  }

  /// 数据源状态行：dev 渠道标注 L4 技术口径与计程起点便于排查；
  /// master 渠道只用用户可感知的产品文案。
  String _sourceLabel(StepSessionCollector collector) {
    if (!isDevBuild) {
      return '今日步数 · 实时更新中';
    }
    final startedAt = collector.startedAt;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final from =
        '${twoDigits(startedAt?.hour ?? 0)}:${twoDigits(startedAt?.minute ?? 0)}';
    if (startedAt == null) return '传感器直读（L4）· 实时计步中';
    return '传感器直读（L4）· $from 起实时计步';
  }

  static String _kindLabel(ReminderKind kind) => switch (kind) {
        ReminderKind.sedentary => '久坐',
        ReminderKind.water => '喝水',
        ReminderKind.eye => '护眼',
      };

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _dayKey(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// ≥60 分显示时刻，<60 分显示剩余分钟。
  static String _timeText(DateTime? at, DateTime now) {
    if (at == null) return '—';
    final left = at.difference(now).inMinutes;
    if (left < 1) return '马上';
    if (left < 60) return '$left 分后';
    return _hm(at);
  }

  static String _remainingText(DateTime? at, DateTime now) {
    if (at == null) return '…';
    final left = at.difference(now).inMinutes;
    return left < 1 ? '马上' : '$left 分后';
  }

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(HomeIntent intent) async {
    switch (intent) {
      case RefreshPressed():
        final collector = GetIt.I<StepSessionCollector>();
        // 权限缺失态的点击 = 申请并重启采集（而非仅刷新基线）。
        if (state.dataSourceLabel.contains('权限未开启')) {
          final ok = await collector.ensurePermission();
          if (ok) {
            await collector.restart();
            return;
          }
        }
        await collector.refreshBaseline();
      case DeEscalationAcknowledged():
        if (!ref.mounted) return;
        final engine = _engine;
        if (engine == null) return;
        final now = DateTime.now();
        final repo = GetIt.I<ReminderConfigRepository>();
        final config =
            (await repo.load()).copyWith(deEscalationAckDay: _dayKey(now));
        await repo.save(config);
        await engine.onSettingsChanged();
        state = state.copyWith(showDeEscalationBanner: false);
    }
  }
}

/// 今日页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
