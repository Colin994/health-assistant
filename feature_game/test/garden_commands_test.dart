import 'dart:async';
import 'package:core_database/core_database.dart';
import 'package:feature_game/feature_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_view_model_test.dart' show boot, FakePoseStream, getVm, getState;

class DelayedStore extends GameEconomyStore {
  Completer<void>? barrier;
  int calls = 0;
  bool fail = false;
  @override
  Future<int> investSunshine(int index, int amount) async {
    calls++;
    await barrier?.future;
    if (fail) throw StateError('simulated storage failure');
    return super.investSunshine(index, amount);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'same-plot double tap is ignored, pending and feedback track committed result',
    () async {
      final store = DelayedStore();
      await store.load();
      await store.addSunshine(120);
      await store.plantSeed(0, 'sunflower');
      final c = boot(fake: FakePoseStream(), economy: store);
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      store.barrier = Completer<void>();
      final first = getVm(c).handleIntent(const InvestPressed(0));
      final second = getVm(c).handleIntent(const InvestPressed(0));
      expect(getState(c).pendingPlotIndices, {0});
      await Future<void>.delayed(Duration.zero);
      expect(store.calls, 1);
      store.barrier!.complete();
      await Future.wait([first, second]);
      expect(getState(c).plots[0]!.invested, 30);
      expect(getState(c).todaySunshineTotal, 90);
      expect(getState(c).pendingPlotIndices, isEmpty);
      expect(getState(c).feedback!.success, isTrue);
    },
  );
  test(
    'save failure retains data, clears pending and exposes retryable feedback',
    () async {
      final store = DelayedStore();
      await store.load();
      await store.addSunshine(12);
      await store.plantSeed(0, 'sunflower');
      final c = boot(fake: FakePoseStream(), economy: store);
      addTearDown(c.dispose);
      await Future<void>.delayed(Duration.zero);
      store.fail = true;
      await getVm(c).handleIntent(const InvestPressed(0));
      expect(getState(c).plots[0]!.invested, 0);
      expect(getState(c).todaySunshineTotal, 12);
      expect(getState(c).pendingPlotIndices, isEmpty);
      expect(getState(c).feedback!.success, isFalse);
      store.fail = false;
      await getVm(c).handleIntent(const InvestPressed(0));
      expect(getState(c).plots[0]!.invested, 12);
      expect(getState(c).todaySunshineTotal, 0);
    },
  );
  test('different wallet commands serialize without losing funds', () async {
    final store = DelayedStore();
    await store.load();
    await store.addSunshine(40);
    await store.plantSeed(0, 'sunflower');
    await store.plantSeed(1, 'rose');
    // Rose is locked: use another free seed.
    await store.plantSeed(1, 'lavender');
    final c = boot(fake: FakePoseStream(), economy: store);
    addTearDown(c.dispose);
    await Future<void>.delayed(Duration.zero);
    await Future.wait([
      getVm(c).handleIntent(const InvestPressed(0)),
      getVm(c).handleIntent(const InvestPressed(1)),
    ]);
    expect(getState(c).plots[0]!.invested, 30);
    expect(getState(c).plots[1]!.invested, 10);
    expect(getState(c).todaySunshineTotal, 0);
  });
}
