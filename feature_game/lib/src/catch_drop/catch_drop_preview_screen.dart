import 'dart:async';
import 'dart:math';

import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'catch_drop_board.dart';
import 'catch_drop_session.dart';

/// 接阳光 2.5D 预览(dev):合成循环 snapshot 驱动 [CatchDropBoard],
/// 纯呈现层风格预览,不接 Session/相机/玩法逻辑。
class CatchDropPreviewScreen extends StatefulWidget {
  const CatchDropPreviewScreen({super.key});

  @override
  State<CatchDropPreviewScreen> createState() =>
      _CatchDropPreviewScreenState();
}

class _CatchDropPreviewScreenState extends State<CatchDropPreviewScreen> {
  final _rnd = Random(7);
  final List<Drop> _drops = [];
  Timer? _tick;
  Timer? _spawner;
  var _elapsed = Duration.zero;
  var _score = 0;
  var _nextId = 0;
  // 金阳光引导演示:每 6s 切换在场与方向(左/右交替)。
  var _goldenPresent = false;
  var _goldenSide = 1;

  @override
  void initState() {
    super.initState();
    // 50ms 拍:推进时钟 + 篮子正弦摆动 + 移除落底掉落物(模拟接住计分)。
    _tick = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsed += const Duration(milliseconds: 50);
        final t = _elapsed.inMilliseconds / 900 * pi;
        _containerX = 0.5 + 0.33 * sin(t);
        _drops.removeWhere((d) {
          if (d.landedAt(_elapsed)) {
            _score += d.kind == DropKind.golden ? 25 : 5;
            return true;
          }
          return false;
        });
        final sec = _elapsed.inSeconds;
        _goldenPresent = sec % 12 >= 4 && sec % 12 < 10;
        _goldenSide = (sec ~/ 12).isEven ? 1 : -1;
      });
    });
    // 每 2.5s 落一个阳光(第 4 个起为金阳光,便于预览两种精灵)。
    _spawner = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      setState(() {
        _drops.add(Drop(
          id: _nextId++,
          kind: _nextId % 4 == 3 ? DropKind.golden : DropKind.normal,
          x: 0.2 + _rnd.nextDouble() * 0.6,
          spawnedAt: _elapsed,
          fallDuration: const Duration(milliseconds: 5200),
        ));
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _spawner?.cancel();
    super.dispose();
  }

  double _containerX = 0.5;

  @override
  Widget build(BuildContext context) {
    final snapshot = CatchDropSnapshot(
      phase: CatchDropPhase.playing,
      containerX: _containerX,
      elapsed: _elapsed,
      score: _score,
      caughtNormal: 0,
      caughtGolden: 0,
      activeDrops: List.unmodifiable(_drops),
      goldenChargeProgress: 0,
      goldenCharging: false,
      canFinishEarly: _score >= 40,
      goldenPresent: _goldenPresent,
      goldenSide: _goldenSide,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('接阳光 2.5D 预览')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/game/backdrop_catch.png'),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          Column(
        children: [
          // 复刻 _PlayArea 顶栏:倒计时 HUD 胶囊。
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 68, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '28s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CatchDropBoard(
              snapshot: snapshot,
              remainingSeconds: 28,
              totalSeconds: 40,
              events: const [],
              eventSeq: 0,
              tickMs: 50,
            ),
          ),
          // 复刻 _PlayArea 底栏:提前完成按钮固定槽位(出现时不挤压棋盘)。
          SizedBox(
            height: 64,
            child: Center(
              child: IgnorePointer(
                ignoring: !snapshot.canFinishEarly,
                child: AnimatedOpacity(
                  opacity: snapshot.canFinishEarly ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('提前完成'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentWarm,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
