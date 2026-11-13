import 'package:core_database/core_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  GameEconomyStore fresh() => GameEconomyStore();

  test('空库载入为空态(四块空地)', () async {
    final s = await fresh().load();
    expect(s.sunshineTotal, 0);
    expect(s.plots, hasLength(4));
    expect(s.plots.every((p) => p == null), isTrue);
    expect(s.decorations, isEmpty);
    expect(s.harvestedCount, 0);
    expect(s.starGazeUnlocked, isFalse);
  });

  test('旧版 JSON(无地块字段)兼容载入,经济数据不丢', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'l4_game_economy': '{"sunshineTotal":120,"quotaDay":"2026-11-12",'
          '"quotaUsed":1,"seeds":{"sunflower":2}}',
    });
    final s = await fresh().load();
    expect(s.sunshineTotal, 120);
    expect(s.quotaUsed, 1);
    expect(s.plots, hasLength(4)); // 缺省补齐空地
  });

  test('阳光入账累计、封顶 999、持久化', () async {
    final store = fresh();
    await store.load();
    await store.addSunshine(30);
    await store.addSunshine(5000);
    expect(store.state.sunshineTotal, 999);
    expect((await fresh().load()).sunshineTotal, 999);
  });

  test('每日额度:3 局后拒绝,跨日重置', () async {
    final store = fresh();
    await store.load();
    final day1 = DateTime(2026, 11, 12, 10);
    expect(await store.tryUseDailyQuota(day1), isTrue);
    expect(await store.tryUseDailyQuota(day1), isTrue);
    expect(await store.tryUseDailyQuota(day1), isTrue);
    expect(await store.tryUseDailyQuota(day1), isFalse);
    expect(store.quotaRemaining(DateTime(2026, 11, 13, 8)), 3);
    expect(await store.tryUseDailyQuota(DateTime(2026, 11, 13, 8)), isTrue);
  });

  group('地块(花园 MVP)', () {
    test('种花:空地+基础种可种;占用/越界/高级种拒绝', () async {
      final store = fresh();
      await store.load();
      expect(await store.plantSeed(0, 'sunflower'), isTrue);
      expect(await store.plantSeed(0, 'rose'), isFalse); // 占用
      expect(await store.plantSeed(1, 'rose'), isFalse); // 高级种
      expect(await store.plantSeed(9, 'sunflower'), isFalse); // 越界
      expect(store.state.plots[0]!.species, 'sunflower');
      expect(store.isStarGazeUnlocked, isFalse);
    });

    test('投入:受余额与全程线双重限制,阶段推进正确', () async {
      final store = fresh();
      await store.load();
      await store.addSunshine(500);
      await store.plantSeed(0, 'lavender');

      expect(await store.investSunshine(0, 30), 30);
      expect(store.state.plots[0]!.invested, 30);
      expect(store.state.sunshineTotal, 470);
      expect(store.state.plots[0]!.stage, 0);

      expect(await store.investSunshine(0, 60), 60); // 跨越 75 → stage1
      expect(store.state.plots[0]!.stage, 1);
      expect(store.state.plots[0]!.bloomed, isFalse);

      // 全程线封顶:多投只吃到 450
      expect(await store.investSunshine(0, 9999), 360); // 90+360=450
      expect(store.state.plots[0]!.invested, 450);
      expect(store.state.plots[0]!.harvestable, isTrue);
      expect(store.state.plots[0]!.bloomed, isTrue);
      expect(store.isStarGazeUnlocked, isTrue); // 盛开解锁看星星
      // 已到全程线:再投 0
      expect(await store.investSunshine(0, 30), 0);
    });

    test('无余额时投入为 0(不产生负阳光)', () async {
      // 独立 mock 环境,避免与其他 store 实例共享数据。
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = fresh();
      await store.load();
      await store.plantSeed(1, 'cyperus');
      expect(await store.investSunshine(1, 30), 0);
      expect(store.state.plots[1]!.invested, 0);
      expect(store.state.sunshineTotal, 0);
    });

    test('收获:押花册+1、地块清空、持久化;未达标拒绝', () async {
      final store = fresh();
      await store.load();
      await store.addSunshine(450);
      await store.plantSeed(2, 'hydrocotyle');
      expect(await store.harvest(2), isNull); // 未到 450
      await store.investSunshine(2, 450);
      expect(await store.harvest(2), 'hydrocotyle');
      expect(store.state.plots[2], isNull);
      expect(store.state.harvestedCount, 1);
      expect((await fresh().load()).harvestedCount, 1);
    });
  });

  group('装饰(直购)', () {
    test('阳光够:买入、去重、扣款、持久化', () async {
      final store = fresh();
      await store.load();
      await store.addSunshine(100);
      expect(await store.buyDecoration('path'), isTrue); // 30
      expect(await store.buyDecoration('path'), isFalse); // 重复
      expect(await store.buyDecoration('pavilion'), isFalse); // 80 > 余 70
      expect(await store.buyDecoration('fence'), isTrue); // 40 → 余 30
      expect(store.state.decorations, ['path', 'fence']);
      expect(store.state.sunshineTotal, 30);
      expect((await fresh().load()).decorations, ['path', 'fence']);
    });
  });

  test('损坏数据回到空态,不崩溃', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'l4_game_economy': '{broken json',
    });
    final s = await fresh().load();
    expect(s.sunshineTotal, 0);
  });
}
