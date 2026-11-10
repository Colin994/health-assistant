import 'package:core_model/core_model.dart';

/// 触发日志仓库（驱动「今天已提醒 N 次」与 W4 文案缓存）。
abstract class ReminderLogStore {
  Future<void> appendFire({
    required ReminderKind kind,
    required DateTime firedAt,
    String adviceId,
    String copyText = '',
  });

  /// 当日触发/完成计数流（首页计数卡）。
  Stream<({int fired, int done})> watchDayCounts(DateTime day);
}

/// 反馈事件仓库（四态；降频统计 = 近 7 天负面占比）。
abstract class FeedbackLogStore {
  Future<void> add({
    required ReminderKind kind,
    required FeedbackAction action,
    required DateTime at,
    String? adviceId,
  });

  /// 近 7 天统计（负面 = 非 done）。
  Future<({int total, int negative})> stats7d(DateTime now);
}

/// 倒计时状态仓库（重启恢复）。
abstract class RuleStateStore {
  Future<Map<ReminderKind, RuleState>> loadAll();

  Future<void> save(RuleState state);
}
