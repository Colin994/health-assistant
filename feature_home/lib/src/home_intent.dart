/// HomeScreen 上抛的用户事件（Screen → ViewModel）。
sealed class HomeIntent {
  const HomeIntent();
}

/// 下拉/点击刷新（W2 接 FetchSegmentsUseCase 重算预估）。
final class RefreshPressed extends HomeIntent {
  const RefreshPressed();
}
