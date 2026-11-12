import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'star_gazing_session.dart';

/// 看星星棋盘(§6.2.1,eyes-free 仰头):夜空 + 星星 + 视口框。
///
/// 视觉只做余光提示(大色块/边框发光);主反馈走音频(VM 侧接入)。
class StarGazingBoard extends StatelessWidget {
  const StarGazingBoard({
    required this.snapshot,
    required this.headPitch,
    required this.remainingSeconds,
    required this.totalSeconds,
    super.key,
  });

  final StarGazingSnapshot snapshot;

  /// 当前头部仰角(度,决定视口位置)。
  final double headPitch;

  final int remainingSeconds;

  /// 本局总时长(倒计时条归一化用)。
  final int totalSeconds;

  static const double _maxPitch = 35;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '看星星:已收集 ${snapshot.collectedCount} 颗,'
          '${snapshot.aligned ? "对准中" : "未对准"},'
          '剩余 $remainingSeconds 秒',
      liveRegion: true,
      child: CustomPaint(
        painter: _StarGazingPainter(
          snapshot: snapshot,
          headPitch: headPitch,
          remainingSeconds: remainingSeconds,
          totalSeconds: totalSeconds,
        ),
        size: const Size(double.infinity, 420),
      ),
    );
  }
}

class _StarGazingPainter extends CustomPainter {
  _StarGazingPainter({
    required this.snapshot,
    required this.headPitch,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  final StarGazingSnapshot snapshot;
  final double headPitch;
  final int remainingSeconds;
  final int totalSeconds;

  double _yOf(double pitch, double h) {
    // pitch 0° = 近底部(地平线),35° = 顶部。
    final t = (pitch / StarGazingBoard._maxPitch).clamp(0.0, 1.0);
    return h - 60 - t * (h - 120);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 夜空底(深墨绿,品牌深色)。
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF16241F),
    );

    // 顶部倒计时条。
    final urgency = remainingSeconds <= 10;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        w * (remainingSeconds / totalSeconds).clamp(0.0, 1.0),
        6,
      ),
      Paint()
        ..color = urgency
            ? AppColors.danger
            : AppColors.accentWarm.withValues(alpha: 0.8),
    );

    // 装饰星点(固定位置,营造夜空)。
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.25);
    const seeds = [
      [0.12, 0.18],
      [0.85, 0.12],
      [0.25, 0.72],
      [0.72, 0.66],
      [0.5, 0.3],
      [0.08, 0.5],
      [0.92, 0.42],
      [0.62, 0.85],
    ];
    for (final s in seeds) {
      canvas.drawCircle(Offset(s[0] * w, s[1] * h), 2, dot);
    }

    // 目标星(大而亮;回中星较小偏下)。
    final targetY = _yOf(snapshot.targetPitch, h);
    final isRecentring = snapshot.targetIsRecentring;
    final starColor = isRecentring ? AppColors.primary : AppColors.accentWarm;
    final radius = isRecentring ? 10.0 : 20.0;
    canvas.drawCircle(
      Offset(w / 2, targetY),
      radius * 2.2,
      Paint()..color = starColor.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      Offset(w / 2, targetY),
      radius,
      Paint()..color = starColor,
    );

    // 收集进度环(围绕目标星)。
    if (snapshot.holdProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, targetY), radius: radius * 2.8),
        -1.5708,
        6.2832 * snapshot.holdProgress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = AppColors.primary,
      );
    }

    // 视口框(当前头部仰角位置):对准时发光加粗。
    final viewY = _yOf(headPitch.clamp(0, StarGazingBoard._maxPitch), h);
    final focused = snapshot.aligned;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, viewY),
        width: w * 0.55,
        height: 96,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = focused ? 4 : 2
        ..color = focused
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.45),
    );

    // 已收集数 + 分数(右上)。
    final tp = TextPainter(
      text: TextSpan(
        text: '★ ${snapshot.collectedCount} · ${snapshot.score}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w - tp.width - 20, 20));
  }

  @override
  bool shouldRepaint(_StarGazingPainter old) =>
      old.snapshot != snapshot ||
      old.headPitch != headPitch ||
      old.remainingSeconds != remainingSeconds ||
      old.totalSeconds != totalSeconds;
}
