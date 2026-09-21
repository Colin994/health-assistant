import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'home_intent.dart';
import 'home_state.dart';

/// HomeScreen 的状态持有者（架构文档 3.2）。
///
/// W1 阶段以设计稿 04 的占位数据驱动 UI；W2 接入
/// FetchSegmentsUseCase / ReminderRepository 后替换为真实数据。
@injectable
class HomeViewModel extends ChangeNotifier {
  HomeState _state = const HomeState(
    dataSourceLabel: 'Apple Watch · 数据更新 5 分钟前',
    reminderCount: 3,
    completedCount: 2,
    nextEstimateText: '如果你持续坐着，约 14:30 会提醒你',
    records: [
      HomeRecord(timeLabel: '11:20', actionName: '颈部侧拉伸', statusLabel: '完成'),
    ],
  );

  /// 当前视图数据。
  HomeState get state => _state;

  /// 统一的 Intent 入口（Screen 经 onIntent 回调转发至此）。
  void handleIntent(HomeIntent intent) {
    switch (intent) {
      case RefreshPressed():
        // W2：重新拉取活动分段并重算「下次提醒预估」
        notifyListeners();
    }
  }
}
