import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'action_detail_screen_route.dart';
import 'stretch_event.dart';
import 'stretch_screen.dart';
import 'stretch_view_model.dart';

/// 拉伸页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// W3 后此页由通知深链 `healthassistant://stretch?advice_id=` 直达。
/// 事件流订阅保持「initState 订阅 / dispose 取消」语义；VM 生命周期
/// 交给 provider（页面 pop 后自动销毁并关闭事件流）。
class StretchScreenRoute extends ConsumerStatefulWidget {
  const StretchScreenRoute({super.key, this.onOpenGarden});

  /// 慢植物花园入口(由 app 壳注入,避免 feature 间横向依赖)。
  final VoidCallback? onOpenGarden;

  /// 跳转到拉伸页。
  static Future<void> push(BuildContext context, {VoidCallback? onOpenGarden}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StretchScreenRoute(onOpenGarden: onOpenGarden),
      ),
    );
  }

  @override
  ConsumerState<StretchScreenRoute> createState() =>
      _StretchScreenRouteState();
}

class _StretchScreenRouteState extends ConsumerState<StretchScreenRoute> {
  StreamSubscription<StretchEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription =
        ref.read(stretchViewModelProvider.notifier).onEvent.listen(
              _handleEvent,
            );
  }

  void _handleEvent(StretchEvent event) {
    if (!mounted) {
      return;
    }
    // 多实例堆叠保护：仅栈顶路由响应事件（provider 为单实例）。
    if (ModalRoute.of(context)?.isCurrent != true) {
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
    final viewModel = ref.watch(stretchViewModelProvider.notifier);
    final state = ref.watch(stretchViewModelProvider);
    return StretchScreen(
      state: state,
      onIntent: viewModel.handleIntent,
      onActionTapped: ActionDetailScreenRoute.push,
      onOpenGarden: widget.onOpenGarden,
    );
  }
}
