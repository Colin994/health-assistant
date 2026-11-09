import 'package:flutter/foundation.dart';

/// HomeScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class HomeState {
  const HomeState({
    this.dataSourceLabel = '',
    this.todaySteps,
    this.reminderCount = 0,
    this.completedCount = 0,
    this.nextEstimateText = '',
    this.records = const [],
  });

  /// 数据源状态行（如「传感器直读（L4）· 实时计步中」）。
  final String dataSourceLabel;

  /// 今日步数（L4 传感器直读；null = 采集未启动/通道不可用）。
  final int? todaySteps;

  /// 今天已提醒次数。
  final int reminderCount;

  /// 与用户一起完成的提醒次数。
  final int completedCount;

  /// 下次提醒预估文案。
  final String nextEstimateText;

  /// 今日提醒记录（时间倒序）。
  final List<HomeRecord> records;

  HomeState copyWith({
    String? dataSourceLabel,
    int? todaySteps,
    int? reminderCount,
    int? completedCount,
    String? nextEstimateText,
    List<HomeRecord>? records,
  }) {
    return HomeState(
      dataSourceLabel: dataSourceLabel ?? this.dataSourceLabel,
      todaySteps: todaySteps ?? this.todaySteps,
      reminderCount: reminderCount ?? this.reminderCount,
      completedCount: completedCount ?? this.completedCount,
      nextEstimateText: nextEstimateText ?? this.nextEstimateText,
      records: records ?? this.records,
    );
  }
}

/// 今日提醒记录条目（W2 接 core_model / core_database 后替换为领域对象）。
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
