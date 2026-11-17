import 'reminder_kind.dart';

/// 提醒设置（用户可改配置；经 core_profile 持久化，引擎换算为 ReminderRule）。
class ReminderConfig {
  const ReminderConfig({
    this.sedentaryMinutes = 55,
    this.waterEnabled = true,
    this.eyeEnabled = true,
    this.nightMuteStart = defaultNightStart,
    this.nightMuteEnd = defaultNightEnd,
    this.lunchMuteEnabled = true,
    this.disabledKinds = const {},
    this.demoRhythm = false,
    this.deEscalationAckDay = '',
  });

  static const int defaultNightStart = 22 * 60;
  static const int defaultNightEnd = 7 * 60;

  /// 久坐档位对应的阈值（分钟）：45 / 55 / 75。
  static const List<int> sedentaryChoices = [45, 55, 75];

  final int sedentaryMinutes;
  final bool waterEnabled;
  final bool eyeEnabled;

  /// 夜间静音窗（分钟制，支持跨零点）。
  final int nightMuteStart;
  final int nightMuteEnd;

  /// 午休静音（12:30–13:30）开关。
  final bool lunchMuteEnabled;

  /// 已「别再提醒」的类别（重新选择档位可恢复久坐类）。
  final Set<ReminderKind> disabledKinds;

  /// 演示节奏（仅 dev 渠道入口切换）：三类间隔一律 1 分钟，供真机 E2E。
  final bool demoRhythm;

  /// 自动降频告知已读日（yyyy-MM-dd；App 内只告知一次）。
  final String deEscalationAckDay;

  ReminderConfig copyWith({
    int? sedentaryMinutes,
    bool? waterEnabled,
    bool? eyeEnabled,
    int? nightMuteStart,
    int? nightMuteEnd,
    bool? lunchMuteEnabled,
    Set<ReminderKind>? disabledKinds,
    bool? demoRhythm,
    String? deEscalationAckDay,
  }) {
    return ReminderConfig(
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      eyeEnabled: eyeEnabled ?? this.eyeEnabled,
      nightMuteStart: nightMuteStart ?? this.nightMuteStart,
      nightMuteEnd: nightMuteEnd ?? this.nightMuteEnd,
      lunchMuteEnabled: lunchMuteEnabled ?? this.lunchMuteEnabled,
      disabledKinds: disabledKinds ?? this.disabledKinds,
      demoRhythm: demoRhythm ?? this.demoRhythm,
      deEscalationAckDay: deEscalationAckDay ?? this.deEscalationAckDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderConfig &&
          other.sedentaryMinutes == sedentaryMinutes &&
          other.waterEnabled == waterEnabled &&
          other.eyeEnabled == eyeEnabled &&
          other.nightMuteStart == nightMuteStart &&
          other.nightMuteEnd == nightMuteEnd &&
          other.lunchMuteEnabled == lunchMuteEnabled &&
          _sameSet(other.disabledKinds, disabledKinds) &&
          other.demoRhythm == demoRhythm &&
          other.deEscalationAckDay == deEscalationAckDay;

  static bool _sameSet(Set<ReminderKind> a, Set<ReminderKind> b) {
    if (a.length != b.length) return false;
    for (final k in a) {
      if (!b.contains(k)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        sedentaryMinutes,
        waterEnabled,
        eyeEnabled,
        nightMuteStart,
        nightMuteEnd,
        lunchMuteEnabled,
        Object.hashAll(disabledKinds),
        demoRhythm,
        deEscalationAckDay,
      );
}
