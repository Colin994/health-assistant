/// ProfileScreen 上抛的用户事件（Screen → ViewModel）。
sealed class ProfileIntent {
  const ProfileIntent();
}

/// 点击「我的健康标签」区块（W2 打开标签编辑）。
final class EditTagsPressed extends ProfileIntent {
  const EditTagsPressed();
}
