import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'home_screen.dart';
import 'home_view_model.dart';

/// 今日页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建，不经 Navigator push。
class HomeScreenRoute extends StatefulWidget {
  const HomeScreenRoute({super.key, this.onQuickStretch});

  /// 快捷开始拉伸（开发入口，由 app 壳注入）。
  final VoidCallback? onQuickStretch;

  @override
  State<HomeScreenRoute> createState() => _HomeScreenRouteState();
}

class _HomeScreenRouteState extends State<HomeScreenRoute> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<HomeViewModel>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => HomeScreen(
        state: _viewModel.state,
        onIntent: _viewModel.handleIntent,
        onQuickStretch: widget.onQuickStretch,
      ),
    );
  }
}
