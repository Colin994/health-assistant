import 'package:core_model/core_model.dart';
import 'package:flutter/foundation.dart';

/// HomeScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class HomeState {
  const HomeState({
    this.dataSourceLabel = '',
    this.todaySteps,
    this.reminderCount = 0,
    this.completedCount = 0,
    this.chips = const [],
    this.nextReminders = const [],
    this.showDeEscalationBanner = false,
    this.records = const [],
  });

  /// 数据源状态行（如「今日步数 · 实时更新中」）。
  final String dataSourceLabel;

  /// 今日步数（L4 传感器直读；null = 采集未启动/通道不可用）。
  final int? todaySteps;

  /// 今天已提醒次数（reminder_log 流）。
  final int reminderCount;

  /// 与用户一起完成的提醒次数（feedback done 流）。
  final int completedCount;

  /// 三类提醒 chips（引擎投影：活倒计时/状态）。
  final List<ReminderChipView> chips;

  /// 下次提醒条目（逐类一行；空 = 全关/全免打扰，整行隐藏）。
  final List<NextReminderView> nextReminders;

  /// 自动降频告知横幅（负面 >50% 且当日未读）。
  final bool showDeEscalationBanner;

  /// 今日提醒记录（时间倒序；W3 接反馈流水细化）。
  final List<HomeRecord> records;

  HomeState copyWith({
    String? dataSourceLabel,
    int? todaySteps,
    int? reminderCount,
    int? completedCount,
    List<ReminderChipView>? chips,
    List<NextReminderView>? nextReminders,
    bool? showDeEscalationBanner,
    List<HomeRecord>? records,
  }) {
    return HomeState(
      dataSourceLabel: dataSourceLabel ?? this.dataSourceLabel,
      todaySteps: todaySteps ?? this.todaySteps,
      reminderCount: reminderCount ?? this.reminderCount,
      completedCount: completedCount ?? this.completedCount,
      chips: chips ?? this.chips,
      nextReminders: nextReminders ?? this.nextReminders,
      showDeEscalationBanner:
          showDeEscalationBanner ?? this.showDeEscalationBanner,
      records: records ?? this.records,
    );
  }
}

/// 提醒 chip 视图（点击跳对应设置）。
@immutable
class ReminderChipView {
  const ReminderChipView({
    required this.kind,
    required this.label,
    required this.sub,
    required this.dimmed,
  });

  final ReminderKind kind;

  /// 主标签（如「久坐 · 52 分后」）。
  final String label;

  /// 状态副标签（静音中/已稍后等；null = 正常）。
  final String? sub;

  /// 非倒计时态（静音/冷却/稍后）降透明度。
  final bool dimmed;
}

/// 下次提醒条目（状态矩阵映射，交互文档 §4.1）。
@immutable
class NextReminderView {
  const NextReminderView({
    required this.kind,
    required this.label,
    required this.timeText,
  });

  final ReminderKind kind;

  /// 「久坐 / 喝水 / 护眼」。
  final String label;

  /// 「14:30」「23 分后」「静音中 · 07:00 恢复」「已稍后 · 16:20」「今天已免打扰」。
  final String timeText;
}

/// 今日提醒记录条目（W3 接反馈流水后替换为领域对象）。
@immutable
class HomeRecord {
  const HomeRecord({
    required this.timeLabel,
    required this.actionName,
    required this.statusLabel,
  });

  /// 时间（如「11:20」）。
  final String timeLabel;

  /// 动作名（如「颈部侧拉伸」）。
  final String actionName;

  /// 状态（如「完成」）。
  final String statusLabel;
}
