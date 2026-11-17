import 'package:flutter/foundation.dart';

/// 引导流程步骤（设计稿 01–03，三个差异化版式）。
enum OnboardingStep { value, tags, permissions }

/// OnboardingScreen 的视图数据类（不可变，变更经 copyWith 重建）。
@immutable
class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.value,
    this.selectedTags = const {},
    this.notificationGranted = false,
  });

  /// 当前步骤（0：价值页 / 1：健康标签 / 2：开启提醒）。
  final OnboardingStep step;

  /// 已选健康标签（标签选项文案为静态 UI 数据，见 Screen）。
  final Set<String> selectedTags;

  /// 通知授权状态（03 卡片一）。
  ///
  /// 手表连接（健康数据授权）已隐藏为设置页 Pro 付费功能，
  /// 上线后再回归引导流程。
  final bool notificationGranted;

  /// 是否最后一步（决定底部主按钮文案与行为）。
  bool get isLastStep => step == OnboardingStep.permissions;

  /// 标签页「下一步」是否可用（至少选一个标签，含「只是久坐」）。
  bool get canProceedTags => selectedTags.isNotEmpty;

  OnboardingState copyWith({
    OnboardingStep? step,
    Set<String>? selectedTags,
    bool? notificationGranted,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      selectedTags: selectedTags ?? this.selectedTags,
      notificationGranted: notificationGranted ?? this.notificationGranted,
    );
  }
}
