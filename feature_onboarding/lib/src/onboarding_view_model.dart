import 'dart:async';

import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'onboarding_event.dart';
import 'onboarding_intent.dart';
import 'onboarding_screen.dart';
import 'onboarding_state.dart';

/// OnboardingScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
///
/// - 持有 [OnboardingState]，经 provider 驱动 Screen 重建（新旧状态
///   `==` 时 Riverpod 自动跳过通知，等价原 `_setState` 去重）；
/// - 消费 [OnboardingIntent]，业务结果写入 State 或发出 [OnboardingEvent]；
/// - 生命周期由 [onboardingViewModelProvider] 管理：页面 pop 后自动销毁，
///   并经 `ref.onDispose` 关闭事件流（补齐原 get_it 工厂实例不回收的缺口）。
class OnboardingViewModel extends Notifier<OnboardingState> {
  final StreamController<OnboardingEvent> _events =
      StreamController<OnboardingEvent>.broadcast();

  /// 一次性事件流，由 ScreenRoute 订阅并处理。
  Stream<OnboardingEvent> get onEvent => _events.stream;

  @override
  OnboardingState build() {
    ref.onDispose(_events.close);
    return const OnboardingState();
  }

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(OnboardingIntent intent) async {
    switch (intent) {
      case SkipPressed():
        await _complete();
      case BackPressed():
        if (state.step != OnboardingStep.value) {
          state = state.copyWith(
            step: OnboardingStep.values[state.step.index - 1],
          );
        }
      case NextPressed():
        if (state.isLastStep) {
          await _complete();
        } else {
          state = state.copyWith(
            step: OnboardingStep.values[state.step.index + 1],
          );
        }
      case TagToggled(:final label):
        final tags = {...state.selectedTags};
        if (tags.contains(label)) {
          tags.remove(label);
        } else {
          tags.add(label);
          // 互斥（设计稿 02 v6）：「只是久坐」与身体状况类互斥，
          // 习惯类标签（常忘喝水）独立、可与任一项共存。
          if (label == OnboardingScreen.noConditionTag) {
            tags.removeAll(OnboardingScreen.bodyConditionTags);
          } else if (OnboardingScreen.bodyConditionTags.contains(label)) {
            tags.remove(OnboardingScreen.noConditionTag);
          }
        }
        state = state.copyWith(selectedTags: tags);
      // W2-c：真实通知权限请求（Android 13+ / iOS）。
      case RequestNotifications():
        final granted = await _requestNotificationPermission();
        state = state.copyWith(notificationGranted: granted);
    }
  }

  Future<void> _complete() async {
    // 标签落库（PRD FR-2）+ 自动开启对应提醒（v8：加法式）。
    try {
      final tags = {...state.selectedTags};
      final store = GetIt.I<HealthTagStore>();
      final repo = GetIt.I<ReminderConfigRepository>();
      await store.save(tags);
      await enableRemindersForTags(tags, repo);
      await GetIt.I<ReminderEngine>().onSettingsChanged();
    } catch (_) {
      // 落库失败不阻断引导完成（空标签走默认文案）。
    }
    _events.add(const OnboardingCompleted());
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      return await GetIt.I<ReminderNotificationService>().requestPermission();
    } catch (_) {
      return false;
    }
  }
}

/// 引导页状态容器。
final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
