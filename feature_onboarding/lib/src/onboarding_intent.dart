/// OnboardingScreen 上抛的用户事件（Screen → ViewModel）。
sealed class OnboardingIntent {
  const OnboardingIntent();
}

/// 点击「跳过」（01 页右上角，直接完成引导）。
final class SkipPressed extends OnboardingIntent {
  const SkipPressed();
}

/// 点击返回箭头「‹」（02/03 页左上角）。
final class BackPressed extends OnboardingIntent {
  const BackPressed();
}

/// 点击主按钮「开始使用 / 下一步 / 进入应用」推进流程。
final class NextPressed extends OnboardingIntent {
  const NextPressed();
}

/// 勾选/取消一个健康标签（02 页）。
final class TagToggled extends OnboardingIntent {
  const TagToggled(this.label);

  final String label;
}

/// 点击「去授权」（03 页健康数据卡片）。
///
/// W2 接 HealthRepository.requestPermissions；当前 UI 先落选中态。
final class RequestHealthAccess extends OnboardingIntent {
  const RequestHealthAccess();
}

/// 点击「去开启」（03 页通知卡片）。
///
/// W3 通知链路接入后接系统通知设置；当前 UI 先落选中态。
final class RequestNotifications extends OnboardingIntent {
  const RequestNotifications();
}
