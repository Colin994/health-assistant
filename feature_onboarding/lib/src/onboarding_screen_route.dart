import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'onboarding_event.dart';
import 'onboarding_screen.dart';
import 'onboarding_view_model.dart';

/// 引导页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// - 对外只暴露静态跳转方法，路由聚合在 app 壳模块；
/// - 对内负责：从 get_it 取 ViewModel、驱动 Screen 重建、
///   订阅一次性 [OnboardingEvent] 完成导航；
/// - ViewModel 为工厂注册（get_it 不持有实例），随页面销毁自然回收。
class OnboardingScreenRoute extends StatefulWidget {
  const OnboardingScreenRoute({super.key});

  /// 跳转到引导页。
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreenRoute()),
    );
  }

  @override
  State<OnboardingScreenRoute> createState() => _OnboardingScreenRouteState();
}

class _OnboardingScreenRouteState extends State<OnboardingScreenRoute> {
  late final OnboardingViewModel _viewModel;
  StreamSubscription<OnboardingEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<OnboardingViewModel>();
    _eventSubscription = _viewModel.onEvent.listen(_handleEvent);
  }

  void _handleEvent(OnboardingEvent event) {
    switch (event) {
      case OnboardingCompleted():
        // W2 接入 app 路由表后改为命名路由跳转；当前直接退出引导页。
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
      builder: (context, _) => OnboardingScreen(
        state: _viewModel.state,
        onIntent: _viewModel.handleIntent,
      ),
    );
  }
}
