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
                  'B 2.5D 等距:菱形地块网格 + 厚度立面 + 暖光长影 + 深度排序',
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

// ============ 风格 B:2.5D 等距花园 ============

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

/// 等距 2.5D 场景:菱形地块网格 + 带厚度立面 + 深度排序 + 暖光长影。
class _IsoGardenPainter extends CustomPainter {
  // 暖阳草地色系。
  static const _skyTop = Color(0xFFFFF3C9);
  static const _skyBottom = Color(0xFFFFE9B8);
  static const _hillFar = Color(0xFFBCE3C8);
  static const _hillNear = Color(0xFF9AD4B0);
  static const _grassLight = Color(0xFFA9E0B9);
  static const _grassShade = Color(0xFF8CC9A0);
  static const _grassSideL = Color(0xFF6FB586);
  static const _grassSideR = Color(0xFF5B9E72);
  static const _soilTop = Color(0xFF9C7258);
  static const _soilSideL = Color(0xFF7A5C48);
  static const _soilSideR = Color(0xFF63483A);
  static const _wood = Color(0xFFE8DCC0);
  static const _woodShade = Color(0xFFC9B992);
  static const _trunk = Color(0xFFA9714E);
  static const _leafLight = Color(0xFF7FD6A4);
  static const _leafMain = Color(0xFF4FBF83);
  static const _leafDeep = Color(0xFF3AA06A);
  static const _sunCore = Color(0xFFFFF6CC);
  static const _sunEdge = Color(0xFFFFD98A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 暖阳天空。
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // 太阳与光晕。
    final sun = Offset(0.78 * w, 0.12 * h);
    canvas.drawCircle(
      sun,
      0.14 * w,
      Paint()..color = const Color(0x55FFD98A),
    );
    canvas.drawCircle(
      sun,
      0.07 * w,
      Paint()
        ..shader = RadialGradient(
          colors: [_sunCore, _sunEdge],
        ).createShader(Rect.fromCircle(center: sun, radius: 0.07 * w)),
    );

    // 远山两层(景深,藏在平台后缘)。
    canvas.drawCircle(
      Offset(0.16 * w, 0.40 * h),
      0.26 * w,
      Paint()..color = _hillFar,
    );
    canvas.drawCircle(
      Offset(0.86 * w, 0.42 * h),
      0.30 * w,
      Paint()..color = _hillFar,
    );
    canvas.drawCircle(
      Offset(0.55 * w, 0.44 * h),
      0.28 * w,
      Paint()..color = _hillNear,
    );

    // 平台底座(带厚度的大菱形草地)。
    const origin = Offset(0.5, 0.26);
    final tileW = 0.34 * w;
    final tileH = tileW / 2;
    Offset iso(double col, double row) => Offset(
          origin.dx * w + (col - row) * tileW / 2,
          origin.dy * h + (col + row) * tileH / 2,
        );

    // 底座立面(先画左右两块深色侧面)。
    final baseL = iso(-1.4, 3.6);
    final baseB = iso(3.6, 3.6);
    final baseR = iso(3.6, -1.4);
    final baseDepth = 0.07 * h;
    final basePath = Path()
      ..moveTo(baseL.dx, baseL.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..lineTo(baseB.dx, baseB.dy + baseDepth)
      ..lineTo(baseL.dx, baseL.dy + baseDepth)
      ..close();
    canvas.drawPath(basePath, Paint()..color = _grassSideR);
    final basePathR = Path()
      ..moveTo(baseB.dx, baseB.dy)
      ..lineTo(baseR.dx, baseR.dy)
      ..lineTo(baseR.dx, baseR.dy + baseDepth)
      ..lineTo(baseB.dx, baseB.dy + baseDepth)
      ..close();
    canvas.drawPath(basePathR, Paint()..color = _grassSideR);

    // 草地顶面(大菱形,微渐变)。
    final groundTop = Path()
      ..moveTo(baseL.dx, baseL.dy)
      ..lineTo(iso(3.6, -1.4).dx, iso(-1.4, -1.4).dy)
      ..lineTo(baseR.dx, baseR.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();
    canvas.drawPath(
      groundTop,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_grassLight, _grassShade],
        ).createShader(Rect.fromLTWH(0, 0.3 * h, w, 0.6 * h)),
    );

    // 背边栅栏(两段,先画在地块后面)。
    _isoFence(canvas, w, h, iso, fromCol: -0.9, toCol: 3.0, row: -1.1);
    _isoFence(canvas, w, h, iso, col: -1.1, fromRow: -0.9, toRow: 3.0);

    // 地块网格(按 col+row 深度排序绘制,中央 2×2 为土壤花畦)。
    const plots = {(1, 1), (2, 1), (1, 2), (2, 2)};
    for (var sum = -3; sum <= 7; sum++) {
      for (var col = -2; col <= sum; col++) {
        final row = sum - col;
        if (row < -2 || col < -2 || row > 3 || col > 3) {
          continue;
        }
        _isoTile(
          canvas,
          w,
          iso(col - 0.04, row - 0.04),
          iso(col + 1.04, row - 0.04),
          iso(col + 1.04, row + 1.04),
          iso(col - 0.04, row + 1.04),
          soil: plots.contains((col, row)),
          checker: (col + row).isOdd,
        );
      }
    }

    // 花畦里的小苗(深度排序后画)。
    for (final plot in plots) {
      _isoSprout(canvas, w, iso(plot.$1 + 0.5, plot.$2 + 0.5));
    }

    // 等距树(左后/右后各一,先画靠后的)。
    _isoTree(canvas, w, h, iso(-0.55, -0.35));
    _isoTree(canvas, w, h, iso(2.85, 0.0));
    // 前景灌木(草块前景角,避开中央花畦)。
    _isoBush(canvas, w, iso(-0.55, 3.1));
    _isoBush(canvas, w, iso(3.1, -0.55));
  }

  /// 菱形地块:顶面 + 左立面 + 右立面(厚度),土壤块换土壤色;
  /// 相邻同色块间留 0.08 缝隙,土壤块棋盘微调避免融合。
  void _isoTile(
    Canvas canvas,
    double w,
    Offset top,
    Offset right,
    Offset bottom,
    Offset left, {
    required bool soil,
    bool checker = false,
  }) {
    final depth = 0.022 * w;
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
    canvas.drawPath(faceL, Paint()..color = soil ? _soilSideL : _grassSideL);
    canvas.drawPath(faceR, Paint()..color = soil ? _soilSideR : _grassSideR);
    final topFace = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()
        ..color = soil
            ? (checker ? _soilTop : Color.lerp(_soilTop, _soilSideL, 0.25)!)
            : (checker ? _grassLight : _grassShade),
    );
    if (!soil) {
      // 草块上的浅色高光小菱形(固定位置)。
      final cx = (top.dx + bottom.dx) / 2;
      final cy = (top.dy + bottom.dy) / 2;
      canvas.drawCircle(
        Offset(cx, cy),
        0.012 * w,
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
  }

  /// 等距小苗:短茎 + 两片菱形叶。
  void _isoSprout(Canvas canvas, double w, Offset base) {
    final stem = Paint()
      ..color = _leafDeep
      ..strokeWidth = 0.008 * w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base - Offset(0, 0.05 * w), stem);
    final leaf = Paint()..color = _leafMain;
    canvas.drawOval(
      Rect.fromCenter(
        center: base - Offset(0.025 * w, 0.045 * w),
        width: 0.05 * w,
        height: 0.02 * w,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: base - Offset(-0.025 * w, 0.05 * w),
        width: 0.05 * w,
        height: 0.02 * w,
      ),
      leaf,
    );
    canvas.drawCircle(
      base - Offset(0, 0.065 * w),
      0.014 * w,
      Paint()..color = _leafLight,
    );
  }

  /// 等距栅栏:后缘一排立柱(双面) + 连接横档。
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
      for (var c = fromCol; c <= toCol!; c += 0.85) {
        posts.add(iso(c, row!));
      }
    } else {
      for (var r = fromRow!; r <= toRow!; r += 0.85) {
        posts.add(iso(col!, r));
      }
    }
    // 横档(连接相邻柱)。
    for (var i = 0; i < posts.length - 1; i++) {
      final a = posts[i];
      final b = posts[i + 1];
      final rail = Paint()
        ..color = _woodShade
        ..strokeWidth = 0.014 * w
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        a - Offset(0, 0.055 * w),
        b - Offset(0, 0.055 * w),
        rail,
      );
      canvas.drawLine(
        a - Offset(0, 0.03 * w),
        b - Offset(0, 0.03 * w),
        rail..color = _wood,
      );
    }
    // 立柱:圆角小柱 + 右侧阴影面 + 地面长影。
    for (final p in posts) {
      final shadow = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + 0.05 * w, p.dy + 0.018 * w)
        ..lineTo(p.dx + 0.02 * w, p.dy + 0.03 * w)
        ..lineTo(p.dx - 0.01 * w, p.dy + 0.012 * w)
        ..close();
      canvas.drawPath(shadow, Paint()..color = const Color(0x33407050));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(p.dx - 0.011 * w, p.dy - 0.085 * w, 0.022 * w,
              0.085 * w),
          Radius.circular(0.008 * w),
        ),
        Paint()..color = _wood,
      );
      canvas.drawRect(
        Rect.fromLTWH(p.dx + 0.002 * w, p.dy - 0.085 * w, 0.009 * w, 0.085 * w),
        Paint()..color = _woodShade,
      );
    }
  }

  /// 等距树:地面长影 + 树干 + 三球冠(径向渐变)。
  void _isoTree(Canvas canvas, double w, double h, Offset base) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0.03 * w, 0.008 * h),
        width: 0.22 * w,
        height: 0.05 * h,
      ),
      Paint()..color = const Color(0x33407050),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 0.014 * w, base.dy - 0.12 * h, 0.028 * w,
            0.12 * h),
        Radius.circular(0.01 * w),
      ),
      Paint()..color = _trunk,
    );
    _isoBall(canvas, Offset(base.dx, base.dy - 0.16 * h), 0.075 * w, _leafDeep);
    _isoBall(canvas, Offset(base.dx - 0.05 * w, base.dy - 0.12 * h), 0.055 * w,
        _leafMain);
    _isoBall(canvas, Offset(base.dx + 0.05 * w, base.dy - 0.125 * h), 0.05 * w,
        _leafMain);
    _isoBall(canvas, Offset(base.dx - 0.01 * w, base.dy - 0.2 * h), 0.045 * w,
        _leafLight);
  }

  /// 等距灌木:小影 + 双球。
  void _isoBush(Canvas canvas, double w, Offset base) {
    canvas.drawOval(
      Rect.fromCenter(
        center: base + Offset(0.015 * w, 0.006 * w),
        width: 0.14 * w,
        height: 0.03 * w,
      ),
      Paint()..color = const Color(0x33407050),
    );
    _isoBall(canvas, base - Offset(0.02 * w, 0.03 * w), 0.04 * w, _leafMain);
    _isoBall(canvas, base + Offset(0.025 * w, -0.025 * w), 0.03 * w, _leafLight);
  }

  /// 立体球:径向渐变(左上受光)。
  void _isoBall(Canvas canvas, Offset c, double r, Color base) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Color.lerp(base, const Color(0xFFFFFFFF), 0.35)!,
            base,
            Color.lerp(base, const Color(0xFF1E4D3A), 0.25)!,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_IsoGardenPainter oldDelegate) => false;
}
