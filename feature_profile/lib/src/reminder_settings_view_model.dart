import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'reminder_settings_intent.dart';
import 'reminder_settings_state.dart';

/// ReminderSettingsScreen 的状态持有者（架构文档 3.2）。
///
/// W2 接 core_reminder 的规则配置 CRUD 后替换为持久化读写。
@injectable
class ReminderSettingsViewModel extends ChangeNotifier {
  ReminderSettingsState _state = const ReminderSettingsState();

  /// 当前视图数据。
  ReminderSettingsState get state => _state;

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(ReminderSettingsIntent intent) {
    switch (intent) {
      case DensitySelected(:final density):
        _setState(_state.copyWith(density: density));
      case MuteWindowTapped():
        // W2：静音时段选择器
        break;
      case LunchMuteTapped():
        // W2：午休静音开关持久化
        break;
      case TestReminderPressed():
        // W3：本地通知测试链路
        break;
    }
  }

  void _setState(ReminderSettingsState next) {
    if (_state != next) {
      _state = next;
      notifyListeners();
    }
  }
}
