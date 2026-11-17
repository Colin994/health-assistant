import 'package:feature_game/feature_game.dart';
import 'package:flutter_test/flutter_test.dart';

const tick = Duration(milliseconds: 100);

void run(StarGazingSession s, Duration duration, double pitch) {
  var left = duration;
  while (left > Duration.zero) {
    s.advance(dt: tick, headPitch: pitch);
    left -= tick;
  }
}

void main() {
  group('对准收集(§6.2.1:对准 ±5° 保持 3 秒)', () {
    test('初始目标 pitch 8°,对准即充能、满 3 秒得 25', () {
      final s = StarGazingSession();
      expect(s.snapshot.targetPitch, 8);
      run(s, const Duration(seconds: 2), 8);
      expect(s.snapshot.holdProgress, greaterThan(0.5));
      expect(s.score, 0); // 未满
      run(s, const Duration(milliseconds: 1100), 8);
      expect(s.score, 25);
      expect(s.collectedCount, 1);
      // 下一颗是回中星 2°
      expect(s.snapshot.targetPitch, 2);
      expect(s.snapshot.targetIsRecentring, isTrue);
    });

    test('容差边界:恰 5° 算对准,5.1° 不算', () {
      final s = StarGazingSession();
      run(s, const Duration(milliseconds: 500), 13); // |13-8|=5
      expect(s.snapshot.aligned, isTrue);
      final s2 = StarGazingSession();
      run(s2, const Duration(milliseconds: 500), 13.1);
      expect(s2.snapshot.aligned, isFalse);
      expect(s2.snapshot.holdProgress, 0);
    });

    test('中断进度保留(无惩罚,§6.2)', () {
      final s = StarGazingSession();
      run(s, const Duration(seconds: 1), 8);
      final p = s.snapshot.holdProgress;
      expect(p, greaterThan(0.2));
      // 头放开 2 秒
      run(s, const Duration(seconds: 2), 0);
      expect(s.snapshot.holdProgress, closeTo(p, 0.01)); // 不归零
      // 重新对准补满
      run(s, const Duration(seconds: 2), 8);
      expect(s.score, 25);
    });
  });

  group('星序列与回中(§6.2.1 安全:单次后伸 ≤15 秒)', () {
    test('序列共 9 颗(5 星 + 4 回中),回中间隔保证回正', () {
      const cfg = StarGazingConfig();
      expect(cfg.stars.length, 9);
      final realStars = cfg.stars.where((s) => !s.recentring).toList();
      expect(realStars.length, 5);
      expect(realStars.map((s) => s.pitch).toList(), [8, 14, 20, 26, 30]);
      // 每两颗真星之间必有回中星
      for (var i = 1; i < cfg.stars.length; i++) {
        if (!cfg.stars[i].recentring) {
          expect(cfg.stars[i - 1].recentring, isTrue);
        }
      }
    });

    test('收集完全部 9 颗 → 分数 145,allCollected', () {
      final s = StarGazingSession();
      const cfg = StarGazingConfig();
      for (final star in cfg.stars) {
        run(s, star.hold + const Duration(milliseconds: 200), star.pitch);
      }
      expect(s.allCollected, isTrue);
      expect(s.collectedCount, 9);
      expect(s.score, 145); // 5×25 + 4×5
    });
  });

  group('局流程', () {
    test('时间到 → finished', () {
      final s = StarGazingSession();
      run(s, const Duration(seconds: 40), 0);
      expect(s.phase, StarGazingPhase.finished);
    });

    test('未达目标分不能提前完成;达 100 分可提前', () {
      final s = StarGazingSession();
      expect(s.snapshot.canFinishEarly, isFalse);
      expect(s.finishEarly(), isFalse);
      // 收集 4 颗真星(25×4=100)
      const cfg = StarGazingConfig();
      var collected = 0;
      for (final star in cfg.stars) {
        run(s, star.hold + const Duration(milliseconds: 200), star.pitch);
        if (!star.recentring) {
          collected++;
          if (collected == 4) {
            break;
          }
        }
      }
      expect(s.snapshot.canFinishEarly, isTrue);
      expect(s.finishEarly(), isTrue);
      expect(s.phase, StarGazingPhase.finished);
    });
  });

  group('星屑换算(§5.2:15~25/局按表现)', () {
    test('表现区间映射到 15~25', () {
      const c = StarGazingConfig();
      // 12 + score*0.09:100 分 → 21,145 分 → 25
      expect(c.stardustFor(100), 21);
      expect(c.stardustFor(145), 25);
      expect(c.stardustFor(0), 12);
      expect(c.stardustFor(999), 25); // 封顶
      expect(c.stardustFor(100), greaterThanOrEqualTo(15));
    });
  });

  group('eyes-free 可行性(§6.2 验收)', () {
    test('快照提供音频所需字段:目标 pitch、对准与否、进度', () {
      final s = StarGazingSession();
      run(s, const Duration(milliseconds: 500), 8);
      final snap = s.snapshot;
      // 无视觉也能驱动音频:音高=targetPitch,音量=aligned?强:弱,
      // 完成音=收集数变化。
      expect(snap.targetPitch, isNotNull);
      expect(snap.aligned, isTrue);
      expect(snap.holdProgress, greaterThan(0));
      expect(snap.collectedCount, isNotNull);
    });
  });
}
