import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_screen.dart';
import 'settings_view_model.dart';

/// 设置页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建；
/// 开发者条目与提醒设置跳转由 app 壳注入。
class SettingsScreenRoute extends ConsumerWidget {
  const SettingsScreenRoute({
    super.key,
    required this.onReminderSettings,
    this.devEntries = const [],
  });

  /// 提醒设置入口（跳 feature_profile 的提醒设置页）。
  final VoidCallback onReminderSettings;

  /// 开发者入口区条目（label + onTap，由 app 壳注入）。
  final List<(String, VoidCallback)> devEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    return SettingsScreen(
      state: state,
      onReminderSettings: onReminderSettings,
      devEntries: devEntries,
    );
  }
}
