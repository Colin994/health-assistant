import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'home_view_model.dart';

/// 今日页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建，不经 Navigator push。
/// Riverpod 接管后：watch provider 驱动重建，get_it 不再注册 VM。
class HomeScreenRoute extends ConsumerWidget {
  const HomeScreenRoute({
    super.key,
    this.onQuickStretch,
    this.onOpenReminderSettings,
  });

  /// 快捷开始拉伸（开发入口，由 app 壳注入）。
  final VoidCallback? onQuickStretch;

  /// 点击提醒 chips 跳「提醒设置」（交互文档 §4.1，由 app 壳注入）。
  final VoidCallback? onOpenReminderSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider.notifier);
    final state = ref.watch(homeViewModelProvider);
    return HomeScreen(
      state: state,
      onIntent: viewModel.handleIntent,
      onQuickStretch: onQuickStretch,
      onOpenReminderSettings: onOpenReminderSettings,
    );
  }
}
