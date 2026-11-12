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
import 'star_gazing/star_gazing_session.dart';

/// GameScreen 的状态持有者(Riverpod Notifier,架构文档 3.2)。
///
/// v0.5:接阳光/接雨滴(侧屈)+ 看星星(仰头,Pro 资格)+ 花园经济。
class GameViewModel extends Notifier<GameState>
    with WidgetsBindingObserver {
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
    _initEconomy();
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
    final inSession = state.phase == GamePhase.countdown ||
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
    _syncEconomyState(await store.load());
  }

  void _syncEconomyState(GameEconomyState economy) {
    state = state.copyWith(
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

  Future<void> handleIntent(GameIntent intent) async {
    switch (intent) {
      case StartCatchDropPressed():
        await _startSession(GameKind.catchDrop);
      case StartStarGazingPressed():
        if (!state.starGazeUnlocked) {
          state = state.copyWith(
            statusText: '种出一株盛开的花,星空就会为你打开',
          );
          return;
        }
        await _startSession(GameKind.starGazing);
      case FinishEarlyPressed():
        _finishEarly();
      case SeedSelected(:final plotIndex, :final species):
        final store = _economy;
        if (store == null) {
          return;
        }
        await store.plantSeed(plotIndex, species);
        _syncEconomyState(store.state);
      case InvestPressed(:final plotIndex):
        final store = _economy;
        if (store == null) {
          return;
        }
        final invested = await store.investSunshine(plotIndex, 30);
        _syncEconomyState(store.state);
        state = state.copyWith(
          statusText: invested > 0 ? '' : '阳光不足,去玩一局接阳光吧',
        );
      case HarvestPressed(:final plotIndex):
        final store = _economy;
        if (store == null) {
          return;
        }
        final species = await store.harvest(plotIndex);
        if (species != null) {
          _syncEconomyState(store.state);
          _events.add(PlotHarvested(species, store.state.harvestedCount));
        }
      case BuyDecorationPressed(:final decorationId):
        await _buyDecoration(decorationId);
      case ExchangeAdvancedSeedPressed():
        await _exchangeAdvancedSeed();
      case BackToGardenPressed():
        _gameTimer?.cancel();
        _catchSession = null;
        _starSession = null;
        state = state.clearedSession();
      case ExitPressed():
        _events.add(const GameExited());
    }
  }

  Future<void> _buyDecoration(String id) async {
    final store = _economy;
    if (store == null) {
      return;
    }
    final ok = await store.buyDecoration(id);
    if (!ok) {
      state = state.copyWith(shopHint: '阳光不够或已拥有');
      return;
    }
    _syncEconomyState(store.state);
    state = state.copyWith(shopHint: '已放进花园');
  }

  Future<void> _exchangeAdvancedSeed() async {
    final store = _economy;
    if (store == null) {
      return;
    }
    final species = await store.tryExchangeAdvancedSeed();
    _syncEconomyState(store.state);
    if (species == null) {
      state = state.copyWith(
        shopHint: state.stardustTotal < 100 ? '再攒些星屑(需 100)' : '高级种子已全部解锁',
      );
      return;
    }
    final name = seedCatalog
        .where((s) => s.id == species)
        .map((s) => s.name)
        .firstOrNull;
    state = state.copyWith(shopHint: '解锁「${name ?? species}」,可以种下了');
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
      state = state.copyWith(
        statusText: '☀️ 今日光照已足,颈椎也需要休息,明天再练',
      );
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
      unawaited(_settleCatchDrop(session));
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
      unawaited(_settleStarGazing(session));
      return;
    }
    // eyes-free 主反馈:仰头时看不到屏幕,用触感/音效告诉用户「还在对准」。
    if (snap.collectedCount > _starCollectedCount) {
      GameFeel.standard.onStarCollected();
      _starCollectedCount = snap.collectedCount;
    } else if (snap.aligned) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastStarPulseMs >= 900) {
        GameFeel.standard.onStarAligned();
        _lastStarPulseMs = now;
      }
    }
    state = state.copyWith(
      starSnapshot: snap,
      statusText: snap.aligned
          ? '对准了,保持…'
          : (snap.targetIsRecentring
              ? '回到平视,收集回中星'
              : '慢慢仰头,对准亮星'),
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
      // 满 100 自动兑换下一颗高级种子(§5.1)。
      unlocked = await store.tryExchangeAdvancedSeed();
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
      unawaited(_settleCatchDrop(catchSession));
      return;
    }
    final starSession = _starSession;
    if (starSession != null && starSession.finishEarly()) {
      _gameTimer?.cancel();
      unawaited(_settleStarGazing(starSession));
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
