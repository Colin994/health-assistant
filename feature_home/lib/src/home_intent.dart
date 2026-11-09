/// HomeScreen 上抛的用户事件（Screen → ViewModel）。
sealed class HomeIntent {
  const HomeIntent();
}

/// 下拉/点击刷新（重读本地当日步数基线；W2 接倒计时引擎后同时重算下次提醒）。
final class RefreshPressed extends HomeIntent {
  const RefreshPressed();
}
