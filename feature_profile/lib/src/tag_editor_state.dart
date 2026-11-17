import 'package:flutter/foundation.dart';

/// TagEditorScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class TagEditorState {
  const TagEditorState({this.selectedTags = const {}, this.saving = false});

  /// 当前勾选标签。
  final Set<String> selectedTags;

  /// 保存中（防重复提交）。
  final bool saving;

  TagEditorState copyWith({Set<String>? selectedTags, bool? saving}) {
    return TagEditorState(
      selectedTags: selectedTags ?? this.selectedTags,
      saving: saving ?? this.saving,
    );
  }
}
