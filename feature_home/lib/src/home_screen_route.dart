import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_intent.dart';
import 'home_screen.dart';
import 'home_view_model.dart';

/// 今日页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建，不经 Navigator push。
/// Riverpod 接管后：watch provider 驱动重建，get_it 不再注册 VM。
class HomeScreenRoute extends ConsumerStatefulWidget {
  const HomeScreenRoute({
    super.key,
    this.onQuickStretch,
    this.onOpenReminderSettings,
    this.gardenRefreshTick = 0,
  });

  /// 快捷开始拉伸（开发入口，由 app 壳注入）。
  final VoidCallback? onQuickStretch;

  /// 点击提醒 chips 跳「提醒设置」（交互文档 §4.1，由 app 壳注入）。
  final VoidCallback? onOpenReminderSettings;

  /// 花园刷新信号（递增）：变化即请求重读花园剩余次数。
  /// 由壳层在游戏返回后递增（IndexedStack 常驻页不会自动重建）。
  final int gardenRefreshTick;

  @override
  ConsumerState<HomeScreenRoute> createState() => _HomeScreenRouteState();
}

class _HomeScreenRouteState extends ConsumerState<HomeScreenRoute> {
  int _lastTick = -1;

  @override
  void initState() {
    super.initState();
    _lastTick = widget.gardenRefreshTick;
  }

  @override
  void didUpdateWidget(HomeScreenRoute old) {
    super.didUpdateWidget(old);
    if (widget.gardenRefreshTick != _lastTick) {
      _lastTick = widget.gardenRefreshTick;
      ref
          .read(homeViewModelProvider.notifier)
          .handleIntent(const GardenQuotaRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider.notifier);
    final state = ref.watch(homeViewModelProvider);
    return HomeScreen(
      state: state,
      onIntent: viewModel.handleIntent,
      onQuickStretch: widget.onQuickStretch,
      onOpenReminderSettings: widget.onOpenReminderSettings,
      gardenRefreshTick: widget.gardenRefreshTick,
    );
  }
}
