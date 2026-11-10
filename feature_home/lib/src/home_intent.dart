/// HomeScreen 上抛的用户事件（Screen → ViewModel）。
sealed class HomeIntent {
  const HomeIntent();
}

/// 下拉/点击刷新（重读本地当日步数基线）。
final class RefreshPressed extends HomeIntent {
  const RefreshPressed();
}

/// 点击降频告知横幅的「知道了」（当日不再显示）。
final class DeEscalationAcknowledged extends HomeIntent {
  const DeEscalationAcknowledged();
}
