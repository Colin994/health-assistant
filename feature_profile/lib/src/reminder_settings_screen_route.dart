import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_settings_screen.dart';
import 'reminder_settings_view_model.dart';

/// 提醒设置跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
class ReminderSettingsScreenRoute extends ConsumerWidget {
  const ReminderSettingsScreenRoute({super.key});

  /// 跳转到提醒设置。
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ReminderSettingsScreenRoute(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(reminderSettingsViewModelProvider.notifier);
    final state = ref.watch(reminderSettingsViewModelProvider);
    return ReminderSettingsScreen(
      state: state,
      onIntent: viewModel.handleIntent,
    );
  }
}
