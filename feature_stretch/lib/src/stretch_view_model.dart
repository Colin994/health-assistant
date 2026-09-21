import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'stretch_event.dart';
import 'stretch_intent.dart';
import 'stretch_state.dart';

/// StretchScreen 的状态持有者（架构文档 3.2）。
///
/// W1 阶段以设计稿 05 的占位文案驱动 UI；W4 接 LLM 文案、
/// W5 接 RecordFeedbackUseCase 回流。
@injectable
class StretchViewModel extends ChangeNotifier {
  final StretchState _state = const StretchState(
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

  /// 当前视图数据。
  StretchState get state => _state;

  final StreamController<StretchEvent> _events =
      StreamController<StretchEvent>.broadcast();

  /// 一次性事件流，由 ScreenRoute 订阅并处理。
  Stream<StretchEvent> get onEvent => _events.stream;

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(StretchIntent intent) {
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
      case FeedbackSelected():
        // W5：RecordFeedbackUseCase（本地即时降频 + 上报）后结束
        _events.add(const StretchFinished());
    }
  }

  @override
  void dispose() {
    _events.close();
    super.dispose();
  }
}
