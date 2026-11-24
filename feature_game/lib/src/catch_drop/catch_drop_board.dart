import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../garden/garden_ui_theme.dart';
import 'catch_drop_session.dart';

/// 接阳光棋盘(林边小院水粉风表现层)。
///
/// 组合:RepaintBoundary + CustomPaint(阳光柔光/金阳光充能环/余光边缘光带/
/// 粒子/飘字/草尖消散)+ 手绘水粉精灵图(小阳光/大金阳光/枫木托盘)。
/// 顶栏 HUD 与底部单槽引导胶囊由外层 [GamePlayArea] 统一绘制,避免重复遮挡。
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

  /// 本局总时长(保留接口供预览/扩展使用)。
  final int totalSeconds;

  /// VM 传入的打点事件(与 [eventSeq] 配合去重消费)。
  final List<CatchEvent> events;

  /// 事件序号:变化即视为新事件批次。
  final int eventSeq;

  /// 逻辑 tick 周期(毫秒):位置插值窗口,与 VM config 对齐。
  final int tickMs;

  /// 普通阳光精灵尺寸(逻辑像素)。
  static const double normalDropSize = 48;

  /// 金阳光精灵尺寸。
  static const double goldenDropSize = 80;

  /// 枫木托盘尺寸(宽 × 高,匹配 540×130 宽托盘比例)。
  static const double basketWidth = 112;
  static const double basketHeight = 36;

  /// 棋盘按此宽度排布;舞台更宽时整体等比放大,而不是把精灵散到整幅宽度。
  static const double referenceWidth = 480;

  /// 与最宽的练习舞台(640)对应的比例。
  static const double maxStageScale = 4 / 3;

  static double stageScaleFor(double stageWidth) =>
      (stageWidth / referenceWidth).clamp(1.0, maxStageScale);

  @override
  State<CatchDropBoard> createState() => _CatchDropBoardState();
}

class _CatchDropBoardState extends State<CatchDropBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<Duration> _frameTick = ValueNotifier<Duration>(
    Duration.zero,
  );
  final List<_FloatingScore> _floats = [];
  final List<_Particle> _particles = [];
  final List<_MissSparkle> _missSparkles = [];
  Duration _now = Duration.zero;
  int _lastSeq = -1;
  bool _reduceMotion = false;

  /// 接住弹跳:起始时刻驱动(单次 380ms 衰减,结束即归位)。
  Duration? _bounceStart;

  /// 接住偏移微倾:按落点偏心角阻尼回正(±4°以内,减弱动态下禁用)。
  Duration? _tiltStart;
  double _tiltPeak = 0;

  // 渲染插值:VM 按 50ms 逻辑拍更新 containerX,在相邻两拍之间做 easeOut 插值,
  // 使托盘以屏幕刷新率平滑滑动。
  double _displayX = 0.5;
  double _fromX = 0.5;
  double _toX = 0.5;
  Duration _lerpStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _displayX = widget.snapshot.containerX;
    _fromX = widget.snapshot.containerX;
    _toX = widget.snapshot.containerX;
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _floats.clear();
      _particles.clear();
      _missSparkles.clear();
      _bounceStart = null;
      _tiltStart = null;
      _tiltPeak = 0;
    }
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
        if (e is DropCaught && !_reduceMotion) {
          _floats.add(
            _FloatingScore(
              x: e.x,
              text: '+${e.gained}',
              golden: e.kind == DropKind.golden,
              born: _now,
            ),
          );
          _bounceStart = _now;
          final offset = (e.x - _displayX).clamp(-0.18, 0.18);
          _tiltPeak = (offset / 0.18) * 0.07;
          _tiltStart = _now;
          _burst(e.x, golden: e.kind == DropKind.golden);
        } else if (e is DropMissed && !_reduceMotion) {
          _missSparkles.add(_MissSparkle(x: e.x, born: _now));
        }
      }
    }
  }

  /// 弹跳系数:0→1 的阻尼余弦,380ms 内收敛到 1.0,避免持续抖动。
  double get _bounce {
    if (_reduceMotion) return 1;
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

  /// 托盘偏心微倾弧度:接住瞬间轻微向落点一侧压低并阻尼回正。
  double get _tiltRad {
    if (_reduceMotion) return 0;
    final start = _tiltStart;
    if (start == null) return 0;
    final ms = (_now - start).inMilliseconds;
    if (ms >= 380) {
      _tiltStart = null;
      _tiltPeak = 0;
      return 0;
    }
    final t = ms / 380.0;
    final decay = math.exp(-4.5 * t);
    return _tiltPeak * decay * math.sin(math.pi * 1.5 * t);
  }

  void _burst(double x, {required bool golden}) {
    final rnd = math.Random(x.hashCode ^ _now.inMilliseconds);
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
    _missSparkles.removeWhere(
      (s) => _now - s.born > const Duration(milliseconds: 550),
    );
    if (mounted) {
      _frameTick.value = _now;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frameTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.snapshot;
    return Semantics(
      label:
          '得分 ${snap.score},剩余 ${widget.remainingSeconds} 秒。'
          '${snap.goldenPresent ? "大金阳光出现" : ""}',
      liveRegion: true,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final maxLeft = math.max(0.0, w - CatchDropBoard.basketWidth);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CatchDropPainter(
                        repaint: _frameTick,
                        snapshot: snap,
                        nowProvider: () => _now,
                        floats: _floats,
                        particles: _particles,
                        missSparkles: _missSparkles,
                        dropSize: CatchDropBoard.normalDropSize,
                        goldenSize: CatchDropBoard.goldenDropSize,
                        reduceMotion: _reduceMotion,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ValueListenableBuilder<Duration>(
                    valueListenable: _frameTick,
                    builder: (context, _, _) {
                      final basketLeft =
                          (_displayX * w - CatchDropBoard.basketWidth / 2)
                              .clamp(0.0, maxLeft);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final drop in snap.activeDrops)
                            _dropSprite(drop, w, h),
                          Positioned(
                            left: basketLeft,
                            bottom: 18,
                            width: CatchDropBoard.basketWidth,
                            height: CatchDropBoard.basketHeight,
                            child: Transform.scale(
                              scale: _bounce,
                              alignment: Alignment.bottomCenter,
                              child: Transform.rotate(
                                angle: _tiltRad,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/game/catch_maple_tray.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (snap.combo >= 3)
                  Positioned(
                    left: 16,
                    top: 10,
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
    final y = 12 + p * (h - 12 - size - 44);
    final sway = _reduceMotion
        ? 0.0
        : math.sin(_now.inMilliseconds / 360.0 + drop.id) * 0.10;
    return Positioned(
      left: drop.x * w - size / 2,
      top: y,
      width: size,
      height: size,
      child: Transform.rotate(
        angle: sway,
        child: Image.asset(
          golden
              ? 'assets/game/catch_sun_large.png'
              : 'assets/game/catch_sun_small.png',
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

class _MissSparkle {
  _MissSparkle({required this.x, required this.born});

  final double x;
  final Duration born;
}

/// 连续接住徽章:暖金纸感样式(与小院暖纸视觉统一)。
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo});
  final int combo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GardenUiTheme.honey,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GardenUiTheme.honeyEdge),
        boxShadow: const [
          BoxShadow(
            color: GardenUiTheme.softShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$combo 连击 ×1.2',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: GardenUiTheme.ink,
        ),
      ),
    );
  }
}

class _CatchDropPainter extends CustomPainter {
  _CatchDropPainter({
    required Listenable repaint,
    required this.snapshot,
    required this.nowProvider,
    required this.floats,
    required this.particles,
    required this.missSparkles,
    required this.dropSize,
    required this.goldenSize,
    required this.reduceMotion,
  }) : super(repaint: repaint);

  final CatchDropSnapshot snapshot;
  final Duration Function() nowProvider;
  final List<_FloatingScore> floats;
  final List<_Particle> particles;
  final List<_MissSparkle> missSparkles;
  final double dropSize;
  final double goldenSize;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final now = nowProvider();

    // 1. 余光边缘暖金光带(大金阳光在场时):
    // 侧头幅度较大时用户主要依赖余光确认方向与充能状态。
    if (snapshot.goldenPresent) {
      int dir = snapshot.goldenSide;
      if (dir == 0) {
        for (final drop in snapshot.activeDrops) {
          if (drop.kind == DropKind.golden) {
            dir = drop.x < 0.5 ? -1 : 1;
            break;
          }
        }
      }
      if (dir != 0) {
        final aligned = snapshot.goldenAligned;
        final bandWidth = aligned ? 30.0 : 22.0;
        final alpha = aligned
            ? 0.55
            : (reduceMotion
                  ? 0.36
                  : (math.sin(now.inMilliseconds / 260 * math.pi) * 0.5 + 0.5) *
                            0.24 +
                        0.26);
        final edgeRect = Rect.fromLTWH(
          dir < 0 ? 0 : w - bandWidth,
          0,
          bandWidth,
          h,
        );
        final glowColor = aligned
            ? GardenUiTheme.honeyDeep
            : GardenUiTheme.honey;
        canvas.drawRect(
          edgeRect,
          Paint()
            ..shader = LinearGradient(
              begin: dir < 0 ? Alignment.centerLeft : Alignment.centerRight,
              end: dir < 0 ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                glowColor.withValues(alpha: alpha),
                glowColor.withValues(alpha: 0),
              ],
            ).createShader(edgeRect),
        );
      }
    }

    // 2. 掉落物柔光与金阳光充能进度环。
    for (final drop in snapshot.activeDrops) {
      final p = drop.progressAt(snapshot.elapsed);
      final golden = drop.kind == DropKind.golden;
      final sz = golden ? goldenSize : dropSize;
      final y = 12 + p * (h - 12 - sz - 44) + sz / 2;
      final x = drop.x * w;
      final glowColor = golden ? GardenUiTheme.honeyDeep : GardenUiTheme.honey;
      canvas.drawCircle(
        Offset(x, y),
        sz * 0.74,
        Paint()..color = glowColor.withValues(alpha: golden ? 0.36 : 0.24),
      );
      if (golden && snapshot.goldenChargeProgress > 0) {
        // 底部浅环底轨,让充能进度更易读。
        canvas.drawCircle(
          Offset(x, y),
          sz * 0.88,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..color = GardenUiTheme.paper.withValues(alpha: 0.65),
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: sz * 0.88),
          -math.pi / 2,
          2 * math.pi * snapshot.goldenChargeProgress,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round
            ..color = snapshot.goldenCharging
                ? GardenUiTheme.sunInk
                : GardenUiTheme.mutedInk,
        );
        // 充能百分比暖纸胶囊(高对比,不融入浅色天空)。
        final pct = (snapshot.goldenChargeProgress * 100).round();
        final pctTp = TextPainter(
          text: TextSpan(
            text: '$pct%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: snapshot.goldenCharging
                  ? GardenUiTheme.sunInk
                  : GardenUiTheme.mutedInk,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final badgeW = pctTp.width + 14;
        final badgeH = pctTp.height + 6;
        final badgeTop = y + sz * 0.94;
        final badgeRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - badgeW / 2, badgeTop, badgeW, badgeH),
          const Radius.circular(10),
        );
        canvas.drawRRect(
          badgeRect,
          Paint()..color = GardenUiTheme.paper.withValues(alpha: 0.92),
        );
        pctTp.paint(canvas, Offset(x - pctTp.width / 2, badgeTop + 3));
      }
    }

    // 3. 漏接草尖温和消散光点(无红色警示或扣分惩罚)。
    for (final s in missSparkles) {
      final age = (now - s.born).inMilliseconds / 550.0;
      if (age < 0 || age > 1) continue;
      final cx = s.x * w;
      final cy = h - 22 - age * 14;
      final alpha = (1 - age) * 0.55;
      canvas.drawCircle(
        Offset(cx, cy),
        10 * (1 - age * 0.5),
        Paint()..color = GardenUiTheme.honey.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset(cx - 12 * age, cy - 4 * age),
        3.5 * (1 - age),
        Paint()..color = GardenUiTheme.paper.withValues(alpha: alpha),
      );
      canvas.drawCircle(
        Offset(cx + 12 * age, cy - 6 * age),
        3.5 * (1 - age),
        Paint()..color = GardenUiTheme.paper.withValues(alpha: alpha),
      );
    }

    // 4. 接住粒子。
    for (final particle in particles) {
      final age = (now - particle.born).inMilliseconds / 700.0;
      if (age < 0 || age > 1) continue;
      final px = particle.x * w + particle.vx * age * 0.55;
      final py = (h - 52) + particle.vy * age * 0.55 + 200 * age * age;
      canvas.drawCircle(
        Offset(px, py),
        (particle.golden ? 5.2 : 3.6) * (1 - age),
        Paint()
          ..color =
              (particle.golden ? GardenUiTheme.honeyDeep : GardenUiTheme.honey)
                  .withValues(alpha: 1 - age),
      );
    }

    // 5. 接住飘字(带暖纸底衬,确保晴朗草地背景上清晰可读)。
    for (final f in floats) {
      final age = (now - f.born).inMilliseconds / 850.0;
      if (age < 0 || age > 1) continue;
      final opacity = (1 - age).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontSize: f.golden ? 28 : 20,
            fontWeight: FontWeight.w800,
            color: (f.golden ? GardenUiTheme.sunInk : GardenUiTheme.leaf)
                .withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final left = (f.x * w - tp.width / 2).clamp(8.0, w - tp.width - 8);
      final top = h - 88 - age * 66;
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 8, top - 2, tp.width + 16, tp.height + 4),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        pill,
        Paint()..color = GardenUiTheme.paper.withValues(alpha: opacity * 0.85),
      );
      tp.paint(canvas, Offset(left, top));
    }
  }

  @override
  bool shouldRepaint(_CatchDropPainter old) =>
      old.snapshot != snapshot || old.reduceMotion != reduceMotion;
}
