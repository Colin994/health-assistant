import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'privacy_screen.dart';
import 'settings_screen.dart';
import 'settings_view_model.dart';

/// 设置页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建；
/// 开发者条目由 app 壳注入（v7：提醒设置已移入「我的」）。
class SettingsScreenRoute extends ConsumerWidget {
  const SettingsScreenRoute({
    super.key,
    this.devEntries = const [],
  });

  /// 开发者入口区条目（label + onTap，由 app 壳注入）。
  final List<(String, VoidCallback)> devEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    return SettingsScreen(
      state: state,
      devEntries: devEntries,
      onOpenPrivacy: () => PrivacyScreenRoute.push(context),
    );
  }
}
