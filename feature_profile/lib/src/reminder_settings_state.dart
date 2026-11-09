import 'package:flutter/foundation.dart';

/// 提醒密度三档（设计稿 08，久坐拉伸档位）。
enum RemindDensity {
  strict('更严格', '45 分钟'),
  standard('标准', '55 分钟'),
  relaxed('更宽松', '75 分钟');

  const RemindDensity(this.label, this.thresholdLabel);

  /// 档位名。
  final String label;

  /// 久坐阈值描述。
  final String thresholdLabel;
}

/// ReminderSettingsScreen 的视图数据类。
///
/// v5：三类提醒（久坐拉伸 / 喝水 / 护眼）核心均为倒计时触发；
/// 手表数据源判定上线（Pro）后久坐档位可接传感器重置。
@immutable
class ReminderSettingsState {
  const ReminderSettingsState({
    this.density = RemindDensity.standard,
    this.waterReminderEnabled = true,
    this.eyeReminderEnabled = true,
    this.muteWindowLabel = '22:00 – 07:00',
    this.lunchMuteLabel = '12:30 – 13:30 不提醒',
  });

  /// 久坐拉伸密度档位。
  final RemindDensity density;

  /// 喝水提醒开关（默认每 45 分钟）。
  final bool waterReminderEnabled;

  /// 护眼提醒开关（默认 20-20-20：每 20 分钟远眺 20 秒）。
  final bool eyeReminderEnabled;

  /// 静音时段展示。
  final String muteWindowLabel;

  /// 午休静音展示。
  final String lunchMuteLabel;

  /// 页脚「当前」行。
  String get currentLabel =>
      '当前：久坐 ${density.label}（${density.thresholdLabel}）'
      '· 喝水 ${waterReminderEnabled ? '45 分' : '关'}'
      '· 护眼 ${eyeReminderEnabled ? '20 分' : '关'}';

  ReminderSettingsState copyWith({
    RemindDensity? density,
    bool? waterReminderEnabled,
    bool? eyeReminderEnabled,
    String? muteWindowLabel,
    String? lunchMuteLabel,
  }) {
    return ReminderSettingsState(
      density: density ?? this.density,
      waterReminderEnabled: waterReminderEnabled ?? this.waterReminderEnabled,
      eyeReminderEnabled: eyeReminderEnabled ?? this.eyeReminderEnabled,
      muteWindowLabel: muteWindowLabel ?? this.muteWindowLabel,
      lunchMuteLabel: lunchMuteLabel ?? this.lunchMuteLabel,
    );
  }
}
