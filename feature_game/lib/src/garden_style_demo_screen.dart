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
                  'B 2.5D 等距(位图版):edit_iso B 锚点四时段 AI 生成图,顶部可切换时段',
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

// ============ 风格 B:2.5D 等距花园(位图资产版,锚点 edit_iso B) ============

class _IsoGardenScene extends StatefulWidget {
  const _IsoGardenScene();

  @override
  State<_IsoGardenScene> createState() => _IsoGardenSceneState();
}

/// 位图资产版(3D 渲染生动度远超手绘近似):四时段 AI 生成图直接铺底,
/// 经 Qwen-Image-Edit 以 [锚点图] 逐时段指令编辑产出,构图完全一致。
class _IsoGardenSceneState extends State<_IsoGardenScene> {
  var _period = _IsoPeriod.noon;

  static const _assets = {
    _IsoPeriod.morning: 'assets/game/demo_iso_morning.png',
    _IsoPeriod.noon: 'assets/game/demo_iso_noon.png',
    _IsoPeriod.dusk: 'assets/game/demo_iso_dusk.png',
    _IsoPeriod.night: 'assets/game/demo_iso_night.png',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: SegmentedButton<_IsoPeriod>(
            segments: const [
              ButtonSegment(value: _IsoPeriod.morning, label: Text('晨')),
              ButtonSegment(value: _IsoPeriod.noon, label: Text('午')),
              ButtonSegment(value: _IsoPeriod.dusk, label: Text('暮')),
              ButtonSegment(value: _IsoPeriod.night, label: Text('夜')),
            ],
            selected: {_period},
            onSelectionChanged: (selection) =>
                setState(() => _period = selection.first),
            showSelectedIcon: false,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Image.asset(
              _assets[_period]!,
              key: ValueKey(_period),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ],
    );
  }
}

enum _IsoPeriod { morning, noon, dusk, night }
