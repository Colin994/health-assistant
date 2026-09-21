import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'reminder_settings_screen.dart';
import 'reminder_settings_view_model.dart';

/// 提醒设置跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
class ReminderSettingsScreenRoute extends StatefulWidget {
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
  State<ReminderSettingsScreenRoute> createState() =>
      _ReminderSettingsScreenRouteState();
}

class _ReminderSettingsScreenRouteState
    extends State<ReminderSettingsScreenRoute> {
  late final ReminderSettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<ReminderSettingsViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ReminderSettingsScreen(
        state: _viewModel.state,
        onIntent: _viewModel.handleIntent,
      ),
    );
  }
}
