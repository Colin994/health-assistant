import 'dart:async';

import 'package:flutter/material.dart';

import 'star_gazing_board.dart';
import 'star_gazing_session.dart';

/// 看星星 2.5D 预览(dev):合成 snapshot + 自动摆动 headPitch,
/// 展示夜空背景/目标星/视口框/方向胶囊;不接 Session 与相机。
class StarGazingPreviewScreen extends StatefulWidget {
  const StarGazingPreviewScreen({super.key});

  @override
  State<StarGazingPreviewScreen> createState() =>
      _StarGazingPreviewScreenState();
}

class _StarGazingPreviewScreenState extends State<StarGazingPreviewScreen> {
  Timer? _tick;
  var _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsed += const Duration(milliseconds: 100));
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _elapsed.inMilliseconds / 1000;
    // 头部仰角:0→32° 三角波摆动,演示「抬头/低头/保持」三种提示。
    final phase = (t % 12) / 12;
    final headPitch = phase < 0.5 ? phase * 2 * 32 : (1 - phase) * 2 * 32;
    const targetPitch = 20.0;
    final delta = (headPitch - targetPitch).abs();
    final aligned = delta <= 4;
    final snapshot = StarGazingSnapshot(
      phase: StarGazingPhase.playing,
      elapsed: _elapsed,
      score: 55,
      currentIndex: 2,
      targetPitch: targetPitch,
      targetIsRecentring: false,
      holdProgress: aligned ? ((t % 3) / 3).clamp(0.0, 1.0) : 0,
      aligned: aligned,
      collectedCount: 3,
      canFinishEarly: false,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('看星星 2.5D 预览')),
      body: StarGazingBoard(
        snapshot: snapshot,
        headPitch: headPitch,
        remainingSeconds: 28,
        totalSeconds: 40,
      ),
    );
  }
}
