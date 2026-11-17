import 'dart:async';

import 'package:base_utils/base_utils.dart';
import 'package:core_database/core_database.dart';
import 'package:core_health/core_health.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'catch_drop/catch_drop_session.dart';
import 'game_event.dart';
import 'game_feel.dart';
import 'game_intent.dart';
import 'game_state.dart';
import 'garden_scene.dart';
import 'star_gazing/star_gazing_session.dart';

/// GameScreen 的状态持有者(Riverpod Notifier,架构文档 3.2)。
///
/// v0.5:接阳光/接雨滴(侧屈)+ 看星星(仰头,Pro 资格)+ 花园经济。
class GameViewModel extends Notifier<GameState> with WidgetsBindingObserver {
  GameViewModel();

  final StreamController<GameEvent> _events =
      StreamController<GameEvent>.broadcast();

  /// 一次性事件流,由 ScreenRoute 订阅并处理。
  Stream<GameEvent> get onEvent => _events.stream;

  static const int _countdownFrom = 3;

  Timer? _countdownTimer;
  Timer? _gameTimer;
  StreamSubscription<PoseSample>? _poseSub;
  StreamSubscription<PoseEvent>? _poseEventSub;
  StreamSubscription<int>? _stepsSub;
  PoseSample? _zero;

  /// 订阅时缓存实例:dispose 回调中禁止使用 ref(Riverpod 3 约束)。
  PoseStream? _poseStream;
  GameEconomyStore? _economy;

  CatchDropSession? _catchSession;
  StarGazingSession? _starSession;
  PoseSample? _latestRel;

  /// 金阳光在场状态(检测首次出现以触发提醒)。
  bool _goldenWasPresent = false;

  // 看星星 eyes-free 反馈节流
  int _starCollectedCount = 0;
  int _lastStarPulseMs = 0;

  /// 注入时钟(不读墙钟,跨日配额判定可测)。
  Clock get _clock => ref.read(gameClockProvider);

  @override
  GameState build() {
    ref.onDispose(_teardown);
    WidgetsBinding.instance.addObserver(this);
    _subscribePoseStream();
    unawaited(_initEconomy().catchError(_reportAsyncError));
    return const GameState();
  }

  /// 应用退后台:立即停局并释放相机(D 项)。
  ///
  /// 不自动恢复——相机已释放,恢复需要重新校准,回到花园让用户
  /// 主动重开更安全(也避免后台占用相机被系统/其他应用抢占)。
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden) {
      return;
    }
    final inSession =
        state.phase == GamePhase.countdown ||
        state.phase == GamePhase.calibrating ||
        state.phase == GamePhase.playing ||
        state.phase == GamePhase.paused;
    if (!inSession) {
      return;
    }
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _poseStream?.stop().ignore();
    _catchSession = null;
    _starSession = null;
    _goldenWasPresent = false;
    state = state.clearedSession().copyWith(
      phase: GamePhase.idle,
      statusText: '应用切到后台,已暂停并释放相机;需要时重新开始一局',
    );
  }

  void _subscribePoseStream() {
    final PoseStream poseStream = ref.read(gamePoseStreamProvider);
    _poseStream = poseStream;
    _poseSub = poseStream.poses.listen((sample) {
      final zero = _zero;
      if (zero == null || !sample.faceDetected) {
        return;
      }
      final rel = sample.relativeTo(zero);
      _latestRel = rel;
      state = state.copyWith(
        latestPitch: rel.pitch,
        latestRoll: rel.roll,
        latestYaw: rel.yaw,
      );
    });
    _poseEventSub = poseStream.events.listen(_onPoseEvent);
    _stepsSub = ref.read(todayStepsProvider).listen((steps) {
      state = state.copyWith(todaySteps: steps);
    });
  }

  Future<void> _initEconomy() async {
    final store = ref.read(gameEconomyProvider);
    _economy = store;
    final loaded = await store.load();
    if (ref.mounted) _syncEconomyState(loaded);
  }

  void _syncEconomyState(GameEconomyState economy) {
    state = state.copyWith(
      gardenTime: GardenTimeOfDay.fromClock(_clock.now()),
      todaySunshineTotal: economy.sunshineTotal,
      stardustTotal: economy.stardustTotal,
      quotaRemaining: isDevBuild
          ? 99 // dev 不限次(测试期)
          : (_economy?.quotaRemaining(_clock.now()) ?? 3),
      plots: List<PlotState?>.from(economy.plots),
      decorations: List<String>.from(economy.decorations),
      harvestedCount: economy.harvestedCount,
      harvestCounts: Map<String, int>.from(economy.harvestCounts),
      starGazeUnlocked: economy.starGazeUnlocked,
      unlockedAdvancedSeeds: List<String>.from(economy.unlockedAdvancedSeeds),
    );
  }

  int _feedbackSequence = 0;
  Future<void> _mutationTail = Future<void>.value();

  /// The route may call this directly; expected I/O failures become visible state.
  Future<void> handleIntent(GameIntent intent) async {
    try {
      switch (intent) {
        case SeedSelected(:final plotIndex, :final species):
          await _mutate(GardenAction.plant, '$plotIndex', () async {
            final ok = await _economy!.plantSeed(plotIndex, species);
            return (ok, ok ? '已种下，慢慢长大吧' : '这块地暂时不能种植这颗种子');
          }, plotIndex: plotIndex);
        case InvestPressed(:final plotIndex):
          await _mutate(GardenAction.invest, '$plotIndex', () async {
            final actual = await _economy!.investSunshine(plotIndex, 30);
            return (actual > 0, actual > 0 ? '已投入 $actual 阳光' : '暂时没有可投入的阳光');
          }, plotIndex: plotIndex);
        case HarvestPressed(:final plotIndex):
          await _mutate(GardenAction.harvest, '$plotIndex', () async {
            final species = await _economy!.harvest(plotIndex);
            return (
              species != null,
              species != null ? '已收入押花册' : '植物还没有到收获的时候',
            );
          }, plotIndex: plotIndex);
        case BuyDecorationPressed(:final decorationId):
          await _mutate(GardenAction.buyDecoration, decorationId, () async {
            if (_economy!.state.decorations.contains(decorationId)) {
              return (false, '这件装饰已经在花园里了');
            }
            final ok = await _economy!.buyDecoration(decorationId);
            return (ok, ok ? '已放进花园' : '阳光不足，先去接些阳光吧');
          }, decorationId: decorationId);
        case ExchangeAdvancedSeedPressed():
          await _mutate(GardenAction.exchange, 'seed', () async {
            if (_economy!.state.nextAdvancedSeed == null) {
              return (false, '高级种子已全部解锁');
            }
            final id = await _economy!.tryExchangeAdvancedSeed();
            final name = seedCatalog.where((s) => s.id == id).firstOrNull?.name;
            return (
              id != null,
              id == null ? '需要 100 星屑，慢慢积累就好' : '已解锁$name，可以种下了',
            );
          });
        case StartCatchDropPressed():
          await _startSession(GameKind.catchDrop);
        case StartStarGazingPressed():
          if (!state.starGazeUnlocked) {
            state = state.copyWith(statusText: '首株植物盛开后解锁看星星');
            return;
          }
          await _startSession(GameKind.starGazing);
        case FinishEarlyPressed():
          _finishEarly();
        case BackToGardenPressed():
          _gameTimer?.cancel();
          _catchSession = null;
          _starSession = null;
          state = state.clearedSession();
        case ExitPressed():
          _events.add(const GameExited());
      }
    } catch (error, stack) {
      AppLogger.error('游戏操作失败', tag: 'game', error: (error, stack));
      if (ref.mounted) state = state.copyWith(statusText: '操作未完成，请稍后重试');
    }
  }

  Future<void> _mutate(
    GardenAction action,
    String target,
    Future<(bool, String)> Function() operation, {
    int? plotIndex,
    String? decorationId,
  }) async {
    if (_economy == null ||
        (plotIndex != null && state.pendingPlotIndices.contains(plotIndex)) ||
        (decorationId != null &&
            state.pendingDecorationIds.contains(decorationId)) ||
        (action == GardenAction.exchange && state.isExchangingSeed)) {
      return;
    }
    state = state.copyWith(
      pendingPlotIndices: {...state.pendingPlotIndices, ?plotIndex},
      pendingDecorationIds: {...state.pendingDecorationIds, ?decorationId},
      isExchangingSeed:
          action == GardenAction.exchange || state.isExchangingSeed,
    );
    // Serialize wallet writes across different targets as well as guarding double taps.
    final previous = _mutationTail;
    final done = Completer<void>();
    _mutationTail = done.future;
    try {
      await previous;
      if (!ref.mounted) return;
      final (success, message) = await operation();
      if (!ref.mounted) return;
      _syncEconomyState(_economy!.state);
      if (success) GameFeel.standard.onTap();
      state = state.copyWith(
        shopHint: message,
        feedback: GardenFeedback(
          sequence: ++_feedbackSequence,
          action: action,
          target: target,
          success: success,
          message: message,
        ),
      );
    } catch (error, stack) {
      AppLogger.error('花园保存失败', tag: 'game', error: (error, stack));
      if (ref.mounted) {
        state = state.copyWith(
          feedback: GardenFeedback(
            sequence: ++_feedbackSequence,
            action: action,
            target: target,
            success: false,
            message: '保存未完成，请重试',
          ),
        );
      }
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          pendingPlotIndices: {...state.pendingPlotIndices}..remove(plotIndex),
          pendingDecorationIds: {...state.pendingDecorationIds}
            ..remove(decorationId),
          isExchangingSeed: action == GardenAction.exchange
              ? false
              : state.isExchangingSeed,
        );
      }
      done.complete();
    }
  }

  Future<void> _startSession(GameKind kind) async {
    if (state.phase != GamePhase.idle && state.phase != GamePhase.error) {
      return;
    }
    final store = _economy;
    if (store == null) {
      return;
    }
    // 额度:dev 构建不限次(开发测试期);master 保持每日 3 局剂量上限。
    if (!isDevBuild && store.quotaRemaining(_clock.now()) <= 0) {
      state = state.copyWith(statusText: '☀️ 今日光照已足,颈椎也需要休息,明天再练');
      return;
    }
    final poseStream = _poseStream!;
    try {
      await poseStream.start();
    } catch (error) {
      AppLogger.error('相机启动失败(权限被拒或不可用)', tag: 'game', error: error);
      state = state.copyWith(
        phase: GamePhase.error,
        statusText: '相机不可用或权限被拒绝,请检查后重试',
      );
      return;
    }
    // 相机就绪后扣额度(相机失败的尝试不占额度;dev 不扣)。
    if (!isDevBuild) {
      await store.tryUseDailyQuota(_clock.now());
    }
    state = state.copyWith(
      phase: GamePhase.countdown,
      kind: kind,
      countdownSeconds: _countdownFrom,
      statusText: '',
      quotaRemaining: store.quotaRemaining(_clock.now()),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.countdownSeconds - 1;
      if (next > 0) {
        state = state.copyWith(countdownSeconds: next);
        return;
      }
      timer.cancel();
      _beginCalibration();
    });
  }

  Future<void> _beginCalibration() async {
    state = state.copyWith(
      phase: GamePhase.calibrating,
      countdownSeconds: 0,
      statusText: '正脸入画,目视屏幕中央,保持 2 秒',
    );
    final poseStream = _poseStream!;
    try {
      await poseStream.calibrate();
    } on StateError {
      state = state.copyWith(
        phase: GamePhase.error,
        statusText: '校准期间未检出人脸,请正对前置摄像头重试',
      );
    }
  }

  void _onPoseEvent(PoseEvent event) {
    switch (event) {
      case PoseCalibrated(:final zero):
        _zero = zero;
        switch (state.kind) {
          case GameKind.catchDrop:
            _startCatchDrop();
          case GameKind.starGazing:
            _startStarGazing();
        }
      case PoseFaceLost():
        _pauseGame();
      case PoseFaceBack():
        _resumeGame();
      case PoseSourceError(:final message):
        state = state.copyWith(phase: GamePhase.error, statusText: message);
    }
  }

  // ---------- 接阳光/接雨滴(侧屈,§6.1) ----------

  void _startCatchDrop() {
    final session = CatchDropSession();
    _catchSession = session;
    state = state.copyWith(
      phase: GamePhase.playing,
      kind: GameKind.catchDrop,
      catchSnapshot: session.snapshot,
      statusText: '左右倾斜,让容器接住落下的阳光',
    );
    GameFeel.standard.onStart();
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      CatchDropConfig.standard.tickInterval,
      (_) => _catchTick(),
    );
  }

  void _catchTick() {
    final session = _catchSession;
    if (session == null) {
      return;
    }
    final snap = session.advance(
      dt: CatchDropConfig.standard.tickInterval,
      headRoll: _latestRel?.roll ?? 0,
    );
    // 事件 → 触感 + UI 特效
    final events = session.drainEvents();
    for (final e in events) {
      switch (e) {
        case DropCaught(:final kind, :final combo):
          if (kind == DropKind.golden) {
            GameFeel.standard.onGoldenCatch();
          } else {
            GameFeel.standard.onCatch(combo);
          }
        case ComboBroken():
          GameFeel.standard.onComboBroken();
        case DropMissed():
          GameFeel.standard.onMiss();
      }
    }
    if (snap.phase == CatchDropPhase.finished) {
      _gameTimer?.cancel();
      unawaited(_settleCatchDrop(session).catchError(_reportAsyncError));
      return;
    }
    // 金阳光首次出现 → 震动提醒(用户可能并未盯屏幕)。
    if (snap.goldenPresent && !_goldenWasPresent) {
      GameFeel.standard.onGoldenAppear();
    }
    _goldenWasPresent = snap.goldenPresent;

    state = state.copyWith(
      catchSnapshot: snap,
      catchEvents: events,
      catchEventSeq: state.catchEventSeq + (events.isEmpty ? 0 : 1),
      statusText: _catchStatus(snap),
    );
  }

  /// 接阳光玩法的分步引导(告诉用户「现在该做什么」)。
  String _catchStatus(CatchDropSnapshot snap) {
    if (snap.canFinishEarly) {
      return '达标!可提前完成,或继续接';
    }
    if (snap.goldenPresent) {
      final side = snap.goldenSide < 0 ? '左' : '右';
      if (!snap.goldenAligned) {
        return '金阳光!把篮子移到$side侧下方';
      }
      if (!snap.goldenTiltOk) {
        return '再向$side倾深一点,然后保持';
      }
      final pct = (snap.goldenChargeProgress * 100).round();
      return '保持住!$pct%';
    }
    return '左右倾斜,接住落下的阳光';
  }

  Future<void> _settleCatchDrop(CatchDropSession session) async {
    const cfg = CatchDropConfig.standard;
    final score = session.score;
    final sunshine = cfg.sunshineFor(score);
    final elapsed = session.elapsed.inSeconds;
    final store = _economy;
    if (store != null) {
      await store.addSunshine(sunshine);
      if (!ref.mounted) return;
      _syncEconomyState(store.state);
    }
    state = state.copyWith(
      phase: GamePhase.result,
      kind: GameKind.catchDrop,
      resultScore: score,
      resultElapsedSeconds: elapsed,
      resultCaughtNormal: session.caughtNormal,
      resultCaughtGolden: session.caughtGolden,
      resultSunshine: sunshine,
      resultStardust: 0,
      resultFinishedEarly: elapsed < cfg.sessionDuration.inSeconds,
      statusText: '',
    );
    GameFeel.standard.onFinish();
  }

  // ---------- 看星星(仰头,§6.2.1) ----------

  void _startStarGazing() {
    final session = StarGazingSession();
    _starSession = session;
    _starCollectedCount = 0;
    _lastStarPulseMs = 0;
    state = state.copyWith(
      phase: GamePhase.playing,
      kind: GameKind.starGazing,
      starSnapshot: session.snapshot,
      statusText: '慢慢仰头,让视野对准亮星',
    );
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(
      StarGazingConfig.standard.tickInterval,
      (_) => _starTick(),
    );
  }

  void _starTick() {
    final session = _starSession;
    if (session == null) {
      return;
    }
    final snap = session.advance(
      dt: StarGazingConfig.standard.tickInterval,
      headPitch: _latestRel?.pitch ?? 0,
    );
    if (snap.phase == StarGazingPhase.finished) {
      _gameTimer?.cancel();
      unawaited(_settleStarGazing(session).catchError(_reportAsyncError));
      return;
    }
    // eyes-free 主反馈:仰头时看不到屏幕,用触感/音效告诉用户「还在对准」。
    if (snap.collectedCount > _starCollectedCount) {
      GameFeel.standard.onStarCollected();
      _starCollectedCount = snap.collectedCount;
    } else if (snap.aligned) {
      final now = _clock.now().millisecondsSinceEpoch;
      if (now - _lastStarPulseMs >= 900) {
        GameFeel.standard.onStarAligned();
        _lastStarPulseMs = now;
      }
    }
    state = state.copyWith(
      starSnapshot: snap,
      statusText: snap.aligned
          ? '对准了,保持…'
          : (snap.targetIsRecentring ? '回到平视,收集回中星' : '慢慢仰头,对准亮星'),
    );
  }

  Future<void> _settleStarGazing(StarGazingSession session) async {
    const cfg = StarGazingConfig.standard;
    final score = session.score;
    final stardust = cfg.stardustFor(score);
    final elapsed = session.elapsed.inSeconds;
    final store = _economy;
    String? unlocked;
    if (store != null) {
      await store.addStardust(stardust);
      if (!ref.mounted) return;
      // 满 100 自动兑换下一颗高级种子(§5.1)。
      unlocked = await store.tryExchangeAdvancedSeed();
      if (!ref.mounted) return;
      _syncEconomyState(store.state);
    }
    state = state.copyWith(
      phase: GamePhase.result,
      kind: GameKind.starGazing,
      resultScore: score,
      resultElapsedSeconds: elapsed,
      resultStars: session.collectedCount,
      resultSunshine: 0,
      resultStardust: stardust,
      resultUnlockedSeed: unlocked,
      resultFinishedEarly: elapsed < cfg.sessionDuration.inSeconds,
      statusText: '',
    );
  }

  // ---------- 通用 ----------

  void _finishEarly() {
    final catchSession = _catchSession;
    if (catchSession != null && catchSession.finishEarly()) {
      _gameTimer?.cancel();
      unawaited(_settleCatchDrop(catchSession).catchError(_reportAsyncError));
      return;
    }
    final starSession = _starSession;
    if (starSession != null && starSession.finishEarly()) {
      _gameTimer?.cancel();
      unawaited(_settleStarGazing(starSession).catchError(_reportAsyncError));
    }
  }

  void _pauseGame() {
    if (state.phase != GamePhase.playing) {
      return;
    }
    _gameTimer?.cancel();
    state = state.copyWith(
      phase: GamePhase.paused,
      statusText: '已暂停:回到画面前保持放松',
    );
  }

  void _resumeGame() {
    if (state.phase != GamePhase.paused) {
      return;
    }
    state = state.copyWith(phase: GamePhase.playing);
    _gameTimer?.cancel();
    switch (state.kind) {
      case GameKind.catchDrop:
        _gameTimer = Timer.periodic(
          CatchDropConfig.standard.tickInterval,
          (_) => _catchTick(),
        );
      case GameKind.starGazing:
        _gameTimer = Timer.periodic(
          StarGazingConfig.standard.tickInterval,
          (_) => _starTick(),
        );
    }
  }

  void _reportAsyncError(Object error, StackTrace stack) {
    AppLogger.error('练习保存失败', tag: 'game', error: (error, stack));
    if (ref.mounted) {
      state = state.copyWith(
        phase: GamePhase.error,
        statusText: '保存未完成，请返回花园后重试',
      );
    }
  }

  void _teardown() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _gameTimer?.cancel();
    _poseSub?.cancel();
    _poseEventSub?.cancel();
    _stepsSub?.cancel();
    _events.close();
    _poseStream?.stop().ignore();
    _poseStream = null;
    _zero = null;
    _catchSession = null;
    _starSession = null;
  }
}

/// 姿态流注入点:默认取 get_it(core_health 注册);测试用 provider 覆盖。
final gamePoseStreamProvider = Provider<PoseStream>(
  (ref) => GetIt.I<PoseStream>(),
);

/// 注入时钟:每日配额跨日判定用(测试 override 假时钟驱动边界场景)。
final gameClockProvider = Provider<Clock>((ref) => const SystemClock());

/// 经济存储注入点:默认取 get_it(core_database 注册);测试覆盖。
final gameEconomyProvider = Provider<GameEconomyStore>(
  (ref) => GetIt.I<GameEconomyStore>(),
);

/// 今日步数流注入点:默认取计步采集器(core_health);测试覆盖。
final todayStepsProvider = Provider<Stream<int>>(
  (ref) => GetIt.I<StepSessionCollector>().todaySteps,
);

/// 游戏页状态容器。
///
/// autoDispose:页面 pop 后 provider 自动销毁 → onDispose 释放相机与订阅
/// (P1 修复:此前常驻会残留相机与姿态订阅,二次进入复用旧状态)。
final gameViewModelProvider =
    NotifierProvider.autoDispose<GameViewModel, GameState>(GameViewModel.new);

/// firstOrNull(仓库惯例)。
extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
