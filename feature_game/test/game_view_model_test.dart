import 'dart:async';

import 'package:core_database/core_database.dart';
import 'package:core_health/core_health.dart';
import 'package:fake_async/fake_async.dart';
import 'package:feature_game/feature_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 假姿态流:校准零点 (pitch 5, roll -3);
/// 之后经 [emitPose] 注入绝对角样本(相对角 = 绝对 - 零点)。
class FakePoseStream implements PoseStream {
  final _poses = StreamController<PoseSample>.broadcast();
  final _events = StreamController<PoseEvent>.broadcast();
  bool started = false;
  bool stopped = false;
  Object? startError;

  @override
  Stream<PoseSample> get poses => _poses.stream;
  @override
  Stream<PoseEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    if (startError != null) {
      throw startError!;
    }
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> calibrate({Duration hold = const Duration(seconds: 2)}) async {
    Future<void>.delayed(const Duration(seconds: 2), () {
      _events.add(PoseCalibrated(PoseSample(
        pitch: 5,
        roll: -3,
        yaw: 0,
        timestampMs: 2000,
      )));
      _poses.add(PoseSample(pitch: 8, roll: 1, yaw: -6, timestampMs: 2100));
    });
  }

  /// 注入一帧绝对角(相对角 = 绝对 - 零点)。
  void emitPose({required double pitch, required double roll}) {
    _poses.add(PoseSample(
      pitch: pitch,
      roll: roll,
      yaw: 0,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      faceDetected: true,
    ));
  }

  void emit(PoseEvent event) => _events.add(event);
}

GameViewModel getVm(ProviderContainer c) =>
    c.read(gameViewModelProvider.notifier);
GameState getState(ProviderContainer c) => c.read(gameViewModelProvider);

ProviderContainer boot({
  required FakePoseStream fake,
  GameEconomyStore? economy,
  Stream<int>? steps,
}) {
  final container = ProviderContainer(
    overrides: [
      gamePoseStreamProvider.overrideWithValue(fake),
      gameEconomyProvider.overrideWithValue(economy ?? GameEconomyStore()),
      todayStepsProvider.overrideWithValue(steps ?? const Stream<int>.empty()),
    ],
  );
  // autoDispose:需持续订阅保持 provider 存活(等价于页面在屏)。
  container.listen(gameViewModelProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('接阳光全流程:倒计时 → 校准 → 90s 游戏 → 结算(阳光入账持久化)', () {
    fakeAsync((async) {
      final fake = FakePoseStream();
      final store = GameEconomyStore();
      final container = boot(fake: fake, economy: store);
      addTearDown(container.dispose);

      async.elapse(Duration.zero);
      getVm(container).handleIntent(const StartCatchDropPressed());
      async.elapse(const Duration());
      expect(fake.started, isTrue);
      expect(getState(container).quotaRemaining, 2); // 开局扣额度

      async.elapse(const Duration(seconds: 5)); // 倒计时 3 + 校准 2
      expect(getState(container).phase, GamePhase.playing);
      expect(getState(container).kind, GameKind.catchDrop);

      // 头保持中位(死区内),容器居中;90 秒后结算
      async.elapse(const Duration(seconds: 41));
      async.flushTimers();
      async.elapse(Duration.zero);

      final state = getState(container);
      expect(state.phase, GamePhase.result);
      expect(state.kind, GameKind.catchDrop);
      expect(state.resultSunshine, greaterThanOrEqualTo(10)); // 保底
      expect(state.resultElapsedSeconds, greaterThanOrEqualTo(40));
      expect(state.stardustTotal, 0); // 接阳光不产星屑
      expect(store.state.sunshineTotal, state.resultSunshine);
    });
  });

  test('看星星全流程:未解锁拒绝 → 解锁后 90s → 星屑入账', () {
    fakeAsync((async) {
      final fake = FakePoseStream();
      final store = GameEconomyStore();
      final container = boot(fake: fake, economy: store);
      addTearDown(container.dispose);
      final vm = getVm(container);
      async.elapse(Duration.zero);

      // 未解锁:给解锁条件文案,不启动相机
      vm.handleIntent(const StartStarGazingPressed());
      async.elapse(Duration.zero);
      expect(getState(container).phase, GamePhase.idle);
      expect(getState(container).statusText, contains('盛开'));
      expect(fake.started, isFalse);

      // 解锁:种一株花并投满(直接经 store,等价首株开花)
      unawaited(() async {
        await store.addSunshine(450);
        await store.plantSeed(0, 'lavender');
        await store.investSunshine(0, 450);
      }());
      async.elapse(const Duration(milliseconds: 50));
      // 触发经济同步:任意 intent 会 sync
      vm.handleIntent(const ExchangeAdvancedSeedPressed());
      async.elapse(Duration.zero);
      expect(getState(container).starGazeUnlocked, isTrue);

      // 开局看星星
      vm.handleIntent(const StartStarGazingPressed());
      async.elapse(const Duration(seconds: 5));
      expect(getState(container).phase, GamePhase.playing);
      expect(getState(container).kind, GameKind.starGazing);

      async.elapse(const Duration(seconds: 41));
      async.flushTimers();
      async.elapse(Duration.zero);

      final state = getState(container);
      expect(state.phase, GamePhase.result);
      expect(state.resultStardust, greaterThanOrEqualTo(12));
      expect(state.resultSunshine, 0); // 看星星不产阳光
      expect(store.state.stardustTotal, state.resultStardust);
    });
  });

  test('花园:种花→投入→收获全链路(持久化+押花册)', () {
    fakeAsync((async) {
      final fake = FakePoseStream();
      final store = GameEconomyStore();
      final container = boot(fake: fake, economy: store);
      addTearDown(container.dispose);
      final vm = getVm(container);
      async.elapse(Duration.zero);

      vm.handleIntent(const SeedSelected(0, 'sunflower'));
      async.elapse(Duration.zero);
      expect(getState(container).plots[0]?.species, 'sunflower');

      unawaited(() async {
        await store.addSunshine(500);
        for (var i = 0; i < 15; i++) {
          await store.investSunshine(0, 30);
        }
      }());
      async.elapse(const Duration(milliseconds: 50));
      expect(store.state.plots[0]!.harvestable, isTrue);

      vm.handleIntent(const HarvestPressed(0));
      async.elapse(Duration.zero);
      final state = getState(container);
      expect(state.plots[0], isNull);
      expect(state.harvestedCount, 1);
    });
  });

  test('装饰商店:阳光不足拒绝;足额购入即显示', () {
    fakeAsync((async) {
      final fake = FakePoseStream();
      final store = GameEconomyStore();
      final container = boot(fake: fake, economy: store);
      addTearDown(container.dispose);
      final vm = getVm(container);
      async.elapse(Duration.zero);

      vm.handleIntent(const BuyDecorationPressed('path'));
      async.elapse(Duration.zero);
      expect(getState(container).decorations, isEmpty);

      unawaited(store.addSunshine(100));
      async.elapse(const Duration(milliseconds: 20));
      vm.handleIntent(const BuyDecorationPressed('path'));
      async.elapse(Duration.zero);
      expect(getState(container).decorations, contains('path'));
    });
  });

  test('星屑兑换高级种子:满 100 解锁玫瑰并可在种子表选择', () {
    fakeAsync((async) {
      final fake = FakePoseStream();
      final store = GameEconomyStore();
      final container = boot(fake: fake, economy: store);
      addTearDown(container.dispose);
      final vm = getVm(container);
      async.elapse(Duration.zero);

      // 星屑不足
      vm.handleIntent(const ExchangeAdvancedSeedPressed());
      async.elapse(Duration.zero);
      expect(getState(container).unlockedAdvancedSeeds, isEmpty);
      expect(getState(container).shopHint, contains('星屑'));

      // 攒满 100
      unawaited(store.addStardust(100));
      async.elapse(const Duration(milliseconds: 20));
      vm.handleIntent(const ExchangeAdvancedSeedPressed());
      async.elapse(Duration.zero);

      expect(getState(container).unlockedAdvancedSeeds, contains('rose'));
      expect(getState(container).stardustTotal, 0);
      // 已解锁 → 可种
      vm.handleIntent(const SeedSelected(1, 'rose'));
      async.elapse(Duration.zero);
      expect(getState(container).plots[1]?.species, 'rose');
    });
  });

  test('相机启动失败 → error 态,文案可恢复重试', () {
    fakeAsync((async) {
      final fake = FakePoseStream()..startError = Exception('no camera');
      final container = boot(fake: fake);
      addTearDown(container.dispose);
      async.elapse(Duration.zero);

      getVm(container).handleIntent(const StartCatchDropPressed());
      async.elapse(const Duration());

      final state = getState(container);
      expect(state.phase, GamePhase.error);
      expect(state.statusText, isNotEmpty);
    });
  });
}
