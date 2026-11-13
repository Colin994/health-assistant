import 'dart:math' as math;

import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'catch_drop_session.dart';

/// 接阳光棋盘(§6.1 v0.5,游戏化表现层)。
///
/// 组合:位图背景(iso 花园天空)+CustomPaint(倒计时/光晕/粒子/飘字/HUD 分数)
/// + 图像精灵(阳光/金阳光用 ComfyUI 生成的卡通图)
/// + 篮子容器(接住时弹性缩放)。
class CatchDropBoard extends StatefulWidget {
  const CatchDropBoard({
    required this.snapshot,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.events = const [],
    this.eventSeq = 0,
    this.tickMs = 50,
    super.key,
  });

  final CatchDropSnapshot snapshot;
  final int remainingSeconds;

  /// 本局总时长(倒计时条归一化用)。
  final int totalSeconds;

  /// VM 传入的打点事件(与 [eventSeq] 配合去重消费)。
  final List<CatchEvent> events;

  /// 事件序号:变化即视为新事件批次。
  final int eventSeq;

  /// 逻辑 tick 周期(毫秒):位置插值窗口,与 VM config 对齐。
  final int tickMs;

  /// 普通阳光精灵尺寸(逻辑像素)。
  static const double normalDropSize = 46;

  /// 金阳光精灵尺寸。
  static const double goldenDropSize = 76;

  /// 篮子尺寸(宽)。
  static const double basketWidth = 92;

  @override
  State<CatchDropBoard> createState() => _CatchDropBoardState();
}

class _CatchDropBoardState extends State<CatchDropBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_FloatingScore> _floats = [];
  final List<_Particle> _particles = [];
  Duration _now = Duration.zero;
  int _lastSeq = -1;

  /// 接住弹跳:起始时刻驱动(单次 380ms 衰减,结束即归位——不再持续微晃)。
  Duration? _bounceStart;

  // 渲染插值:VM 每 100ms 才更新一次 containerX,而画面每帧重绘——
  // 直接使用会呈 10Hz 阶梯(视觉抖动)。在相邻两拍之间做 easeOut 插值,
  // 使篮子以帧率平滑移动。
  double _displayX = 0.5;
  double _fromX = 0.5;
  double _toX = 0.5;
  Duration _lerpStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(CatchDropBoard old) {
    super.didUpdateWidget(old);
    final newX = widget.snapshot.containerX;
    if ((newX - _toX).abs() > 0.0005) {
      _fromX = _displayX;
      _toX = newX;
      _lerpStart = _now;
    }
    if (widget.eventSeq != _lastSeq) {
      _lastSeq = widget.eventSeq;
      for (final e in widget.events) {
        if (e is DropCaught) {
          _floats.add(
            _FloatingScore(
              x: e.x,
              text: '+${e.gained}',
              golden: e.kind == DropKind.golden,
              born: _now,
            ),
          );
          _bounceStart = _now;
          _burst(e.x, golden: e.kind == DropKind.golden);
        }
      }
    }
  }

  /// 弹跳系数:0→1 的阻尼余弦,380ms 内收敛到 1.0(精确),避免持续抖动。
  double get _bounce {
    final start = _bounceStart;
    if (start == null) {
      return 1.0;
    }
    final ms = (_now - start).inMilliseconds;
    if (ms >= 380) {
      _bounceStart = null;
      return 1.0;
    }
    final t = ms / 380.0;
    final decay = math.exp(-4.5 * t);
    return 1.0 + 0.16 * decay * math.cos(2 * math.pi * 1.6 * t);
  }

  void _burst(double x, {required bool golden}) {
    final rnd = math.Random(x.hashCode);
    final count = golden ? 18 : 8;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.2;
      final speed = 90 + rnd.nextDouble() * (golden ? 160 : 90);
      _particles.add(
        _Particle(
          x: x,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          born: _now,
          golden: golden,
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    _now = elapsed;
    // 相邻两拍(默认 100ms)之间插值,消除阶梯感。
    final tMs = (_now - _lerpStart).inMilliseconds;
    final t = (tMs / widget.tickMs).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    _displayX = _fromX + (_toX - _fromX) * eased;
    _floats.removeWhere(
      (f) => _now - f.born > const Duration(milliseconds: 850),
    );
    _particles.removeWhere(
      (p) => _now - p.born > const Duration(milliseconds: 700),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 读屏:分数 / 剩余时间 / 当前引导(棋盘为纯自绘,需显式语义)。
    return Semantics(
      label:
          '得分 ${widget.snapshot.score},剩余 ${widget.remainingSeconds} 秒。'
          '${widget.snapshot.goldenPresent ? "金阳光出现" : ""}',
      liveRegion: true,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final snap = widget.snapshot;
            final basketLeft =
                (snap.containerX * w - CatchDropBoard.basketWidth / 2).clamp(
                  0.0,
                  w - CatchDropBoard.basketWidth,
                );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 2.5D 玩法背景(iso 花园世界,上 70% 天空留白给掉落物)。
                Positioned.fill(
                  child: Image.asset(
                    'assets/game/backdrop_catch.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CatchDropPainter(
                      snapshot: snap,
                      remainingSeconds: widget.remainingSeconds,
                      totalSeconds: widget.totalSeconds,
                      now: _now,
                      floats: _floats,
                      particles: _particles,
                      dropSize: CatchDropBoard.normalDropSize,
                      goldenSize: CatchDropBoard.goldenDropSize,
                    ),
                  ),
                ),
                // 掉落物精灵(图片,非纯色圆点)。
                for (final drop in snap.activeDrops) _dropSprite(drop, w, h),
                // 篮子容器(接住弹跳)。
                Positioned(
                  left: basketLeft,
                  bottom: 12,
                  width: CatchDropBoard.basketWidth,
                  height: CatchDropBoard.basketWidth,
                  child: Transform.scale(
                    scale: _bounce,
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/game/basket_iso.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (snap.combo >= 3)
                  Positioned(
                    left: 16,
                    top: 24,
                    child: _ComboBadge(combo: snap.combo),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dropSprite(Drop drop, double w, double h) {
    final p = drop.progressAt(widget.snapshot.elapsed);
    final golden = drop.kind == DropKind.golden;
    final size = golden
        ? CatchDropBoard.goldenDropSize
        : CatchDropBoard.normalDropSize;
    final y = 12 + p * (h - 12 - size - 40);
    return Positioned(
      left: drop.x * w - size / 2,
      top: y,
      width: size,
      height: size,
      child: Transform.rotate(
        angle: math.sin(_now.inMilliseconds / 320.0 + drop.id) * 0.12,
        child: Image.asset(
          golden ? 'assets/game/golden_sun_iso.png' : 'assets/game/sun_iso.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _FloatingScore {
  _FloatingScore({
    required this.x,
    required this.text,
    required this.golden,
    required this.born,
  });

  final double x;
  final String text;
  final bool golden;
  final Duration born;
}

class _Particle {
  _Particle({
    required this.x,
    required this.vx,
    required this.vy,
    required this.born,
    required this.golden,
  });

  final double x;
  final double vx;
  final double vy;
  final Duration born;
  final bool golden;
}

/// 连击徽章:脉冲缩放。
class _ComboBadge extends StatefulWidget {
  const _ComboBadge({required this.combo});

  final int combo;

  @override
  State<_ComboBadge> createState() => _ComboBadgeState();
}

class _ComboBadgeState extends State<_ComboBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.94,
        end: 1.06,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentWarm,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentWarm.withValues(alpha: 0.5),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          '${widget.combo} 连击 ×1.2',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF28332F),
          ),
        ),
      ),
    );
  }
}

class _CatchDropPainter extends CustomPainter {
  _CatchDropPainter({
    required this.snapshot,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.now,
    required this.floats,
    required this.particles,
    required this.dropSize,
    required this.goldenSize,
  });

  final CatchDropSnapshot snapshot;
  final int remainingSeconds;
  final int totalSeconds;
  final Duration now;
  final List<_FloatingScore> floats;
  final List<_Particle> particles;
  final double dropSize;
  final double goldenSize;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 背景(天空+云)由位图 backdrop_catch.png 承担,本 painter 只画动态元素。

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
            : AppColors.primary.withValues(alpha: 0.7),
    );

    // 掉落物光晕(精灵图之下的柔光;图片本体由 Stack 绘制)。
    for (final drop in snapshot.activeDrops) {
      final p = drop.progressAt(snapshot.elapsed);
      final golden = drop.kind == DropKind.golden;
      final sz = golden ? goldenSize : dropSize;
      final y = 12 + p * (h - 12 - sz - 40) + sz / 2;
      final x = drop.x * w;
      final glow = Paint()
        ..color = (golden ? const Color(0xFFFFC933) : AppColors.accentWarm)
            .withValues(alpha: golden ? 0.45 : 0.3);
      canvas.drawCircle(Offset(x, y), sz * 0.78, glow);
      if (golden && snapshot.goldenChargeProgress > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: sz * 0.95),
          -math.pi / 2,
          2 * math.pi * snapshot.goldenChargeProgress,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..color = snapshot.goldenCharging
                ? AppColors.primary
                : AppColors.textTertiary,
        );
        // 充能百分比(让「保持」有明确反馈)。
        final pct = (snapshot.goldenChargeProgress * 100).round();
        final pctTp = TextPainter(
          text: TextSpan(
            text: '$pct%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: snapshot.goldenCharging
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        pctTp.paint(canvas, Offset(x - pctTp.width / 2, y + sz * 1.02));
      }
      // 未对齐:从篮子指向金阳光的箭头(告诉用户往哪移)。
      if (golden && !snapshot.goldenAligned) {
        final basketX = snapshot.containerX * w;
        final dir = (x - basketX).sign;
        final tip = Offset(basketX + dir * 34, h - 76);
        final arrow = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx - dir * 12, tip.dy - 10)
          ..lineTo(tip.dx - dir * 12, tip.dy + 10)
          ..close();
        canvas.drawPath(
          arrow,
          Paint()..color = const Color(0xFFFFC933).withValues(alpha: 0.9),
        );
      }
    }

    // 粒子。
    for (final particle in particles) {
      final age = (now - particle.born).inMilliseconds / 700.0;
      if (age < 0 || age > 1) {
        continue;
      }
      final px = particle.x * w + particle.vx * age * 0.6;
      final py = (h - 90) + particle.vy * age * 0.6 + 220 * age * age;
      canvas.drawCircle(
        Offset(px, py),
        (particle.golden ? 5.0 : 3.5) * (1 - age),
        Paint()
          ..color =
              (particle.golden ? const Color(0xFFFFC933) : AppColors.accentWarm)
                  .withValues(alpha: 1 - age),
      );
    }

    // 飘字。
    for (final f in floats) {
      final age = (now - f.born).inMilliseconds / 850.0;
      if (age < 0 || age > 1) {
        continue;
      }
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontSize: f.golden ? 30 : 22,
            fontWeight: FontWeight.w800,
            color: (f.golden ? const Color(0xFFE0A200) : AppColors.primary)
                .withValues(alpha: 1 - age),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(f.x * w - tp.width / 2, h - 120 - age * 70));
    }

    // 分数:HUD 深色胶囊+白字(与花园 HUD 统一)。
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '${snapshot.score}',
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pillW = scoreTp.width + 30;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - pillW - 16, 14, pillW, 40),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      pillRect,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    scoreTp.paint(
      canvas,
      Offset(w - scoreTp.width - 16 - 15, 14 + (40 - scoreTp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(_CatchDropPainter old) => true; // 动画驱动
}
