import 'reminder_kind.dart';

/// 静音窗（分钟制；start > end 表示跨零点窗口，如 22:00–07:00）。
///
/// 静音语义 = 暂停（2026-11-09 评审决策）：窗口内倒计时剩余时长冻结，
/// 窗口结束后继续，避免静音结束三类提醒同时到点。
class MuteWindow {
  const MuteWindow({
    required this.startMinutes,
    required this.endMinutes,
  });

  /// 便捷构造：整点/半点口径（如 22:00–07:00、12:30–13:30）。
  const MuteWindow.clock(int startHour, int startMinute, int endHour, int endMinute)
      : startMinutes = startHour * 60 + startMinute,
        endMinutes = endHour * 60 + endMinute;

  /// 窗口起点（当日分钟，0–1439）。
  final int startMinutes;

  /// 窗口终点（当日分钟，0–1439；小于起点 = 跨零点）。
  final int endMinutes;

  /// 是否跨零点。
  bool get wrapsOvernight => startMinutes > endMinutes;

  /// 某日的分钟值是否落在静音窗内。
  bool contains(int minuteOfDay) {
    if (wrapsOvernight) {
      return minuteOfDay >= startMinutes || minuteOfDay < endMinutes;
    }
    return minuteOfDay >= startMinutes && minuteOfDay < endMinutes;
  }
}

/// 三类提醒的运行规则（由用户配置换算而来，供引擎消费）。
class ReminderRule {
  const ReminderRule({
    required this.thresholds,
    required this.sedentaryCooldown,
    this.nightMute,
    this.lunchMute,
  });

  /// 各类触发阈值/间隔。
  final Map<ReminderKind, Duration> thresholds;

  /// 久坐触发后的冷却期（默认 90 分，FR-4）。
  final Duration sedentaryCooldown;

  /// 夜间静音（默认 22:00–07:00）。
  final MuteWindow? nightMute;

  /// 午休静音（默认 12:30–13:30）。
  final MuteWindow? lunchMute;

  /// 自动降频：放宽阈值与冷却（FR-6，封顶 = 宽松档 + 增量）。
  ReminderRule widen({
    required Duration thresholdDelta,
    required Duration cooldownDelta,
  }) {
    final widened = <ReminderKind, Duration>{};
    for (final e in thresholds.entries) {
      widened[e.key] =
          e.key == ReminderKind.sedentary ? e.value + thresholdDelta : e.value;
    }
    return ReminderRule(
      thresholds: widened,
      sedentaryCooldown: sedentaryCooldown + cooldownDelta,
      nightMute: nightMute,
      lunchMute: lunchMute,
    );
  }
}
