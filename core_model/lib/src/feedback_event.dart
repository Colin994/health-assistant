/// 用户对一次提醒的四态反馈。
enum FeedbackAction {
  /// 已完成拉伸。
  done,

  /// 稍后提醒。
  snooze,

  /// 今天不再提醒。
  stopToday,

  /// 永久关闭此类提醒。
  neverAgain,
}

/// 一次反馈事件（本地落库 + 云端上报）。
class FeedbackEvent {
  const FeedbackEvent({
    required this.adviceId,
    required this.action,
    required this.at,
    required this.triggerContextJson,
  });

  final String adviceId;
  final FeedbackAction action;
  final DateTime at;

  /// 触发该提醒时的上下文快照（JSON），供云端频控分析。
  final String triggerContextJson;
}
