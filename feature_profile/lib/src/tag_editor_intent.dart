/// TagEditorScreen 上抛的用户事件（Screen → ViewModel）。
sealed class TagEditorIntent {
  const TagEditorIntent();
}

/// 勾选/取消一个健康标签（互斥规则在 VM 内处理）。
final class TagToggled extends TagEditorIntent {
  const TagToggled(this.label);

  final String label;
}

/// 保存标签（落库 + 自动开启对应提醒 + 引擎刷新）。
final class SavePressed extends TagEditorIntent {
  const SavePressed();
}
