/// StretchScreen → ScreenRoute 的一次性事件。
sealed class StretchEvent {
  const StretchEvent();
}

/// 拉伸流程结束（关闭/反馈完成），Route 收到后退出页面。
final class StretchFinished extends StretchEvent {
  const StretchFinished();
}

/// 跳过当前动作（W3 记录 feedback_event 后关闭）。
final class StretchSkipped extends StretchEvent {
  const StretchSkipped();
}
