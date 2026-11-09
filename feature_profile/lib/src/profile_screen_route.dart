import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_screen.dart';
import 'profile_view_model.dart';

/// 我的页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建。
/// v3：设置区块移至「设置」Tab 后，本页不再承接开发者入口注入。
class ProfileScreenRoute extends ConsumerWidget {
  const ProfileScreenRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(profileViewModelProvider.notifier);
    final state = ref.watch(profileViewModelProvider);
    return ProfileScreen(
      state: state,
      onIntent: viewModel.handleIntent,
    );
  }
}
