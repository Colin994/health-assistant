import 'reminder_kind.dart';

/// 每类提醒的倒计时运行状态（经 rule_state 表持久化，重启恢复）。
class RuleState {
  const RuleState({
    required this.kind,
    this.remainingMs,
    this.savedAt,
    this.lastFiredAt,
    this.snoozedUntil,
    this.snoozeCountToday = 0,
    this.dayKey = '',
    this.mutedToday = false,
    this.disabled = false,
  });

  final ReminderKind kind;

  /// 剩余时长（毫秒；静音期冻结）。null = 从未启动，按阈值起算。
  final int? remainingMs;

  /// 最近一次持久化时刻（用于被杀期重算：remaining -= 期间活跃时长）。
  final DateTime? savedAt;

  final DateTime? lastFiredAt;

  /// 稍后再提醒时刻（+1h；到点即重新触发）。
  final DateTime? snoozedUntil;

  /// 今日稍后次数（每类每日最多 1 次，FR-6）。
  final int snoozeCountToday;

  /// 状态所属日（yyyy-MM-dd；跨日重置每日字段）。
  final String dayKey;

  /// 今天别提醒（当日零触发）。
  final bool mutedToday;

  /// 别再提醒这类（持久禁用，重新选择档位可恢复）。
  final bool disabled;

  RuleState copyWith({
    int? remainingMs,
    DateTime? savedAt,
    DateTime? lastFiredAt,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    int? snoozeCountToday,
    String? dayKey,
    bool? mutedToday,
    bool? disabled,
  }) {
    return RuleState(
      kind: kind,
      remainingMs: remainingMs ?? this.remainingMs,
      savedAt: savedAt ?? this.savedAt,
      lastFiredAt: lastFiredAt ?? this.lastFiredAt,
      snoozedUntil:
          clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      snoozeCountToday: snoozeCountToday ?? this.snoozeCountToday,
      dayKey: dayKey ?? this.dayKey,
      mutedToday: mutedToday ?? this.mutedToday,
      disabled: disabled ?? this.disabled,
    );
  }
}
