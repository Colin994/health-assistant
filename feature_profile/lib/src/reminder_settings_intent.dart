import 'reminder_settings_state.dart';

/// ReminderSettingsScreen 上抛的用户事件（Screen → ViewModel）。
sealed class ReminderSettingsIntent {
  const ReminderSettingsIntent();
}

/// 切换久坐拉伸密度档位。
final class DensitySelected extends ReminderSettingsIntent {
  const DensitySelected(this.density);

  final RemindDensity density;
}

/// 切换喝水提醒开关（W2 接倒计时引擎）。
final class WaterReminderToggled extends ReminderSettingsIntent {
  const WaterReminderToggled(this.enabled);

  final bool enabled;
}

/// 切换护眼提醒开关（W2 接倒计时引擎）。
final class EyeReminderToggled extends ReminderSettingsIntent {
  const EyeReminderToggled(this.enabled);

  final bool enabled;
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
