import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_state.dart';

/// SettingsScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  /// W2：接 PackageInfo 读取真实版本号、接 ReminderRepository 同步提醒配置。
}

/// 设置页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);
