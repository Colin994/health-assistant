/// TagEditorScreen → ScreenRoute 的一次性事件。
sealed class TagEditorEvent {
  const TagEditorEvent();
}

/// 保存成功（Route 收到后 pop 返回 true，调用方刷新标签展示）。
final class TagEditorSaved extends TagEditorEvent {
  const TagEditorSaved();
}
