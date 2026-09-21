import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'onboarding_event.dart';
import 'onboarding_intent.dart';
import 'onboarding_state.dart';

/// OnboardingScreen 的状态持有者（架构文档 3.2）。
///
/// - 持有 [OnboardingState]，经 notifyListeners 驱动 Screen 重建；
/// - 消费 [OnboardingIntent]，业务结果写入 State 或发出 [OnboardingEvent]；
/// - 由 ScreenRoute 从 get_it 工厂注册获取，随页面销毁回收。
@injectable
class OnboardingViewModel extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();

  /// 当前视图数据。
  OnboardingState get state => _state;

  final StreamController<OnboardingEvent> _events =
      StreamController<OnboardingEvent>.broadcast();

  /// 一次性事件流，由 ScreenRoute 订阅并处理。
  Stream<OnboardingEvent> get onEvent => _events.stream;

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(OnboardingIntent intent) {
    switch (intent) {
      case SkipPressed():
        _complete();
      case BackPressed():
        if (_state.step != OnboardingStep.value) {
          _setState(
            _state.copyWith(step: OnboardingStep.values[_state.step.index - 1]),
          );
        }
      case NextPressed():
        if (_state.isLastStep) {
          _complete();
        } else {
          _setState(
            _state.copyWith(
              step: OnboardingStep.values[_state.step.index + 1],
            ),
          );
        }
      case TagToggled(:final label):
        final tags = {..._state.selectedTags};
        tags.contains(label) ? tags.remove(label) : tags.add(label);
        _setState(_state.copyWith(selectedTags: tags));
      // W2/W3 接真实授权（HealthRepository / 通知设置），当前仅落 UI 态
      case RequestHealthAccess():
        _setState(_state.copyWith(healthGranted: true));
      case RequestNotifications():
        _setState(_state.copyWith(notificationGranted: true));
    }
  }

  void _setState(OnboardingState next) {
    if (_state != next) {
      _state = next;
      notifyListeners();
    }
  }

  void _complete() {
    _events.add(const OnboardingCompleted());
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
