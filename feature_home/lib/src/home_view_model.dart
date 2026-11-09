import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:core_health/core_health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'home_intent.dart';
import 'home_state.dart';

/// HomeScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
///
/// 数据流（2026-11-04 起）：L4 传感器直读（Step Detector → EventChannel
/// `steps/session` → [StepSessionCollector]）驱动今日步数与数据源状态行；
/// 提醒计数/记录仍为占位（core_reminder 域，W2 接入）。
/// 渠道差异：W2/L4 等开发字样仅 dev 渠道展示，master 文案产品化。
class HomeViewModel extends Notifier<HomeState> {
  StreamSubscription<int>? _stepsSub;

  @override
  HomeState build() {
    ref.onDispose(() {
      _stepsSub?.cancel();
      _stepsSub = null;
    });
    _connectStepCollector();
    return HomeState(
      // master 不暴露「数据源」等开发口径（正式版文案评审 2026-11-09）。
      dataSourceLabel:
          isDevBuild ? '正在连接数据源（L4）…' : '正在获取今日步数…',
      reminderCount: 0,
      completedCount: 0,
      nextEstimateText:
          isDevBuild ? '倒计时提醒引擎接入后提供（W2）' : '提醒倒计时即将上线',
    );
  }

  /// 接入 L4 采集器：先订阅（避免错过启动时的基线推送）再启动；
  /// start() 幂等（App 存活期常开），随后强制刷新一次基线保证有初值。
  Future<void> _connectStepCollector() async {
    final collector = GetIt.I<StepSessionCollector>();
    _stepsSub = collector.todaySteps.listen(
      (steps) {
        // 只在数据源状态行还是非实时文案时更新标签，避免每 tick 重建文案
        if (state.todaySteps != steps ||
            !state.dataSourceLabel.contains('实时')) {
          state = state.copyWith(
            todaySteps: steps,
            dataSourceLabel: _sourceLabel(collector),
          );
        }
      },
      onError: (Object error) {
        state = state.copyWith(
          dataSourceLabel: isDevBuild
              ? '数据源异常，下拉重试（$error）'
              : '步数暂不可用，点击重试',
        );
      },
    );
    await collector.start();
    await collector.refreshBaseline();
  }

  /// 数据源状态行：dev 渠道标注 L4 技术口径与计程起点便于排查；
  /// master 渠道只用用户可感知的产品文案——不出现「传感器/数据源」
  /// 等开发字样，也不暴露会话启动时间（正式版文案评审 2026-11-09）。
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

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(HomeIntent intent) async {
    switch (intent) {
      case RefreshPressed():
        // 重读本地当日基线，流会推送新值
        await GetIt.I<StepSessionCollector>().refreshBaseline();
    }
  }
}

/// 今日页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final homeViewModelProvider =
    NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
