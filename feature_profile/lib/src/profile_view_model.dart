import 'package:core_profile/core_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'profile_intent.dart';
import 'profile_state.dart';

/// ProfileScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // W2 落库、v7 接线：展示引导时选择的标签（HealthTagStore）。
    _load();
    return const ProfileState(tags: []);
  }

  Future<void> _load() async {
    final tags = await GetIt.I<HealthTagStore>().load();
    if (!ref.mounted) return;
    state = ProfileState(tags: tags.toList());
  }

  /// 标签编辑保存后的手动刷新入口。
  Future<void> reload() => _load();

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  ///
  /// v8：标签编辑经 Route 层直跳（TagEditorScreenRoute），不再走 Intent。
  void handleIntent(ProfileIntent intent) {}
}

/// 我的页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
