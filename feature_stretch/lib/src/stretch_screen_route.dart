import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'action_detail_screen_route.dart';
import 'stretch_event.dart';
import 'stretch_screen.dart';
import 'stretch_view_model.dart';

/// 拉伸页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// W3 后此页由通知深链 `healthassistant://stretch?advice_id=` 直达。
class StretchScreenRoute extends StatefulWidget {
  const StretchScreenRoute({super.key});

  /// 跳转到拉伸页。
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StretchScreenRoute()),
    );
  }

  @override
  State<StretchScreenRoute> createState() => _StretchScreenRouteState();
}

class _StretchScreenRouteState extends State<StretchScreenRoute> {
  late final StretchViewModel _viewModel;
  StreamSubscription<StretchEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<StretchViewModel>();
    _eventSubscription = _viewModel.onEvent.listen(_handleEvent);
  }

  void _handleEvent(StretchEvent event) {
    if (!mounted) {
      return;
    }
    switch (event) {
      case StretchFinished():
        Navigator.of(context).maybePop();
      case StretchSkipped():
        Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => StretchScreen(
        state: _viewModel.state,
        onIntent: _viewModel.handleIntent,
        onActionTapped: ActionDetailScreenRoute.push,
      ),
    );
  }
}
