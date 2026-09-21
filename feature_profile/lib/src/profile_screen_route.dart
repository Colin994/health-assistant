import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'profile_screen.dart';
import 'profile_view_model.dart';

/// 我的页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建。
class ProfileScreenRoute extends StatefulWidget {
  const ProfileScreenRoute({super.key, this.devEntries = const []});

  /// 开发者入口区条目（由 app 壳注入，W2 路由表就绪后移除）。
  final List<(String, VoidCallback)> devEntries;

  @override
  State<ProfileScreenRoute> createState() => _ProfileScreenRouteState();
}

class _ProfileScreenRouteState extends State<ProfileScreenRoute> {
  late final ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<ProfileViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ProfileScreen(
        state: _viewModel.state,
        onIntent: _viewModel.handleIntent,
        devEntries: widget.devEntries,
      ),
    );
  }
}
