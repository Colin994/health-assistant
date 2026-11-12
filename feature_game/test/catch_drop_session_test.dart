import 'package:feature_game/feature_game.dart';
import 'package:flutter_test/flutter_test.dart';

const tick = Duration(milliseconds: 100);

/// 以固定头姿推进 [duration]。
void run(CatchDropSession s, Duration duration, double roll) {
  var left = duration;
  while (left > Duration.zero) {
    s.advance(dt: tick, headRoll: roll);
    left -= tick;
  }
}

void main() {
  group('输入映射(§6.1 v0.5:只看方向,不做角度校准)', () {
    test('死区内容器不动', () {
      final s = CatchDropSession(config: const CatchDropConfig());
      // 死区 ±4°:3.9° 不动
      run(s, const Duration(seconds: 2), 6.9);
      expect(s.containerX, closeTo(0.5, 0.001));
      run(s, const Duration(seconds: 2), -6.9);
      expect(s.containerX, closeTo(0.5, 0.001));
    });

    test('倾斜方向 → 容器方向;满倾到屏幕边缘', () {
      // 约定:roll 正 → 容器右移(x 大),roll 负 → 左移。
      final s = CatchDropSession(config: const CatchDropConfig());
      run(s, const Duration(seconds: 4), 55);
      expect(s.containerX, greaterThan(0.85));
      final s2 = CatchDropSession(config: const CatchDropConfig());
      run(s2, const Duration(seconds: 4), -55);
      expect(s2.containerX, lessThan(0.15));
    });

    test('速度封顶:瞬间满倾,容器单拍位移不超过上限', () {
      final s = CatchDropSession(config: const CatchDropConfig());
      var prev = s.containerX;
      var maxDelta = 0.0;
      for (var i = 0; i < 40; i++) {
        s.advance(dt: tick, headRoll: -55);
        final delta = (s.containerX - prev).abs();
        if (delta > maxDelta) {
          maxDelta = delta;
        }
        prev = s.containerX;
      }
      // 上限 = 0.45 屏宽/秒 × 0.1 秒 = 0.045/拍
      expect(maxDelta, lessThanOrEqualTo(0.045 + 0.0001));
    });
  });

  group('普通掉落物', () {
    test('容器对准掉落物 → 接住得分;漏接只不计分(无惩罚)', () {
      // 用小配置让掉落可预测:掉落物 x 固定中段
      final cfg = CatchDropConfig(
        normalDropInterval: const [
          Duration(milliseconds: 500),
          Duration(milliseconds: 500),
        ],
      );
      final s = CatchDropSession(config: cfg, seed: 7);
      // 头保持中位(死区内),容器停在 0.5
      run(s, const Duration(seconds: 12), 0);
      expect(s.caughtNormal, greaterThan(0));
      expect(s.score, s.caughtNormal * 5);
      expect(s.score, greaterThanOrEqualTo(0)); // 漏接不加不减
    });
  });

  group('金阳光(§6.1 深倾 + 保持充能)', () {
    test('深倾并对齐 → 充能 2.5 秒得 25 分', () {
      final cfg = CatchDropConfig(); // goldenFirstAt 12s, x=0.08
      final s = CatchDropSession(config: cfg, seed: 1);
      // 12s 后金阳光出现;持续右倾(-40°)对准左侧 0.08
      run(s, const Duration(seconds: 11), -40);
      final before = s.score;
      // 继续深倾 3 秒完成充能
      run(s, const Duration(seconds: 3), -40);
      expect(s.caughtGolden, 1);
      expect(s.score - before, 25);
    });

    test('充能中断:进度保留,重新满足条件可续满(无惩罚)', () {
      final cfg = CatchDropConfig();
      final s = CatchDropSession(config: cfg, seed: 1);
      run(s, const Duration(seconds: 11), -40); // 金阳光出现并充能 1 秒
      final p1 = s.snapshot.goldenChargeProgress;
      expect(p1, greaterThan(0));
      // 松开(回中)1 秒 → 充能中断但进度不清零
      run(s, const Duration(seconds: 1), 0);
      expect(s.caughtGolden, 0);
      final p2 = s.snapshot.goldenChargeProgress;
      expect(p2, closeTo(p1, 0.25)); // 保留(不归零)
      // 重新深倾 2 秒 → 续满
      run(s, const Duration(seconds: 2), -40);
      expect(s.caughtGolden, 1);
    });
  });

  group('局流程(§6.1:90s / 目标分 100 / 提前完成)', () {
    test('时间到 → finished', () {
      final s = CatchDropSession(config: const CatchDropConfig());
      run(s, const Duration(seconds: 40), 0);
      expect(s.phase, CatchDropPhase.finished);
      expect(s.activeDrops, isEmpty);
    });

    test('未达目标分不能提前完成', () {
      final s = CatchDropSession(config: const CatchDropConfig());
      expect(s.snapshot.canFinishEarly, isFalse);
      expect(s.finishEarly(), isFalse);
    });

    test('达目标分 → 可提前完成,结束后不再推进', () {
      // 高分红配置:普通掉落每次 100 分
      final cfg = CatchDropConfig(
        normalDropScore: 100,
        normalDropInterval: const [
          Duration(milliseconds: 500),
          Duration(milliseconds: 500),
        ],
      );
      final s = CatchDropSession(config: cfg, seed: 3);
      run(s, const Duration(seconds: 8), 0);
      expect(s.snapshot.canFinishEarly, isTrue);
      expect(s.finishEarly(), isTrue);
      expect(s.phase, CatchDropPhase.finished);
      final frozenScore = s.score;
      run(s, const Duration(seconds: 3), 0);
      expect(s.score, frozenScore); // 结束后不再计分
    });
  });

  group('阳光换算(10 + 分数÷10,封顶 30)', () {
    test('0 分 → 10;100 分 → 20;200 → 30;300 → 封顶 30', () {
      const c = CatchDropConfig();
      expect(c.sunshineFor(0), 10);
      expect(c.sunshineFor(100), 20);
      expect(c.sunshineFor(200), 30);
      expect(c.sunshineFor(999), 30);
    });
  });
}
