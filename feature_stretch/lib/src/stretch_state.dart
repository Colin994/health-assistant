import 'package:flutter/foundation.dart';

/// 拉伸动作条目（W2 接动作素材库后替换为 core_model 领域对象）。
@immutable
class StretchAction {
  const StretchAction({
    required this.name,
    required this.durationLabel,
    this.recommended = false,
  });

  /// 动作名（如「颈部侧拉伸」）。
  final String name;

  /// 时长与次数（如「40 秒 · 每侧 2 次」）。
  final String durationLabel;

  /// 是否标注「推荐」。
  final bool recommended;
}

/// StretchScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class StretchState {
  const StretchState({
    this.headline = '',
    this.subCopy = '',
    this.sourceLabel = '来自你的健康助手',
    this.sectionLabel = '',
    this.actions = const [],
  });

  /// 主文案（LLM 生成，W4 接入）。
  final String headline;

  /// 副文案。
  final String subCopy;

  /// 来源标注。
  final String sourceLabel;

  /// 动作区标题（如「为你准备的 1 分钟」）。
  final String sectionLabel;

  /// 推荐动作列表。
  final List<StretchAction> actions;

  StretchState copyWith({
    String? headline,
    String? subCopy,
    String? sourceLabel,
    String? sectionLabel,
    List<StretchAction>? actions,
  }) {
    return StretchState(
      headline: headline ?? this.headline,
      subCopy: subCopy ?? this.subCopy,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      actions: actions ?? this.actions,
    );
  }
}

/// 四态反馈（产品核心回流：即时降频）。
enum StretchFeedback { done, later, muteToday, neverAgain }
