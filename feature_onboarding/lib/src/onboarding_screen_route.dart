import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_event.dart';
import 'onboarding_screen.dart';
import 'onboarding_view_model.dart';

/// 引导页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// - 对外只暴露静态跳转方法，路由聚合在 app 壳模块；
/// - 对内负责：watch provider 驱动 Screen 重建、
///   订阅一次性 [OnboardingEvent] 完成导航；
/// - VM 生命周期交给 provider（页面 pop 后自动销毁并关闭事件流）。
class OnboardingScreenRoute extends ConsumerStatefulWidget {
  const OnboardingScreenRoute({super.key});

  /// 跳转到引导页。
  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const OnboardingScreenRoute()),
    );
  }

  @override
  ConsumerState<OnboardingScreenRoute> createState() =>
      _OnboardingScreenRouteState();
}

class _OnboardingScreenRouteState extends ConsumerState<OnboardingScreenRoute> {
  StreamSubscription<OnboardingEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        ref.read(onboardingViewModelProvider.notifier).onEvent.listen(
              _handleEvent,
            );
  }

  void _handleEvent(OnboardingEvent event) {
    if (!mounted) {
      return;
    }
    // 多实例堆叠保护：仅栈顶路由响应事件（provider 为单实例）。
    if (ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
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
    final viewModel = ref.watch(onboardingViewModelProvider.notifier);
    final state = ref.watch(onboardingViewModelProvider);
    return OnboardingScreen(
      state: state,
      onIntent: viewModel.handleIntent,
    );
  }
}
