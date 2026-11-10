import 'reminder_settings_state.dart';

/// ReminderSettingsScreen 上抛的用户事件（Screen → ViewModel）。
sealed class ReminderSettingsIntent {
  const ReminderSettingsIntent();
}

/// 切换久坐拉伸密度档位（次轮生效；重新选择即恢复被禁用的久坐类）。
final class DensitySelected extends ReminderSettingsIntent {
  const DensitySelected(this.density);

  final RemindDensity density;
}

/// 切换喝水提醒开关。
final class WaterReminderToggled extends ReminderSettingsIntent {
  const WaterReminderToggled(this.enabled);

  final bool enabled;
}

/// 切换护眼提醒开关。
final class EyeReminderToggled extends ReminderSettingsIntent {
  const EyeReminderToggled(this.enabled);

  final bool enabled;
}

/// 修改夜间静音时段（分钟制，支持跨零点）。
final class MuteWindowChanged extends ReminderSettingsIntent {
  const MuteWindowChanged(this.startMinutes, this.endMinutes);

  final int startMinutes;
  final int endMinutes;
}

/// 切换午休静音。
final class LunchMuteToggled extends ReminderSettingsIntent {
  const LunchMuteToggled(this.enabled);

  final bool enabled;
}
