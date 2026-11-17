import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'star_gazing_session.dart';

/// 看星星棋盘(§6.2.1,eyes-free 仰头):iso 夜空背景 + 星星 + 视口框。
///
/// 视觉只做余光提示(大色块/边框发光);主反馈走音频(VM 侧接入)。
/// 2.5D 化:背景用等距花园夜空位图(与花园/接阳光同一世界观),
/// 棋盘只叠加动态元素;顶部方向胶囊提示「抬头/低头/保持」。
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

  /// 目标星与视口仰角差超过该值即提示抬头/低头。
  static const double _hintThreshold = 0.12;

  @override
  Widget build(BuildContext context) {
    final targetT = (snapshot.targetPitch / _maxPitch).clamp(0.0, 1.0);
    final viewT = (headPitch / _maxPitch).clamp(0.0, 1.0);
    // 归一化后差 >0 → 目标在视口上方(需要抬头)。
    final delta = targetT - viewT;
    final String hint;
    final IconData hintIcon;
    if (snapshot.aligned) {
      final pct = (snapshot.holdProgress * 100).round();
      hint = pct > 0 ? '保持住… $pct%' : '保持住…';
      hintIcon = Icons.center_focus_strong_rounded;
    } else if (delta > _hintThreshold) {
      hint = '抬起头看星星';
      hintIcon = Icons.keyboard_arrow_up_rounded;
    } else if (delta < -_hintThreshold) {
      hint = '稍稍低头';
      hintIcon = Icons.keyboard_arrow_down_rounded;
    } else {
      hint = '对准中间';
      hintIcon = Icons.center_focus_weak_rounded;
    }

    final aligned = snapshot.aligned;
    return Semantics(
      label:
          '看星星:已收集 ${snapshot.collectedCount} 颗,'
          '${aligned ? "对准中" : "未对准"},$hint,'
          '剩余 $remainingSeconds 秒',
      liveRegion: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 2.5D 夜空背景(iso 花园世界,上 70% 天空留给星星)。
          Image.asset(
            'assets/game/star_backdrop.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            // 缺图时回退纯色夜空(不阻塞玩法)。
            errorBuilder: (_, _, _) => const ColoredBox(
              color: Color(0xFF16241F),
            ),
          ),
          CustomPaint(
            painter: _StarGazingPainter(
              snapshot: snapshot,
              headPitch: headPitch,
              remainingSeconds: remainingSeconds,
              totalSeconds: totalSeconds,
            ),
          ),
          // 顶部方向胶囊(与接阳光同一套 HUD 语言)。
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: aligned
                      ? AppColors.primary.withValues(alpha: 0.88)
                      : Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hintIcon,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

    // 背景由位图承担;此处只画动态元素。

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

    // 已收集数 + 分数:HUD 深色胶囊(与花园/接阳光统一)。
    final tp = TextPainter(
      text: TextSpan(
        text: '★ ${snapshot.collectedCount} · ${snapshot.score}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pillW = tp.width + 26;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - pillW - 16, 48, pillW, 34),
        const Radius.circular(17),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    tp.paint(
      canvas,
      Offset(w - pillW - 16 + 13, 48 + (34 - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(_StarGazingPainter old) =>
      old.snapshot != snapshot ||
      old.headPitch != headPitch ||
      old.remainingSeconds != remainingSeconds ||
      old.totalSeconds != totalSeconds;
}
