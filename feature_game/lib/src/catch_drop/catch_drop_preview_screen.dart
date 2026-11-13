import 'dart:async';
import 'dart:math';

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
      canFinishEarly: false,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('接阳光 2.5D 预览')),
      body: Column(
        children: [
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
