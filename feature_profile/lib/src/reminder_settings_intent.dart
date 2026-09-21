import 'reminder_settings_state.dart';

/// ReminderSettingsScreen 上抛的用户事件（Screen → ViewModel）。
sealed class ReminderSettingsIntent {
  const ReminderSettingsIntent();
}

/// 切换提醒密度档位。
final class DensitySelected extends ReminderSettingsIntent {
  const DensitySelected(this.density);

  final RemindDensity density;
}

/// 点击静音时段（W2 接时间选择器）。
final class MuteWindowTapped extends ReminderSettingsIntent {
  const MuteWindowTapped();
}

/// 点击午休静音（W2 接开关持久化）。
final class LunchMuteTapped extends ReminderSettingsIntent {
  const LunchMuteTapped();
}

/// 点击「发一条试试」（W3 接本地通知）。
final class TestReminderPressed extends ReminderSettingsIntent {
  const TestReminderPressed();
}
