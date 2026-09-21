import 'package:flutter/foundation.dart';

/// 提醒密度三档（设计稿 08）。
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
@immutable
class ReminderSettingsState {
  const ReminderSettingsState({
    this.density = RemindDensity.standard,
    this.muteWindowLabel = '22:00 – 07:00',
    this.lunchMuteLabel = '12:30 – 13:30 不提醒',
  });

  /// 当前密度档位。
  final RemindDensity density;

  /// 静音时段展示。
  final String muteWindowLabel;

  /// 午休静音展示。
  final String lunchMuteLabel;

  /// 页脚「当前」行。
  String get currentLabel =>
      '当前：${density.label}（${density.thresholdLabel} · 间隔 90 分钟）';

  ReminderSettingsState copyWith({
    RemindDensity? density,
    String? muteWindowLabel,
    String? lunchMuteLabel,
  }) {
    return ReminderSettingsState(
      density: density ?? this.density,
      muteWindowLabel: muteWindowLabel ?? this.muteWindowLabel,
      lunchMuteLabel: lunchMuteLabel ?? this.lunchMuteLabel,
    );
  }
}
