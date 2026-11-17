import 'package:flutter/foundation.dart';

/// 提醒密度三档（设计稿 08，久坐拉伸档位）。
enum RemindDensity {
  strict('更严格', '45 分钟', 45),
  standard('标准', '55 分钟', 55),
  relaxed('更宽松', '75 分钟', 75);

  const RemindDensity(this.label, this.thresholdLabel, this.minutes);

  /// 档位名。
  final String label;

  /// 久坐阈值描述。
  final String thresholdLabel;

  /// 阈值（分钟）。
  final int minutes;

  static RemindDensity fromMinutes(int minutes) =>
      minutes <= 45 ? strict : (minutes >= 75 ? relaxed : standard);
}

/// ReminderSettingsScreen 的视图数据类。
///
/// W2 起与 ReminderConfig 持久化同步（core_profile）。
@immutable
class ReminderSettingsState {
  const ReminderSettingsState({
    this.density = RemindDensity.standard,
    this.waterReminderEnabled = true,
    this.eyeReminderEnabled = true,
    this.nightMuteStart = 22 * 60,
    this.nightMuteEnd = 7 * 60,
    this.lunchMuteEnabled = true,
    this.sedentaryDisabled = false,
  });

  /// 久坐拉伸密度档位。
  final RemindDensity density;

  /// 喝水提醒开关（默认每 45 分钟）。
  final bool waterReminderEnabled;

  /// 护眼提醒开关（默认 20-20-20：每 20 分钟远眺 20 秒）。
  final bool eyeReminderEnabled;

  /// 夜间静音窗（分钟制；跨零点如 22:00–07:00）。
  final int nightMuteStart;
  final int nightMuteEnd;

  /// 午休静音（12:30–13:30）开关。
  final bool lunchMuteEnabled;

  /// 久坐类已被「别再提醒这类」禁用（重新选档位即恢复）。
  final bool sedentaryDisabled;

  /// 静音时段展示。
  String get muteWindowLabel =>
      '${_hm(nightMuteStart)} – ${_hm(nightMuteEnd)}';

  /// 午休静音展示。
  String get lunchMuteLabel =>
      lunchMuteEnabled ? '12:30 – 13:30 不提醒' : '已关闭';

  /// 页脚「当前」行。
  String get currentLabel =>
      '当前：久坐 ${density.label}（${density.thresholdLabel}）'
      '· 喝水 ${waterReminderEnabled ? '45 分' : '关'}'
      '· 护眼 ${eyeReminderEnabled ? '20 分' : '关'}'
      '${sedentaryDisabled ? '（久坐已停用，重选档位恢复）' : ''}';

  static String _hm(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  ReminderSettingsState copyWith({
    RemindDensity? density,
    bool? waterReminderEnabled,
    bool? eyeReminderEnabled,
    int? nightMuteStart,
    int? nightMuteEnd,
    bool? lunchMuteEnabled,
    bool? sedentaryDisabled,
  }) {
    return ReminderSettingsState(
      density: density ?? this.density,
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      eyeReminderEnabled: eyeReminderEnabled ?? this.eyeReminderEnabled,
      nightMuteStart: nightMuteStart ?? this.nightMuteStart,
      nightMuteEnd: nightMuteEnd ?? this.nightMuteEnd,
      lunchMuteEnabled: lunchMuteEnabled ?? this.lunchMuteEnabled,
      sedentaryDisabled: sedentaryDisabled ?? this.sedentaryDisabled,
    );
  }
}
