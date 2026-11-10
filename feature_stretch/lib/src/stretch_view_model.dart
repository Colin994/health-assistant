import 'dart:async';

import 'package:core_model/core_model.dart';
import 'package:domain_all/domain_all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'stretch_event.dart';
import 'stretch_intent.dart';
import 'stretch_state.dart';

/// StretchScreen 的状态持有者（Riverpod Notifier，架构文档 3.2）。
///
/// W2-e：四态反馈经 RecordFeedbackUseCase 回流（引擎即时调整 +
/// feedback_event 落库）；文案 W4 接 LLM。
class StretchViewModel extends Notifier<StretchState> {
  final StreamController<StretchEvent> _events =
      StreamController<StretchEvent>.broadcast();

  /// 一次性事件流，由 ScreenRoute 订阅并处理。
  Stream<StretchEvent> get onEvent => _events.stream;

  @override
  StretchState build() {
    ref.onDispose(_events.close);
    return const StretchState(
      headline: '起来倒杯水，顺便做个颈部拉伸？',
      subCopy: '坐了一个多小时啦，脖子该抗议了——',
      sectionLabel: '为你准备的 1 分钟',
      actions: [
        StretchAction(
          name: '颈部侧拉伸',
          durationLabel: '40 秒 · 每侧 2 次',
          recommended: true,
        ),
        StretchAction(name: '收下巴', durationLabel: '30 秒 · 2 次'),
        StretchAction(name: '肩部画圈', durationLabel: '60 秒'),
      ],
    );
  }

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  Future<void> handleIntent(StretchIntent intent) async {
    switch (intent) {
      case ClosePressed():
        _events.add(const StretchFinished());
      case SkipThisPressed():
        // W3：记录一次跳过反馈后结束
        _events.add(const StretchSkipped());
      case ActionTapped():
        // 详情页导航由 ScreenRoute 直接处理（见 stretch_screen.dart 的
        // onActionTapped 回调），不经 VM。
        break;
      case FeedbackSelected(:final feedback):
        // W2-e：四态反馈回流（引擎即时调整 + feedback_event 落库）后结束。
        await _recordFeedback(feedback);
        _events.add(const StretchFinished());
    }
  }

  /// 四态反馈 → RecordFeedbackUseCase（FR-6 本地即时生效）。
  ///
  /// 拉伸页入口即久坐提醒（W3 深链后由 advice_id 携带来源类别）。
  Future<void> _recordFeedback(StretchFeedback feedback) async {
    final action = switch (feedback) {
      StretchFeedback.done => FeedbackAction.done,
      StretchFeedback.later => FeedbackAction.snooze,
      StretchFeedback.muteToday => FeedbackAction.stopToday,
      StretchFeedback.neverAgain => FeedbackAction.neverAgain,
    };
    try {
      await GetIt.I<RecordFeedbackUseCase>()(
        action: action,
        kind: ReminderKind.sedentary,
      );
    } catch (_) {
      // 反馈落库失败不阻断退出（引擎仍按既有状态运行）。
    }
  }
}

/// 拉伸页状态容器（push 进入：pop 后状态随 provider 自动销毁）。
final stretchViewModelProvider =
    NotifierProvider<StretchViewModel, StretchState>(StretchViewModel.new);
