/// 一段连续行为（来源：健康中枢的活动分段/久坐标记）。
class ActivitySegment {
  const ActivitySegment({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.source,
  });

  /// 平台数据源 + 原始 ID 拼接，保证幂等。
  final String id;

  /// 行为类型：久坐 / 静止 / 步行 / 跑步等。
  final ActivityType type;

  final DateTime start;
  final DateTime end;

  /// 数据来源：healthkit / health_connect。
  final String source;

  /// 分段时长（分钟）。
  int get durationMinutes => end.difference(start).inMinutes;
}

/// 行为分段类型。
enum ActivityType {
  /// 久坐（明确标记的 sedentary 分段，Android Health Connect 提供）。
  sedentary,

  /// 静止（无明确久坐标记时按「非活动」处理）。
  stationary,

  /// 步行。
  walking,

  /// 跑步。
  running,

  /// 其他活动（骑行、锻炼等，均视为「活动打断」）。
  active,

  /// 未识别。
  other,
}
