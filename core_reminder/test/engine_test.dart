import 'dart:async';

import 'package:core_model/core_model.dart';
import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

/// 引擎单测（技术设计文档 §9.7）：用例映射 PRD FR-4 / FR-6 验收——
/// 阈值三档 / 冷却 90 分 / 跨零点静音暂停 / 午休静音 / 活动重置 /
/// 稍后每日 1 次 / 今天别提醒 / 别再提醒这类 / 降频放宽 / 变更次轮生效 /
/// 被杀期重算与补记账 / 静音投影与活跃积分。
void main() {
  late FakeClock clock;
  late FakeConfigRepo repo;
  late MemStores mem;

  ReminderEngine mk({ReminderConfig config = const ReminderConfig()}) {
    clock = FakeClock(DateTime(2026, 11, 2, 9, 0)); // 周一 09:00
    repo = FakeConfigRepo(config);
    mem = MemStores();
    return ReminderEngine(
      clock,
      repo,
      FakeTags(),
      mem,
      ReminderCopyProvider(),
    )..tickPeriodOverride = Duration.zero;
  }

  /// 前进并逐段 tick（段长任取：引擎按活跃积分精确扣减）。
  Future<void> run(ReminderEngine e, Duration total,
      {Duration step = const Duration(minutes: 5)}) async {
    var left = total;
    while (left > Duration.zero) {
      final d = left < step ? left : step;
      clock.advance(d);
      e.debugTick();
      left -= d;
    }
    // fires/states 为广播流（异步投递）：断言前 flush 微任务。
    await Future<void>.delayed(Duration.zero);
  }

  test('久坐 55 分到点触发；触发后按新阈值重置并进入冷却', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 55));
    int sedCount() => fires.where((k) => k == ReminderKind.sedentary).length;
    expect(sedCount(), 1);
    expect(
      mem.fires.where((f) => f.kind == ReminderKind.sedentary).length,
      1,
      reason: '触发落 reminder_log',
    );

    // 再走 55 分：冷却（90 分）未到，不触发；冷却期满再触发。
    await run(e, const Duration(minutes: 55));
    expect(sedCount(), 1, reason: '冷却期内不得触发');
    expect(
      e.state.kinds[ReminderKind.sedentary]!.phase,
      ReminderPhase.cooldown,
    );
    await run(e, const Duration(minutes: 40));
    expect(sedCount(), 2, reason: '冷却期满应触发');
  });

  test('静音=暂停：跨零点夜间静音冻结、恢复后继续，且不三连发', () async {
    clock = FakeClock(DateTime(2026, 11, 2, 21, 30));
    repo = FakeConfigRepo();
    mem = MemStores();
    final e = ReminderEngine(
      clock, repo, FakeTags(), mem, ReminderCopyProvider(),
    )..tickPeriodOverride = Duration.zero;
    final firedAt = <(ReminderKind, DateTime)>[];
    e.fires.listen((f) => firedAt.add((f.kind, f.at)));
    await e.start();

    await run(e, const Duration(minutes: 30)); // 22:00 整（静音起点，不含）
    // eye（20 分阈值）在 21:50 静音开始前的合法触发不算破坏静音；
    // 久坐/喝水（55/45 分）应被静音冻结。
    expect(firedAt.where((f) => f.$1 != ReminderKind.eye), isEmpty);
    await run(e, const Duration(hours: 8)); // 06:00 仍在静音
    expect(
      firedAt.where((f) => f.$1 != ReminderKind.eye),
      isEmpty,
      reason: '静音期零触发（eye 21:50 的触发在静音前，已剔除）',
    );
    expect(
      e.state.kinds[ReminderKind.sedentary]!.phase,
      ReminderPhase.pausedMute,
    );

    // 07:00 恢复：久坐还剩 25 分（21:30→22:00 计了 30 分）→ 07:25 触发；
    // 喝水剩 15 分（45-30）→ 07:15 触发。两者错开，无三连发。
    // 06:00 → 07:15 = 静音尾 60 分 + 剩余 15 分。
    await run(e, const Duration(minutes: 75));
    expect(firedAt.map((f) => f.$1), contains(ReminderKind.water));
    expect(firedAt.where((f) => f.$1 == ReminderKind.sedentary), isEmpty);
    await run(e, const Duration(minutes: 10));
    expect(
      firedAt.where((f) => f.$1 == ReminderKind.sedentary).length,
      1,
      reason: '恢复后按剩余时长触发',
    );
  });

  test('午休静音冻结（12:30–13:30）', () async {
    clock = FakeClock(DateTime(2026, 11, 2, 12, 0));
    repo = FakeConfigRepo();
    mem = MemStores();
    final e = ReminderEngine(
      clock, repo, FakeTags(), mem, ReminderCopyProvider(),
    )..tickPeriodOverride = Duration.zero;
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 45)); // 12:45，喝水 45 分被静音冻结在剩 30。
    expect(fires.where((k) => k != ReminderKind.eye), isEmpty);
    await run(e, const Duration(minutes: 45)); // 13:30
    expect(fires.where((k) => k != ReminderKind.eye), isEmpty);
    await run(e, const Duration(minutes: 30)); // 14:00：恢复后剩余 30 分走完 → 触发。
    expect(fires, contains(ReminderKind.water));
  });

  test('活动打断重置久坐；喝水不受影响', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 30));
    await e.onActivityBurst();
    expect(
      e.state.kinds[ReminderKind.sedentary]!.remaining,
      const Duration(minutes: 55),
    );
    await run(e, const Duration(minutes: 15)); // 09:45：喝水到点（护眼 09:20 已响）。
    expect(fires, contains(ReminderKind.water));
    expect(fires.where((k) => k == ReminderKind.sedentary), isEmpty,
        reason: '重置后久坐不应在 09:45 前触发');
    await run(e, const Duration(minutes: 55)); // 10:40：重置后的久坐到点。
    expect(fires, contains(ReminderKind.sedentary));
  });

  test('稍后：+1h 重新触发，每类每日最多 1 次', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 55));
    int sedCount() => fires.where((k) => k == ReminderKind.sedentary).length;
    expect(sedCount(), 1);

    final ok = await e.applyFeedback(
      FeedbackAction.snooze,
      ReminderKind.sedentary,
    );
    expect(ok, isTrue);
    expect(
      e.state.kinds[ReminderKind.sedentary]!.phase,
      ReminderPhase.snoozed,
    );

    await run(e, const Duration(hours: 1)); // 10:55 稍后到点 → 重新触发。
    expect(sedCount(), 2);

    final again = await e.applyFeedback(
      FeedbackAction.snooze,
      ReminderKind.sedentary,
    );
    expect(again, isFalse, reason: 'FR-6：本日最多稍后 1 次');
  });

  test('今天别提醒：当日零触发，次日恢复', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 20));
    expect(
      await e.applyFeedback(
        FeedbackAction.stopToday,
        ReminderKind.sedentary,
      ),
      isTrue,
    );
    expect(
      e.state.kinds[ReminderKind.sedentary]!.phase,
      ReminderPhase.mutedToday,
    );
    await run(e, const Duration(hours: 6));
    expect(fires.where((k) => k == ReminderKind.sedentary), isEmpty,
        reason: '当日久坐零触发');

    // 次日：跨日重置，剩余（35 分）继续走完 → 恢复触发。
    await run(e, const Duration(hours: 18, minutes: 35));
    expect(fires.where((k) => k == ReminderKind.sedentary).length,
      greaterThanOrEqualTo(1),
      reason: '次日恢复触发（后续循环继续属正常）');
  });

  test('别再提醒这类：持久禁用并写入配置', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    expect(
      await e.applyFeedback(
        FeedbackAction.neverAgain,
        ReminderKind.sedentary,
      ),
      isTrue,
    );
    expect(
      repo.config.disabledKinds,
      contains(ReminderKind.sedentary),
      reason: '禁用状态经配置持久化（重选档位恢复）',
    );
    expect(
      e.state.kinds[ReminderKind.sedentary]!.phase,
      ReminderPhase.disabled,
    );
    await run(e, const Duration(hours: 4));
    expect(fires.where((k) => k == ReminderKind.sedentary), isEmpty);
  });

  test('档位变更次轮生效：进行中的倒计时不受影响', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 10));
    repo.config = const ReminderConfig(sedentaryMinutes: 75);
    await e.onSettingsChanged();

    int sedCount() => fires.where((k) => k == ReminderKind.sedentary).length;
    await run(e, const Duration(minutes: 45)); // 累计 55 分：按旧阈值触发。
    expect(sedCount(), 1, reason: '本轮仍按 55 分');

    // 新一轮按 75 分走完后仍处冷却尾段（09:55+90=11:25），再走 15 分触发。
    await run(e, const Duration(minutes: 90));
    expect(sedCount(), 2);
  });

  test('自动降频：近 7 天负面 >50% 且样本 ≥4 → 阈值+15、冷却+30', () async {
    final e = mk();
    await e.start();
    for (var i = 0; i < 3; i++) {
      mem.addRaw(ReminderKind.sedentary, FeedbackAction.stopToday,
          clock.now().subtract(Duration(hours: i * 5)));
    }
    mem.addRaw(ReminderKind.water, FeedbackAction.done,
        clock.now().subtract(const Duration(hours: 1)));
    // 触发一次重算（设置变更为入口）。
    await e.onSettingsChanged();
    expect(e.deEscalated, isTrue);
    expect(
      e.rule.thresholds[ReminderKind.sedentary],
      const Duration(minutes: 70),
    );
    expect(e.rule.sedentaryCooldown, const Duration(minutes: 120));
  });

  test('被杀期重算：剩余按活跃时长扣减；跨过触发点补记账一次', () async {
    final t0 = DateTime(2026, 11, 2, 9, 0);
    // 场景 A：30 分钟前保存、剩 55 分 → 现在应剩 25 分。
    mem = MemStores();
    mem.saveState(RuleState(
      kind: ReminderKind.sedentary,
      remainingMs: const Duration(minutes: 55).inMilliseconds,
      savedAt: t0,
      dayKey: '2026-11-02',
    ));
    clock = FakeClock(t0.add(const Duration(minutes: 30)));
    repo = FakeConfigRepo();
    var e = ReminderEngine(
      clock, repo, FakeTags(), mem, ReminderCopyProvider(),
    )..tickPeriodOverride = Duration.zero;
    await e.start();
    expect(
      e.state.kinds[ReminderKind.sedentary]!.remaining,
      const Duration(minutes: 25),
    );

    // 场景 B：保存后 2 小时才回来（跨过触发点）→ 按已送达补记账 + 新一轮。
    mem = MemStores();
    mem.saveState(RuleState(
      kind: ReminderKind.sedentary,
      remainingMs: const Duration(minutes: 10).inMilliseconds,
      savedAt: t0,
      dayKey: '2026-11-02',
    ));
    clock = FakeClock(t0.add(const Duration(hours: 2)));
    repo = FakeConfigRepo();
    final e2 = ReminderEngine(
      clock, repo, FakeTags(), mem, ReminderCopyProvider(),
    )..tickPeriodOverride = Duration.zero;
    await e2.start();
    expect(mem.fires.length, 1, reason: '跨过触发点按已送达补记账');
    expect(
      e2.state.kinds[ReminderKind.sedentary]!.remaining,
      const Duration(minutes: 55),
      reason: '补记账后按阈值开新一轮',
    );
  });

  test('projectNextFireAt：静音窗按暂停语义跳过', () {
    final rule = ReminderRule(
      thresholds: const {},
      sedentaryCooldown: const Duration(minutes: 90),
      nightMute: const MuteWindow.clock(22, 0, 7, 0),
    );
    // 21:50 剩 30 分：22:00 起冻结 → 07:00 恢复走 30 分 → 07:20。
    final at = ReminderEngine.projectNextFireAt(
      DateTime(2026, 11, 2, 21, 50),
      const Duration(minutes: 30),
      rule,
    );
    expect(at, DateTime(2026, 11, 3, 7, 20));
  });

  test('activeBetween：静音时长从区间中剔除', () {
    final rule = ReminderRule(
      thresholds: const {},
      sedentaryCooldown: const Duration(minutes: 90),
      nightMute: const MuteWindow.clock(22, 0, 7, 0),
    );
    expect(
      ReminderEngine.activeBetween(
        DateTime(2026, 11, 2, 21, 0),
        DateTime(2026, 11, 2, 23, 0),
        rule,
      ),
      const Duration(hours: 1),
    );
    expect(
      ReminderEngine.activeBetween(
        DateTime(2026, 11, 2, 6, 0),
        DateTime(2026, 11, 2, 8, 0),
        rule,
      ),
      const Duration(hours: 1),
    );
    expect(
      ReminderEngine.activeBetween(
        DateTime(2026, 11, 2, 9, 0),
        DateTime(2026, 11, 3, 9, 0),
        rule,
      ),
      const Duration(hours: 15),
      reason: '全天含 9h 夜间静音（22:00–07:00）→ 活跃 15h',
    );
  });

  test('喝水/护眼开关关闭：off 相位、零触发', () async {
    final e = mk(config: const ReminderConfig(eyeEnabled: false));
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    expect(e.state.kinds[ReminderKind.eye]!.phase, ReminderPhase.off);
    await run(e, const Duration(hours: 3));
    expect(fires.where((k) => k == ReminderKind.eye), isEmpty);
    expect(fires, containsAll(<ReminderKind>[ReminderKind.sedentary]));
  });

  test('时钟回拨（NTP 校时）：倒计时冻结不误触发，追上后继续', () async {
    final e = mk();
    final fires = <ReminderKind>[];
    e.fires.listen((f) => fires.add(f.kind));
    await e.start();
    await run(e, const Duration(minutes: 30)); // 久坐剩 25 分。
    // 时钟回拨 40 分钟：期间 tick 空转（不回补、不误触发）。
    clock.advance(const Duration(minutes: -40));
    for (var i = 0; i < 5; i++) {
      e.debugTick();
    }
    expect(
      e.state.kinds[ReminderKind.sedentary]!.remaining,
      const Duration(minutes: 25),
      reason: '回拨期间倒计时冻结',
    );
    expect(fires.where((k) => k == ReminderKind.sedentary), isEmpty);
    // 时钟追上并越过触发点：恢复触发。
    await run(e, const Duration(minutes: 25));
    expect(fires, contains(ReminderKind.sedentary));
  });

  test('文案按健康标签子集匹配（颈椎不适 → 收下巴）', () {
    final copy = ReminderCopyProvider().copyFor(
      ReminderKind.sedentary,
      const {'颈椎不适'},
    );
    expect(copy.title, '久坐拉伸');
    expect(copy.body, contains('收下巴'));
  });
}

// ----------------------------------------------------------------------

class FakeClock extends ReminderClock {
  FakeClock(this._now);

  DateTime _now;

  void advance(Duration d) => _now = _now.add(d); // 支持负值（时钟回拨）。

  @override
  DateTime now() => _now;
}

class FakeConfigRepo implements ReminderConfigRepository {
  FakeConfigRepo([this.config = const ReminderConfig()]);

  ReminderConfig config;

  @override
  Future<ReminderConfig> load() async => config;

  @override
  Future<void> save(ReminderConfig c) async => config = c;
}

class FakeTags implements HealthTagStore {
  @override
  Future<Set<String>> load() async => const {};

  @override
  Future<void> save(Set<String> tags) async {}
}

/// 内存三仓合一（日志/反馈/状态）。
class MemStores implements ReminderPersistence {
  final fires = <({ReminderKind kind, DateTime firedAt})>[];
  final feedbacks =
      <({ReminderKind kind, FeedbackAction action, DateTime at})>[];
  final _states = <ReminderKind, RuleState>{};
  final _counts = StreamController<({int fired, int done})>.broadcast();

  void saveState(RuleState s) => _states[s.kind] = s;

  @override
  Future<void> appendFire({
    required ReminderKind kind,
    required DateTime firedAt,
    String adviceId = '',
    String copyText = '',
  }) async {
    fires.add((kind: kind, firedAt: firedAt));
    _counts.add((fired: fires.length, done: 0));
  }

  @override
  Stream<({int fired, int done})> watchDayCounts(DateTime day) => _counts.stream;

  @override
  Future<void> add({
    required ReminderKind kind,
    required FeedbackAction action,
    required DateTime at,
    String? adviceId,
  }) async {
    feedbacks.add((kind: kind, action: action, at: at));
  }

  void addRaw(ReminderKind kind, FeedbackAction action, DateTime at) =>
      feedbacks.add((kind: kind, action: action, at: at));

  @override
  Future<({int total, int negative})> stats7d(DateTime now) async {
    final from = now.subtract(const Duration(days: 7));
    final recent = feedbacks.where((f) => f.at.isAfter(from)).toList();
    return (
      total: recent.length,
      negative: recent.where((f) => f.action != FeedbackAction.done).length,
    );
  }

  @override
  Future<Map<ReminderKind, RuleState>> loadAll() async => Map.of(_states);

  @override
  Future<void> save(RuleState state) async => _states[state.kind] = state;

  @override
  Future<void> clear() async {
    fires.clear();
    feedbacks.clear();
    _states.clear();
  }
}

extension _ClockBack on Object {}
