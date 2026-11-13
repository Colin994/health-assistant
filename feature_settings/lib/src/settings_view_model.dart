import 'package:base_utils/base_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_state.dart';

/// SettingsScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
///
/// W2 落地：PackageInfo 读取真实版本号（关于行展示）。
class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadVersion();
    return const SettingsState();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!ref.mounted) return;
      state = state.copyWith(version: info.version);
    } catch (error) {
      // 读取失败保持默认 0.1.0。
      AppLogger.error('版本信息读取失败（保持占位版本）', tag: 'settings', error: error);
    }
  }
}

/// 设置页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(SettingsViewModel.new);
