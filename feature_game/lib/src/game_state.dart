import 'package:core_database/core_database.dart';
import 'package:flutter/foundation.dart';

import 'catch_drop/catch_drop_session.dart';
import 'star_gazing/star_gazing_session.dart';

/// 游戏会话阶段(《慢植物小游戏设计方案》v0.5)。
enum GamePhase {
  /// 花园:玩法入口、地块、经济条、商店。
  idle,

  /// 3-2-1 倒计时(手持 → 练习过渡,§3.1)。
  countdown,

  /// 校准中:正脸入画 2 秒取零点。
  calibrating,

  /// 练习中(由 [GameState.kind] 区分接阳光/看星星)。
  playing,

  /// 离画暂停(安全机制,非失败,§2)。
  paused,

  /// 一局结束,展示结算(§6 公共流程)。
  result,

  /// 数据源错误。
  error,
}

/// 玩法种类(v0.5)。
enum GameKind {
  /// 接阳光/接雨滴(侧屈)。
  catchDrop,

  /// 看星星(仰头,Pro 资格)。
  starGazing,
}

/// GameScreen 的视图数据类(不可变,变更经 copyWith 重建)。
@immutable
class GameState {
  const GameState({
    this.phase = GamePhase.idle,
    this.kind = GameKind.catchDrop,
    this.countdownSeconds = 0,
    this.statusText = '',
    this.latestPitch = 0,
    this.latestRoll = 0,
    this.latestYaw = 0,
    // 玩法快照(VM 每拍整体替换;UI 直接读)
    this.catchSnapshot,
    this.catchEvents = const [],
    this.catchEventSeq = 0,
    this.starSnapshot,
    // 结算
    this.resultScore = 0,
    this.resultElapsedSeconds = 0,
    this.resultCaughtNormal = 0,
    this.resultCaughtGolden = 0,
    this.resultStars = 0,
    this.resultSunshine = 0,
    this.resultStardust = 0,
    this.resultUnlockedSeed,
    this.resultFinishedEarly = false,
    // 经济
    this.todaySunshineTotal = 0,
    this.stardustTotal = 0,
    this.todaySteps = 0,
    this.quotaRemaining = 3,
    this.plots = const [null, null, null, null],
    this.decorations = const [],
    this.harvestedCount = 0,
    this.harvestCounts = const {},
    this.starGazeUnlocked = false,
    this.unlockedAdvancedSeeds = const [],
    this.shopHint = '',
  });

  final GamePhase phase;

  /// 本局玩法。
  final GameKind kind;

  final int countdownSeconds;
  final String statusText;

  // 头部相对姿态读数(度)。
  final double latestPitch;
  final double latestRoll;
  final double latestYaw;

  // ---- 玩法快照 ----
  final CatchDropSnapshot? catchSnapshot;
  /// 最近一批打点事件(Board 依 seq 去重消费)。
  final List<CatchEvent> catchEvents;
  final int catchEventSeq;
  final StarGazingSnapshot? starSnapshot;

  // ---- 结算 ----
  /// 本局得分。
  final int resultScore;

  /// 完成用时(秒;提前完成时为实际用时)。
  final int resultElapsedSeconds;

  final int resultCaughtNormal;
  final int resultCaughtGolden;

  /// 看星星:收集星数(含回中星)。
  final int resultStars;

  /// 换算阳光(接阳光玩法;看星星为 0)。
  final int resultSunshine;

  /// 换算星屑(看星星;接阳光为 0)。
  final int resultStardust;

  /// 本局星屑兑换解锁的高级种子(非空则结算弹窗庆祝)。
  final String? resultUnlockedSeed;

  /// 是否提前完成。
  final bool resultFinishedEarly;

  // ---- 经济 ----
  final int todaySunshineTotal;
  final int stardustTotal;
  final int todaySteps;
  final int quotaRemaining;

  /// 四块地块(null = 空地)。
  final List<PlotState?> plots;

  /// 已购装饰 id。
  final List<String> decorations;

  /// 押花册计数。
  final int harvestedCount;

  /// 按物种的收获次数(押花册页面)。
  final Map<String, int> harvestCounts;

  /// 看星星资格(任意植物盛开或收获过,§6.2)。
  final bool starGazeUnlocked;

  /// 已用星屑兑换的高级种子物种 id。
  final List<String> unlockedAdvancedSeeds;

  final String shopHint;

  GameState copyWith({
    GamePhase? phase,
    GameKind? kind,
    int? countdownSeconds,
    String? statusText,
    double? latestPitch,
    double? latestRoll,
    double? latestYaw,
    CatchDropSnapshot? catchSnapshot,
    List<CatchEvent>? catchEvents,
    int? catchEventSeq,
    StarGazingSnapshot? starSnapshot,
    int? resultScore,
    int? resultElapsedSeconds,
    int? resultCaughtNormal,
    int? resultCaughtGolden,
    int? resultStars,
    int? resultSunshine,
    int? resultStardust,
    String? resultUnlockedSeed,
    bool? resultFinishedEarly,
    int? todaySunshineTotal,
    int? stardustTotal,
    int? todaySteps,
    int? quotaRemaining,
    List<PlotState?>? plots,
    List<String>? decorations,
    int? harvestedCount,
    Map<String, int>? harvestCounts,
    bool? starGazeUnlocked,
    List<String>? unlockedAdvancedSeeds,
    String? shopHint,
  }) {
    return GameState(
      phase: phase ?? this.phase,
      kind: kind ?? this.kind,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      statusText: statusText ?? this.statusText,
      latestPitch: latestPitch ?? this.latestPitch,
      latestRoll: latestRoll ?? this.latestRoll,
      latestYaw: latestYaw ?? this.latestYaw,
      catchSnapshot: catchSnapshot ?? this.catchSnapshot,
      catchEvents: catchEvents ?? this.catchEvents,
      catchEventSeq: catchEventSeq ?? this.catchEventSeq,
      starSnapshot: starSnapshot ?? this.starSnapshot,
      resultScore: resultScore ?? this.resultScore,
      resultElapsedSeconds:
          resultElapsedSeconds ?? this.resultElapsedSeconds,
      resultCaughtNormal: resultCaughtNormal ?? this.resultCaughtNormal,
      resultCaughtGolden: resultCaughtGolden ?? this.resultCaughtGolden,
      resultStars: resultStars ?? this.resultStars,
      resultSunshine: resultSunshine ?? this.resultSunshine,
      resultStardust: resultStardust ?? this.resultStardust,
      resultUnlockedSeed: resultUnlockedSeed ?? this.resultUnlockedSeed,
      resultFinishedEarly:
          resultFinishedEarly ?? this.resultFinishedEarly,
      todaySunshineTotal: todaySunshineTotal ?? this.todaySunshineTotal,
      stardustTotal: stardustTotal ?? this.stardustTotal,
      todaySteps: todaySteps ?? this.todaySteps,
      quotaRemaining: quotaRemaining ?? this.quotaRemaining,
      plots: plots ?? this.plots,
      decorations: decorations ?? this.decorations,
      harvestedCount: harvestedCount ?? this.harvestedCount,
      harvestCounts: harvestCounts ?? this.harvestCounts,
      starGazeUnlocked: starGazeUnlocked ?? this.starGazeUnlocked,
      unlockedAdvancedSeeds:
          unlockedAdvancedSeeds ?? this.unlockedAdvancedSeeds,
      shopHint: shopHint ?? this.shopHint,
    );
  }

  /// 清空玩法快照与结算(回花园时)。
  GameState clearedSession() => GameState(
        todaySunshineTotal: todaySunshineTotal,
        stardustTotal: stardustTotal,
        todaySteps: todaySteps,
        quotaRemaining: quotaRemaining,
        plots: plots,
        decorations: decorations,
        harvestedCount: harvestedCount,
        harvestCounts: harvestCounts,
        starGazeUnlocked: starGazeUnlocked,
        unlockedAdvancedSeeds: unlockedAdvancedSeeds,
      );
}
