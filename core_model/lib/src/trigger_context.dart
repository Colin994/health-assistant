/// 触发提醒时的上下文，作为 LLM 文案生成的输入（脱敏摘要）。
class TriggerContext {
  const TriggerContext({
    required this.healthTags,
    required this.continuousSedentaryMinutes,
    required this.timeBand,
    required this.recentFeedbackDone7d,
    required this.recentFeedbackRejected7d,
    required this.locale,
  });

  /// 健康标签码列表（cervical_spondylosis 等）。
  final List<String> healthTags;

  /// 本次连续久坐分钟数。
  final int continuousSedentaryMinutes;

  /// 触发时段，影响文案语气。
  final TimeBand timeBand;

  /// 近 7 天「已完成」反馈次数。
  final int recentFeedbackDone7d;

  /// 近 7 天「拒绝类」反馈次数（snooze/stopToday/neverAgain）。
  final int recentFeedbackRejected7d;

  /// 语言环境（zh-CN 等）。
  final String locale;
}

/// 提醒触发时段。
enum TimeBand { morning, forenoon, afternoon, evening, night }
