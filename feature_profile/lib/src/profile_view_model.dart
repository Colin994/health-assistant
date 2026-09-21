import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'profile_intent.dart';
import 'profile_state.dart';

/// ProfileScreen 的状态持有者（架构文档 3.2）。
@injectable
class ProfileViewModel extends ChangeNotifier {
  ProfileState _state = const ProfileState(tags: ['颈椎不适', '眼疲劳']);

  /// 当前视图数据。
  ProfileState get state => _state;

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(ProfileIntent intent) {
    switch (intent) {
      case EditTagsPressed():
        // W2：接标签编辑流（复用引导页 02 的标签选择）
        break;
    }
  }
}
