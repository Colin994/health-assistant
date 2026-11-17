/// ViewModel → ScreenRoute 的一次性事件（非状态数据）。
///
/// 如导航、弹 toast 等「发生即消费」的动作由 ScreenRoute 处理，
/// 不进入 State（架构文档 3.2）。
sealed class OnboardingEvent {
  const OnboardingEvent();
}

/// 引导流程完成：跳转首页（或落地页）。
final class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}
