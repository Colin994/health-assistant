import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_intent.dart';
import 'profile_state.dart';

/// ProfileScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState(tags: ['颈椎不适', '眼疲劳', '常忘喝水']);

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(ProfileIntent intent) {
    switch (intent) {
      case EditTagsPressed():
        // W2：接标签编辑流（复用引导页 02 的标签选择）
        break;
    }
  }
}

/// 我的页状态容器（常驻 Tab：IndexedStack 持续挂载，状态保活）。
final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(ProfileViewModel.new);
