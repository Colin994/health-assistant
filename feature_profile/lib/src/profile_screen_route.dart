import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_screen.dart';
import 'profile_view_model.dart';
import 'tag_editor_screen_route.dart';

/// 我的页跳转入口与 Screen/ViewModel 通信中间件（架构文档 3.2）。
///
/// 常驻 Tab 页：由 app 壳的 IndexedStack 直接构建。
/// v7（2026-11-10）：提醒设置入口回流本页（经 onReminderSettings 注入）。
class ProfileScreenRoute extends ConsumerWidget {
  const ProfileScreenRoute({super.key, this.onReminderSettings});

  /// 提醒设置入口（由 app 壳注入）。
  final VoidCallback? onReminderSettings;

  Future<void> _editTags(BuildContext context, WidgetRef ref) async {
    final saved = await TagEditorScreenRoute.push(context);
    if (saved) {
      await ref.read(profileViewModelProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(profileViewModelProvider.notifier);
    final state = ref.watch(profileViewModelProvider);
    return ProfileScreen(
      state: state,
      onIntent: viewModel.handleIntent,
      onReminderSettings: onReminderSettings,
      onEditTags: () => _editTags(context, ref),
    );
  }
}
