import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'garden_scene.dart';

/// 花园立体画风 Demo(实验页,仅供 dev 渠道对比挑选)。
///
/// 纯视图:两种立体风格各一页全屏场景 + 现有扁平风基线,不接任何
/// 玩法状态(逻辑层零改动)。风格:
/// A Claymorphism 黏土立体——圆角体积、双阶明暗、同色系柔渐变;
/// B 2.5D 等距花园——菱形地块、带厚度立面、深度排序、暖光长影。
class GardenStyleDemoScreen extends StatefulWidget {
  const GardenStyleDemoScreen({super.key});

  @override
  State<GardenStyleDemoScreen> createState() => _GardenStyleDemoScreenState();
}

class _GardenStyleDemoScreenState extends State<GardenStyleDemoScreen> {
  var _style = _DemoStyle.clay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(title: const Text('花园立体风格 Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_DemoStyle>(
              segments: const [
                ButtonSegment(
                  value: _DemoStyle.clay,
                  label: Text('A 黏土立体'),
                  icon: Icon(Icons.rounded_corner),
                ),
                ButtonSegment(
                  value: _DemoStyle.isometric,
                  label: Text('B 等距2.5D'),
                  icon: Icon(Icons.view_in_ar_outlined),
                ),
                ButtonSegment(
                  value: _DemoStyle.flat,
                  label: Text('扁平基线'),
                  icon: Icon(Icons.layers_outlined),
                ),
              ],
              selected: {_style},
              onSelectionChanged: (selection) =>
                  setState(() => _style = selection.first),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(_style),
                child: switch (_style) {
                  _DemoStyle.clay => const _ClayGardenScene(),
                  _DemoStyle.isometric => const _IsoGardenScene(),
                  _DemoStyle.flat =>
                    const GardenScene(timeOfDay: GardenTimeOfDay.noon),
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              switch (_style) {
                _DemoStyle.clay =>
                  'A Claymorphism:圆角体积 + 顶光/环境影双阶明暗 + 同色系柔渐变',
                _DemoStyle.isometric =>
                  'B 2.5D 等距(锚点 edit_iso B):土台草顶 + 白框花畦 + 丛叶树 + 低多边形丛灌',
                _DemoStyle.flat => '基线:现有扁平矢量风(garden_scene.dart)',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

enum _DemoStyle { clay, isometric, flat }

// ============ 风格 A:Claymorphism 黏土立体 ============

class _ClayGardenScene extends StatelessWidget {
  const _ClayGardenScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClayGardenPainter(),
      size: Size.infinite,
      isComplex: true,
    );
  }
}

/// 黏土立体场景:不受 9 色板扁平约束,允许同色系柔渐变与投影。
class _ClayGardenPainter extends CustomPainter {
  // 黏土色系:主绿三阶 + 奶白陶土 + 天空薄荷渐变。
  static const _skyTop = Color(0xFFBFF0E8);
  static const _skyBottom = Color(0xFFE9FBF6);
  static const _clayLight = Color(0xFF8FE8DA);
  static const _clayMain = Color(0xFF35CDB8);
  static const _clayDeep = Color(0xFF1E9C8C);
  static const _clayShadow = Color(0x221E9C8C);
  static const _cream = Color(0xFFF7F5EC);
  static const _creamShade = Color(0xFFDDD8C8);
  static const _terra = Color(0xFFC98F71);
  static const _terraDeep = Color(0xFFB57F62);
  static const _soil = Color(0xFF7A5C48);
  static const _lemon = Color(0xFFFCFF7D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 天空:同色系垂直柔渐变。
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    _sun(canvas, w, h);
    _cloud(canvas, w, h, Offset(0.18 * w, 0.26 * h), 0.13 * w);
    _cloud(canvas, w, h, Offset(0.44 * w, 0.13 * h), 0.09 * w);
    _canopy(canvas, w, h, left: true);
    _canopy(canvas, w, h, left: false);
    _ground(canvas, w, h);
    _hedge(canvas, w, h);
    _fence(canvas, w, h);
    _bed(canvas, w, h, Offset(0.22 * w, 0.80 * h), 0.30 * w, flower: false);
    _bed(canvas, w, h, Offset(0.78 * w, 0.80 * h), 0.30 * w, flower: true);
  }

  /// 黏土太阳:径向渐变球体 + 左上高光 + 柔投影。
  void _sun(Canvas canvas, double w, double h) {
    final center = Offset(0.63 * w, 0.22 * h);
    final r = 0.085 * w;
    canvas.drawCircle(
      center + Offset(0.008 * w, 0.014 * h),
      r,
      Paint()
        ..color = _clayShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [const Color(0xFFFFFDE6), _lemon],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    canvas.drawCircle(
      center - Offset(0.03 * w, 0.03 * w),
      r * 0.22,
      Paint()..color = const Color(0xB4FFFFFF),
    );
  }

  /// 黏土云:双层圆簇(下层偏移成底缘阴影)。
  void _cloud(Canvas canvas, double w, double h, Offset center, double r) {
    final shade = Paint()..color = const Color(0xFFCFEAE3);
    for (final d in const [(-0.6, 0.15), (0.0, -0.35), (0.6, 0.15)]) {
      canvas.drawCircle(
        center + Offset(d.$1 * r, (d.$2 + 0.14) * r),
        r * 0.55,
        shade,
      );
    }
    final body = Paint()..color = const Color(0xFFFFFFFF);
    for (final d in const [(-0.6, 0.1), (0.0, -0.35), (0.6, 0.1)]) {
      canvas.drawCircle(center + Offset(d.$1 * r, d.$2 * r), r * 0.55, body);
    }
  }

  /// 树冠:三阶圆簇 + 左上高光,陶土枝干带亮侧条纹,地面柔影。
  void _canopy(Canvas canvas, double w, double h, {required bool left}) {
    final side = left ? -1.0 : 1.0;
    final cx = (0.5 + side * 0.42) * w;
    final cy = 0.055 * h;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, 0.20 * h),
        width: 0.30 * w,
        height: 0.035 * h,
      ),
      Paint()
        ..color = _clayShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 0.018 * w, cy, 0.036 * w, 0.14 * h),
        bottomLeft: const Radius.circular(12),
        bottomRight: const Radius.circular(12),
      ),
      Paint()..color = _terraDeep,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 0.018 * w, cy, 0.016 * w, 0.14 * h),
        bottomLeft: const Radius.circular(10),
      ),
      Paint()..color = _terra,
    );
    _clayBall(
      canvas,
      Offset(cx - side * 0.02 * w, cy + 0.015 * h),
      0.155 * w,
      _clayDeep,
      _clayMain,
    );
    _clayBall(canvas, Offset(cx - side * 0.09 * w, cy + 0.05 * h), 0.09 * w,
        _clayDeep, _clayMain);
    _clayBall(canvas, Offset(cx + side * 0.07 * w, cy - 0.005 * h), 0.08 * w,
        _clayMain, _clayLight);
  }

  /// 黏土球:主色渐变 + 左上高光斑。
  void _clayBall(Canvas canvas, Offset c, double r, Color base, Color light) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.45),
          colors: [light, base],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c - Offset(r * 0.38, r * 0.38),
      r * 0.2,
      Paint()..color = const Color(0x8CFFFFFF),
    );
  }

  /// 草地大圆角黏土板:渐变 + 顶缘内侧阴影带。
  void _ground(Canvas canvas, double w, double h) {
    final slab = Rect.fromLTWH(-0.1 * w, 0.46 * h, 1.2 * w, 0.64 * h);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        slab,
        topLeft: const Radius.circular(36),
        topRight: Radius.circular(36),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF7EDDC9), Color(0xFF49BBA7)],
        ).createShader(slab),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-0.1 * w, 0.46 * h, 1.2 * w, 0.02 * h),
        topLeft: const Radius.circular(36),
        topRight: Radius.circular(36),
      ),
      Paint()..color = const Color(0x261E9C8C),
    );
  }

  /// 黏土灌木:每颗为深阶底影 + 主色球 + 高光弧。
  void _hedge(Canvas canvas, double w, double h) {
    final y = 0.495 * h;
    final r = 0.028 * h;
    for (double x = -0.01 * w; x < 1.02 * w; x += 0.048 * w) {
      canvas.drawCircle(
        Offset(x + r * 0.15, y + r * 0.2),
        r,
        Paint()..color = _clayDeep,
      );
      _clayBall(canvas, Offset(x, y), r, _clayDeep, _clayMain);
      canvas.drawCircle(
        Offset(x - r * 0.3, y - r * 0.35),
        r * 0.28,
        Paint()..color = _clayLight,
      );
    }
  }

  /// 黏土栅栏:横档带底缘阴影,尖桩左亮右暗渐变 + 接地小影。
  void _fence(Canvas canvas, double w, double h) {
    final top = 0.54 * h;
    final bottom = 0.68 * h;
    for (final railY in [top + 0.025 * h, bottom - 0.05 * h]) {
      canvas.drawRect(
        Rect.fromLTWH(0, railY + 0.006 * h, w, 0.018 * h),
        Paint()..color = _creamShade,
      );
      canvas.drawRect(
        Rect.fromLTWH(0, railY, w, 0.018 * h),
        Paint()..color = _cream,
      );
    }
    final pw = 0.045 * w;
    final topRadius = Radius.circular(pw / 2);
    for (double x = 0.012 * w; x < w; x += 0.075 * w) {
      final rect = Rect.fromLTWH(x, top, pw, bottom - top);
      canvas.drawRect(
        Rect.fromLTWH(x + pw * 0.3, bottom - 0.004 * h, pw * 0.7, 0.008 * h),
        Paint()
          ..color = _clayShadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: topRadius,
          topRight: topRadius,
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [Color(0xFFFFFFFF), Color(0xFFE3DFD1)],
          ).createShader(rect),
      );
    }
  }

  /// 黏土花畦:奶白圆角池(上亮下暗) + 土壤内凹 + 小苗/花。
  void _bed(
    Canvas canvas,
    double w,
    double h,
    Offset center,
    double width, {
    required bool flower,
  }) {
    final height = width * 0.38;
    final rim = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, height * 0.55),
        width: width * 0.96,
        height: height * 0.3,
      ),
      Paint()
        ..color = _clayShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rim, Radius.circular(width * 0.1)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFFFFFFF), _creamShade],
        ).createShader(rim),
    );
    final soilRect = rim.deflate(width * 0.045);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        soilRect,
        Radius.circular(width * 0.07),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF8A6A55), _soil],
        ).createShader(soilRect),
    );
    final stem = Paint()
      ..color = _clayDeep
      ..strokeWidth = width * 0.02
      ..strokeCap = StrokeCap.round;
    final cx = rim.center.dx;
    final cy = rim.center.dy;
    canvas.drawLine(
      Offset(cx, cy + height * 0.12),
      Offset(cx, cy - height * 0.3),
      stem,
    );
    _clayBall(canvas, Offset(cx - width * 0.07, cy - height * 0.2),
        width * 0.05, _clayDeep, _clayMain);
    _clayBall(canvas, Offset(cx + width * 0.07, cy - height * 0.2),
        width * 0.05, _clayDeep, _clayMain);
    _clayBall(
      canvas,
      Offset(cx, cy - height * 0.36),
      width * 0.045,
      flower ? const Color(0xFFF0E95C) : _clayMain,
      flower ? _lemon : _clayLight,
    );
  }

  @override
  bool shouldRepaint(_ClayGardenPainter oldDelegate) => false;
}

// ============ 风格 B:2.5D 等距花园(锚点:edit_iso B 候选) ============

class _IsoGardenScene extends StatelessWidget {
  const _IsoGardenScene();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IsoGardenPainter(),
      size: Size.infinite,
      isComplex: true,
    );
  }
}

/// 等距 2.5D 场景(对齐 edit_iso B 候选):土台草顶 + 白框花畦 +
/// 丛叶树 + 低多边形丛灌丘陵。
class _IsoGardenPainter extends CustomPainter {
  // 黄绿黏土色系(取自锚点图)。
  static const _backdropTop = Color(0xFFEFEBC8);
  static const _backdropBottom = Color(0xFFD9DA9C);
  static const _hillFar = Color(0xFFB9C468);
  static const _hillNear = Color(0xFFA5B456);
  static const _bushTop = Color(0xFF6E9C46);
  static const _bushFace = Color(0xFF8FB55C);
  static const _bushHi = Color(0xFFA9CB72);
  static const _grassTop = Color(0xFFB9CC68);
  static const _grassHi = Color(0xFFC8D97C);
  static const _earthSideL = Color(0xFF9A744E);
  static const _earthSideR = Color(0xFF7E5C3E);
  static const _earthEdge = Color(0xFF63472F);
  static const _frameTop = Color(0xFFF7F3E4);
  static const _frameSideL = Color(0xFFE5DEC6);
  static const _frameSideR = Color(0xFFD0C8AD);
  static const _soilTop = Color(0xFF6E4F35);
  static const _trunk = Color(0xFFA05A3C);
  static const _leafLight = Color(0xFFB4D36E);
  static const _leafMain = Color(0xFF8CB750);
  static const _leafDeep = Color(0xFF639246);
  static const _fenceWhite = Color(0xFFF9F6EC);
  static const _fenceShade = Color(0xFFD6D0BC);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 暖调背景(上奶油下橄榄)。
    final backdrop = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      backdrop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_backdropTop, _backdropBottom],
        ).createShader(backdrop),
    );

    // 远景丘陵(两带,连绵地形) + 稀疏丛灌(独立圆顶)。
    _hillBand(canvas, w, h, 0.34 * h, 0.08 * h, _hillFar);
    _hillBand(canvas, w, h, 0.42 * h, 0.09 * h, _hillNear);
    _bushRow(canvas, w, 0.455 * h, 0.075 * w, 3, 1);

    // 等距坐标系:平台 col/row ∈ [-1.6, 1.6]。
    const origin = Offset(0.5, 0.60);
    final tileW = 0.30 * w;
    final tileH = tileW / 2;
    Offset iso(double col, double row) => Offset(
          origin.dx * w + (col - row) * tileW / 2,
          origin.dy * h + (col + row) * tileH / 2,
        );

    // 丛叶树(平台左右后方,先画=在最远层)。
    _blobTree(canvas, w, h, Offset(0.07 * w, 0.58 * h));
    _blobTree(canvas, w, h, Offset(0.93 * w, 0.62 * h));

    // 平台:土坯厚座(草顶 + 左右土侧 + 底棱)。
    _platform(canvas, w, h, iso);

    // 背缘白栅栏(两段,沿平台后两边)。
    _isoFence(canvas, w, h, iso, fromCol: -1.15, toCol: 1.15, row: -1.15);
    _isoFence(canvas, w, h, iso, col: -1.15, fromRow: -1.15, toRow: 1.15);

    // 四块白框花畦(2×2,按 col+row 深度排序)。
    const beds = [(0, 0), (1, 0), (0, 1), (1, 1)];
    for (var sum = 0; sum <= 2; sum++) {
      for (var col = 0; col <= sum; col++) {
        final row = sum - col;
        if (!beds.contains((col, row))) {
          continue;
        }
        _whiteBed(canvas, w, iso, col, row);
      }
    }

    // 前景低多边形丛灌(贴屏底,遮住平台前角)。
    _bushLow(canvas, w, Offset(0.10 * w, 0.93 * h), 0.15 * w);
    _bushLow(canvas, w, Offset(0.44 * w, 0.99 * h), 0.12 * w);
    _bushLow(canvas, w, Offset(0.88 * w, 0.90 * h), 0.14 * w);
  }

  /// 丘陵剪影带:圆丘串 + 矩形底,盖到平台后缘之下。
  void _hillBand(
    Canvas canvas,
    double w,
    double h,
    double y,
    double amp,
    Color color,
  ) {
    final paint = Paint()..color = color;
    for (final fx in const [0.10, 0.38, 0.66, 0.92]) {
      canvas.drawCircle(Offset(fx * w, y), amp, paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, y, w, 0.16 * h),
      paint,
    );
  }

  /// 低多边形丛灌(背景行):主面圆 + 顶深色冠 + 左上高光。
  void _bushRow(Canvas canvas, double w, double y, double r, int n, int seed) {
    for (var i = 0; i < n; i++) {
      final jitter = ((i * 37 + seed * 13) % 17) / 17 * 0.06 * w;
      final x = (i + 0.5) / n * w * 1.08 - 0.04 * w + jitter - 0.03 * w;
      final rr = r * (0.8 + ((i + seed) % 3) * 0.15);
      _bushBlob(canvas, Offset(x, y), rr);
    }
  }

  /// 丛灌团:底面 + 顶冠 + 高光。
  void _bushBlob(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c + Offset(r * 0.1, r * 0.12),
      r,
      Paint()..color = _bushFace,
    );
    canvas.drawCircle(
      c - Offset(r * 0.25, r * 0.28),
      r * 0.72,
      Paint()..color = _bushTop,
    );
    canvas.drawCircle(
      c - Offset(r * 0.38, r * 0.42),
      r * 0.26,
      Paint()..color = _bushHi,
    );
  }

  /// 土台:草顶大菱形 + 左右土侧 + 深色底棱 + 草面光点。
  void _platform(
    Canvas canvas,
    double w,
    double h,
    Offset Function(double, double) iso,
  ) {
    final top = iso(-1.6, -1.6);
    final right = iso(1.6, -1.6);
    final bottom = iso(1.6, 1.6);
    final left = iso(-1.6, 1.6);
    final depth = 0.05 * h;

    final faceL = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..lineTo(left.dx, left.dy + depth)
      ..close();
    final faceR = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(right.dx, right.dy + depth)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..close();
    canvas.drawPath(faceL, Paint()..color = _earthSideL);
    canvas.drawPath(faceR, Paint()..color = _earthSideR);
    // 深色底棱(沿两侧面下缘)。
    final edgeL = Path()
      ..moveTo(left.dx, left.dy + depth)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..lineTo(bottom.dx, bottom.dy + depth + 0.008 * h)
      ..lineTo(left.dx, left.dy + depth + 0.008 * h)
      ..close();
    final edgeR = Path()
      ..moveTo(bottom.dx, bottom.dy + depth)
      ..lineTo(right.dx, right.dy + depth)
      ..lineTo(right.dx, right.dy + depth + 0.008 * h)
      ..lineTo(bottom.dx, bottom.dy + depth + 0.008 * h)
      ..close();
    canvas.drawPath(edgeL, Paint()..color = _earthEdge);
    canvas.drawPath(edgeR, Paint()..color = _earthEdge);

    final topFace = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = _grassTop);
    // 草面浅色光点(固定散布)。
    for (final p in const [
      (-0.9, -0.6),
      (0.2, -1.1),
      (1.0, -0.2),
      (-1.2, 0.6),
      (0.5, 1.1),
      (-0.3, 0.3),
    ]) {
      canvas.drawCircle(
        iso(p.$1, p.$2),
        0.010 * w,
        Paint()..color = _grassHi,
      );
    }
  }

  /// 白框花畦:白框菱形环(带厚度) + 内凹深棕土壤 + 三株小苗。
  void _whiteBed(
    Canvas canvas,
    double w,
    Offset Function(double, double) iso,
    int i,
    int j,
  ) {
    final x0 = -0.95 + i * 1.0;
    final y0 = -0.95 + j * 1.0;
    final s = 0.9;
    final top = iso(x0, y0);
    final right = iso(x0 + s, y0);
    final bottom = iso(x0 + s, y0 + s);
    final left = iso(x0, y0 + s);
    final depth = 0.016 * w;

    final faceL = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..lineTo(left.dx, left.dy + depth)
      ..close();
    final faceR = Path()
      ..moveTo(bottom.dx, bottom.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(right.dx, right.dy + depth)
      ..lineTo(bottom.dx, bottom.dy + depth)
      ..close();
    canvas.drawPath(faceL, Paint()..color = _frameSideL);
    canvas.drawPath(faceR, Paint()..color = _frameSideR);
    final frameTop = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(frameTop, Paint()..color = _frameTop);

    // 内凹土壤(框内缩 0.18)。
    final s0 = x0 + 0.18;
    final soilTop = iso(s0, y0 + 0.18);
    final soilRight = iso(x0 + s - 0.18, y0 + 0.18);
    final soilBottom = iso(x0 + s - 0.18, y0 + s - 0.18);
    final soilLeft = iso(s0, y0 + s - 0.18);
    final soil = Path()
      ..moveTo(soilTop.dx, soilTop.dy)
      ..lineTo(soilRight.dx, soilRight.dy)
      ..lineTo(soilBottom.dx, soilBottom.dy)
      ..lineTo(soilLeft.dx, soilLeft.dy)
      ..close();
    canvas.drawPath(soil, Paint()..color = _soilTop);

    // 三株小苗(固定点位)。
    _sprout(canvas, w, iso(x0 + 0.30, y0 + 0.38), 1.0);
    _sprout(canvas, w, iso(x0 + 0.62, y0 + 0.32), 0.85);
    _sprout(canvas, w, iso(x0 + 0.46, y0 + 0.64), 0.9);
  }

  /// 小苗:短茎 + 双叶 + 顶芽(黄绿)。
  void _sprout(Canvas canvas, double w, Offset base, double scale) {
    final stem = Paint()
      ..color = _leafDeep
      ..strokeWidth = 0.006 * w * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base - Offset(0, 0.045 * w * scale), stem);
    final leaf = Paint()..color = _leafMain;
    canvas.drawOval(
      Rect.fromCenter(
        center: base - Offset(0.022 * w * scale, 0.040 * w * scale),
        width: 0.044 * w * scale,
        height: 0.018 * w * scale,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: base - Offset(-0.022 * w * scale, 0.044 * w * scale),
        width: 0.044 * w * scale,
        height: 0.018 * w * scale,
      ),
      leaf,
    );
    canvas.drawCircle(
      base - Offset(0, 0.058 * w * scale),
      0.012 * w * scale,
      Paint()..color = _leafLight,
    );
  }

  /// 丛叶树:红棕干 + 十余片小叶团簇成的冠。
  void _blobTree(Canvas canvas, double w, double h, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.dx - 0.014 * w,
          base.dy - 0.17 * h,
          0.028 * w,
          0.17 * h,
        ),
        Radius.circular(0.01 * w),
      ),
      Paint()..color = _trunk,
    );
    // 叶团(相对冠心的偏移/半径,三绿色交替)。
    const spots = [
      (-0.06, -0.04, 0.055, 2),
      (0.06, -0.05, 0.05, 1),
      (-0.02, -0.11, 0.05, 0),
      (0.08, -0.10, 0.045, 2),
      (-0.10, -0.09, 0.042, 1),
      (0.0, -0.17, 0.04, 1),
      (-0.06, -0.15, 0.04, 2),
      (0.06, -0.16, 0.038, 0),
      (0.0, -0.07, 0.06, 1),
    ];
    const shades = [_leafLight, _leafMain, _leafDeep];
    final crown = base - Offset(0, 0.14 * h);
    for (final spot in spots) {
      canvas.drawCircle(
        crown + Offset(spot.$1 * w, spot.$2 * h),
        spot.$3 * w,
        Paint()..color = shades[spot.$4],
      );
    }
  }

  /// 白栅栏(沿等距边):立柱(右缘阴影) + 双横档。
  void _isoFence(
    Canvas canvas,
    double w,
    double h,
    Offset Function(double, double) iso, {
    double? fromCol,
    double? toCol,
    double? col,
    double? fromRow,
    double? toRow,
    double? row,
  }) {
    final posts = <Offset>[];
    if (fromCol != null) {
      for (var c = fromCol; c <= toCol!; c += 0.575) {
        posts.add(iso(c, row!));
      }
    } else {
      for (var r = fromRow!; r <= toRow!; r += 0.575) {
        posts.add(iso(col!, r));
      }
    }
    for (var i = 0; i < posts.length - 1; i++) {
      final a = posts[i];
      final b = posts[i + 1];
      canvas.drawLine(
        a - Offset(0, 0.052 * w),
        b - Offset(0, 0.052 * w),
        Paint()
          ..color = _fenceShade
          ..strokeWidth = 0.013 * w
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        a - Offset(0, 0.028 * w),
        b - Offset(0, 0.028 * w),
        Paint()
          ..color = _fenceWhite
          ..strokeWidth = 0.013 * w
          ..strokeCap = StrokeCap.round,
      );
    }
    for (final p in posts) {
      final shadow = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + 0.045 * w, p.dy + 0.016 * w)
        ..lineTo(p.dx + 0.018 * w, p.dy + 0.028 * w)
        ..lineTo(p.dx - 0.008 * w, p.dy + 0.010 * w)
        ..close();
      canvas.drawPath(shadow, Paint()..color = const Color(0x3363472F));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            p.dx - 0.010 * w,
            p.dy - 0.080 * w,
            0.020 * w,
            0.080 * w,
          ),
          Radius.circular(0.007 * w),
        ),
        Paint()..color = _fenceWhite,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          p.dx + 0.002 * w,
          p.dy - 0.080 * w,
          0.008 * w,
          0.080 * w,
        ),
        Paint()..color = _fenceShade,
      );
    }
  }

  /// 前景大丛灌(贴屏底,两层冠 + 高光)。
  void _bushLow(Canvas canvas, double w, Offset base, double r) {
    canvas.drawCircle(
      base + Offset(r * 0.12, r * 0.10),
      r,
      Paint()..color = _bushFace,
    );
    canvas.drawCircle(
      base - Offset(r * 0.28, r * 0.30),
      r * 0.78,
      Paint()..color = _bushTop,
    );
    canvas.drawCircle(
      base + Offset(r * 0.38, -r * 0.18),
      r * 0.5,
      Paint()..color = _bushFace,
    );
    canvas.drawCircle(
      base - Offset(r * 0.42, r * 0.46),
      r * 0.24,
      Paint()..color = _bushHi,
    );
  }

  @override
  bool shouldRepaint(_IsoGardenPainter oldDelegate) => false;
}
