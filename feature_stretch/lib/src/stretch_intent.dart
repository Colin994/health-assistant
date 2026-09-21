import 'stretch_state.dart';

/// StretchScreen 上抛的用户事件（Screen → ViewModel）。
sealed class StretchIntent {
  const StretchIntent();
}

/// 点击右上角关闭。
final class ClosePressed extends StretchIntent {
  const ClosePressed();
}

/// 点击「跳过这个 ›」。
final class SkipThisPressed extends StretchIntent {
  const SkipThisPressed();
}

/// 点击一个动作（进入动作详情 06）。
final class ActionTapped extends StretchIntent {
  const ActionTapped(this.action);

  final StretchAction action;
}

/// 四态反馈按钮（做完/稍后/今天别提醒/别再提醒这类）。
final class FeedbackSelected extends StretchIntent {
  const FeedbackSelected(this.feedback);

  final StretchFeedback feedback;
}
