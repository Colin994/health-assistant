import 'package:flutter/material.dart';

/// 花园时段(《游戏美术资产生产指南》§2 场景四时段:同构图,仅天空与光线变化)。
enum GardenTimeOfDay {
  /// 晨:薄荷浅调。
  morning,

  /// 午:亮白。
  noon,

  /// 暮:柠檬暖调。
  dusk,

  /// 夜:墨绿炭天 + 星点。
  night;

  /// 由本地时钟解析时段(纯函数,便于测试):
  /// 5–9 点晨 / 10–15 点午 / 16–18 点暮 / 其余夜。
  static GardenTimeOfDay fromClock(DateTime now) {
    return switch (now.hour) {
      >= 5 && <= 9 => GardenTimeOfDay.morning,
      >= 10 && <= 15 => GardenTimeOfDay.noon,
      >= 16 && <= 18 => GardenTimeOfDay.dusk,
      _ => GardenTimeOfDay.night,
    };
  }
}

/// 林边小院水粉四时段底图（同机位无植物/无装饰干净母版，运行时叠加植物与装饰）。
const Map<GardenTimeOfDay, String> kGardenIsoAssets = {
  GardenTimeOfDay.morning: 'assets/game/garden_woodland_morning.jpg',
  GardenTimeOfDay.noon: 'assets/game/garden_woodland_noon.jpg',
  GardenTimeOfDay.dusk: 'assets/game/garden_woodland_dusk.jpg',
  GardenTimeOfDay.night: 'assets/game/garden_woodland_night.jpg',
};

/// 林边小院底图原始像素尺寸（与四时段资产一一对应，cover 映射用）。
const Size kGardenIsoImageSize = Size(768, 1376);

/// 宽窗收窄世界后，用于两侧延展的边缘色。
///
/// 取四时段母版左右外沿（宽 3.5%）自上而下九等分带的平均色，
/// 与紧邻的画面边缘同源，使两侧读起来是同一张画面的延续。
/// 外层下标 0 = 左沿、1 = 右沿；每层九色按 [kGardenEdgeBandStops] 定位。
const Map<GardenTimeOfDay, List<List<Color>>> kGardenEdgeBands = {
  GardenTimeOfDay.morning: [
    [
      Color(0xFF6B6B50),
      Color(0xFF5B5E37),
      Color(0xFF787844),
      Color(0xFF54623C),
      Color(0xFF536033),
      Color(0xFF727D3F),
      Color(0xFF667239),
      Color(0xFF4C5A2F),
      Color(0xFF4A5435),
    ],
    [
      Color(0xFF5E593F),
      Color(0xFF7D7050),
      Color(0xFF746F52),
      Color(0xFF63644E),
      Color(0xFF63634A),
      Color(0xFF6D783B),
      Color(0xFF757C39),
      Color(0xFF6C743A),
      Color(0xFF3F4E32),
    ],
  ],
  GardenTimeOfDay.noon: [
    [
      Color(0xFF61694C),
      Color(0xFF4F5829),
      Color(0xFF717A39),
      Color(0xFF435F30),
      Color(0xFF435F27),
      Color(0xFF698536),
      Color(0xFF5A7830),
      Color(0xFF3A5723),
      Color(0xFF374D2A),
    ],
    [
      Color(0xFF4D5339),
      Color(0xFF70714C),
      Color(0xFF686E4D),
      Color(0xFF545F49),
      Color(0xFF54634B),
      Color(0xFF608030),
      Color(0xFF6D872E),
      Color(0xFF607A2E),
      Color(0xFF264426),
    ],
  ],
  GardenTimeOfDay.dusk: [
    [
      Color(0xFF4A3E38),
      Color(0xFF3A3224),
      Color(0xFF50432E),
      Color(0xFF37362B),
      Color(0xFF343325),
      Color(0xFF4B452F),
      Color(0xFF403E2C),
      Color(0xFF2D2D23),
      Color(0xFF292825),
    ],
    [
      Color(0xFF44352F),
      Color(0xFF664A3D),
      Color(0xFF674E41),
      Color(0xFF5B473E),
      Color(0xFF584539),
      Color(0xFF47432D),
      Color(0xFF50472C),
      Color(0xFF49402B),
      Color(0xFF242623),
    ],
  ],
  GardenTimeOfDay.night: [
    [
      Color(0xFF35484D),
      Color(0xFF364337),
      Color(0xFF4B5A46),
      Color(0xFF2C463E),
      Color(0xFF2A4437),
      Color(0xFF3E5B45),
      Color(0xFF345140),
      Color(0xFF233C32),
      Color(0xFF203736),
    ],
    [
      Color(0xFF243135),
      Color(0xFF34454D),
      Color(0xFF445457),
      Color(0xFF4A5654),
      Color(0xFF3F4F4F),
      Color(0xFF365341),
      Color(0xFF3B5640),
      Color(0xFF37513E),
      Color(0xFF193331),
    ],
  ],
};

/// 边缘色带的中心位置（母版高度归一化，自上而下）。
const List<double> kGardenEdgeBandStops = [
  1 / 18,
  3 / 18,
  5 / 18,
  7 / 18,
  9 / 18,
  11 / 18,
  13 / 18,
  15 / 18,
  17 / 18,
];

/// 看星星夜空位图（`star_backdrop.png`）的原始像素尺寸。
const Size kStarNightImageSize = Size(1024, 1488);

/// 夜空位图左右外沿的边缘色，取法与 [kGardenEdgeBands] 相同：
/// 外层下标 0 = 左沿、1 = 右沿，每层九色按 [kGardenEdgeBandStops] 定位。
const List<List<Color>> kStarNightEdgeBands = [
  [
    Color(0xFF174F54),
    Color(0xFF184E54),
    Color(0xFF0F3D44),
    Color(0xFF0D3A43),
    Color(0xFF0C363E),
    Color(0xFF082327),
    Color(0xFF0D333D),
    Color(0xFF021620),
    Color(0xFF031321),
  ],
  [
    Color(0xFF103A3F),
    Color(0xFF0F3A3F),
    Color(0xFF103B40),
    Color(0xFF0F3B41),
    Color(0xFF103B40),
    Color(0xFF0E343A),
    Color(0xFF10373E),
    Color(0xFF082A30),
    Color(0xFF0F2534),
  ],
];

/// 花园 iso 场景背景:AI 生成位图(edit_iso B 锚点四时段),cover 铺底 +
/// 顶部轻 scrim 保证状态行文字可读。进入时预热全部时段,切换零延迟。
class GardenIsoBackdrop extends StatefulWidget {
  const GardenIsoBackdrop({required this.timeOfDay, super.key});

  final GardenTimeOfDay timeOfDay;

  @override
  State<GardenIsoBackdrop> createState() => _GardenIsoBackdropState();
}

class _GardenIsoBackdropState extends State<GardenIsoBackdrop> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in kGardenIsoAssets.values) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          kGardenIsoAssets[widget.timeOfDay]!,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // 顶部 scrim:晨/暮亮丘陵上压暗 8%,状态行深字保底可读。
        const Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x14000000), Color(0x00000000)],
              ),
            ),
            child: SizedBox(height: 96, width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// iso 场景 cover 映射数学:把图内归一化坐标换算到全屏坐标。
///
/// BoxFit.cover 取 scale = max(屏宽/图宽, 屏高/图高) 并居中裁切;
/// 花畦锚点定位必须与该数学一致,否则不同屏比下错位。
class GardenIsoMetrics {
  const GardenIsoMetrics({
    required this.screenSize,
    this.imageSize = kGardenIsoImageSize,
  });

  final Size screenSize;
  final Size imageSize;

  /// cover 缩放系数。
  double get scale {
    final sx = screenSize.width / imageSize.width;
    final sy = screenSize.height / imageSize.height;
    return sx > sy ? sx : sy;
  }

  /// 图内容左上角在屏幕上的偏移(居中裁切,可为负)。
  Offset get topLeft {
    final dx = (screenSize.width - imageSize.width * scale) / 2;
    final dy = (screenSize.height - imageSize.height * scale) / 2;
    return Offset(dx, dy);
  }

  /// 图内归一化点 (nx, ny) → 全屏坐标。
  Offset point(double nx, double ny) =>
      topLeft + Offset(nx * imageSize.width, ny * imageSize.height) * scale;

  /// 图内归一化矩形(中心+宽高) → 全屏 Rect。
  Rect rect(Offset center, Size normalizedSize) {
    final c = point(center.dx, center.dy);
    final halfW = normalizedSize.width * imageSize.width * scale / 2;
    final halfH = normalizedSize.height * imageSize.height * scale / 2;
    return Rect.fromCenter(center: c, width: halfW * 2, height: halfH * 2);
  }
}

/// 花园场景背景:程序化矢量五层构图(替代位图 scene_*.png 占位)。
///
/// 草地/花畦土壤/栅栏/灌木/树冠全部圆角扁平色块,无渐变无描边;
/// 色值取自《游戏美术资产生产指南》§2 色板,时段变化走同色相
/// 明度阶梯(罩色),不引入新色相。植物立绘/装饰/道具仍用位图资产。
class GardenScene extends StatelessWidget {
  const GardenScene({required this.timeOfDay, super.key});

  final GardenTimeOfDay timeOfDay;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GardenScenePainter(timeOfDay),
      size: Size.infinite,
      isComplex: true,
    );
  }

  /// 天空区主文字色(夜空转白,其余用墨绿炭 token 值)。
  ///
  /// 花园顶部状态文字直接叠在天空上,固定深色在夜景不可读。
  static Color skyTextPrimary(GardenTimeOfDay timeOfDay) =>
      timeOfDay == GardenTimeOfDay.night
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF28332F);

  /// 天空区次级文字色(夜空转浅白,其余用绿灰 token 值)。
  static Color skyTextSecondary(GardenTimeOfDay timeOfDay) =>
      timeOfDay == GardenTimeOfDay.night
          ? const Color(0xFFFFFFFF).withValues(alpha: 0.72)
          : const Color(0xFF5A625F);
}

class _GardenScenePainter extends CustomPainter {
  _GardenScenePainter(this.timeOfDay);

  final GardenTimeOfDay timeOfDay;

  // 色板(docs/游戏美术资产生产指南.md §2)。
  static const Color _green = Color(0xFF27C3B0); // 主绿
  static const Color _greenDeep = Color(0xFF1E9C8C); // 主色深阶
  static const Color _greenPale = Color(0xFFA9E6DD); // 主色浅阶
  static const Color _mintPot = Color(0xFFD7EBD9); // 盆身浅薄荷
  static const Color _ink = Color(0xFF28332F); // 墨绿炭(夜景天)
  static const Color _lemon = Color(0xFFFCFF7D); // 柠檬黄
  static const Color _terracotta = Color(0xFFB57F62); // 陶土棕深阶
  static const Color _soil = Color(0xFF7A5C48); // 土壤棕
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFFAFAFA);

  /// 夜空星点(归一化坐标,固定位置;只占天空区)。
  static const List<double> _stars = [
    0.10, 0.08, 0.28, 0.05, 0.48, 0.13, 0.66, 0.04, 0.86, 0.15, //
    0.20, 0.22, 0.56, 0.26, 0.76, 0.20, 0.40, 0.17, 0.92, 0.30,
  ];

  Color get _skyColor => switch (timeOfDay) {
        GardenTimeOfDay.morning => _greenPale,
        GardenTimeOfDay.noon => _white,
        GardenTimeOfDay.dusk => _lemon,
        GardenTimeOfDay.night => _ink,
      };

  /// 时段罩:同色相明度阶梯(午间无罩),统一压暗/暖化场景。
  double get _veilAlpha => switch (timeOfDay) {
        GardenTimeOfDay.morning => 0.15,
        GardenTimeOfDay.noon => 0,
        GardenTimeOfDay.dusk => 0.20,
        GardenTimeOfDay.night => 0.45,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1 天空。
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _skyColor,
    );

    // 2 树冠(顶部两角)。
    _canopy(canvas, w, h, left: true);
    _canopy(canvas, w, h, left: false);

    // 3 灌木绿篱(栅栏后)。
    _hedge(canvas, w, h);

    // 4 草地(先铺,栅栏桩衬其上才可见)。
    _lawn(canvas, w, h);

    // 5 栅栏。
    _fence(canvas, w, h);

    // 6 花畦。
    _bed(canvas, w, h, const Rect.fromLTWH(0.06, 0.72, 0.30, 0.12));
    _bed(
      canvas,
      w,
      h,
      const Rect.fromLTWH(0.64, 0.72, 0.30, 0.12),
      flower: true,
    );

    // 7 时段罩(晨雾/暮色/夜幕)。
    if (_veilAlpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = _skyColor.withValues(alpha: _veilAlpha),
      );
    }

    // 7 夜空星点(罩后绘制,保持亮度)。
    if (timeOfDay == GardenTimeOfDay.night) {
      for (var i = 0; i < _stars.length; i += 2) {
        final bright = i ~/ 2 % 3 == 0;
        canvas.drawCircle(
          Offset(_stars[i] * w, _stars[i + 1] * h),
          bright ? 2.4 : 1.4,
          Paint()
            ..color = _lemon.withValues(alpha: bright ? 0.9 : 0.55),
        );
      }
    }
  }

  /// 树冠:圆簇(深阶底 + 主色团 + 浅阶高光)+ 陶土色圆头枝干。
  void _canopy(Canvas canvas, double w, double h, {required bool left}) {
    final cx = (left ? 0.09 : 0.91) * w;
    final cy = (left ? 0.05 : 0.09) * h;
    final trunk = Paint()
      ..color = _terracotta
      ..strokeWidth = 0.032 * w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset((left ? 0.005 : 0.995) * w, -0.02 * h),
      Offset(cx + (left ? 0.01 : -0.01) * w, 0.17 * h),
      trunk,
    );
    final base = Paint()..color = _greenDeep;
    final mid = Paint()..color = _green;
    final hi = Paint()..color = _greenPale;
    canvas.drawCircle(Offset(cx, cy), 0.16 * w, base);
    canvas.drawCircle(
      Offset(cx + (left ? -0.06 : 0.06) * w, cy + 0.05 * h),
      0.10 * w,
      mid,
    );
    canvas.drawCircle(
      Offset(cx + (left ? 0.07 : -0.07) * w, cy - 0.01 * h),
      0.075 * w,
      mid,
    );
    canvas.drawCircle(
      Offset(cx + (left ? -0.02 : 0.02) * w, cy + 0.01 * h),
      0.032 * w,
      hi,
    );
    canvas.drawCircle(
      Offset(cx + (left ? 0.09 : -0.09) * w, cy + 0.055 * h),
      0.024 * w,
      hi,
    );
  }

  /// 灌木绿篱:深阶底带 + 一排主色圆。
  void _hedge(Canvas canvas, double w, double h) {
    final y = 0.44 * h;
    canvas.drawRect(
      Rect.fromLTWH(0, y, w, 0.055 * h),
      Paint()..color = _greenDeep,
    );
    final bush = Paint()..color = _green;
    final r = 0.042 * h;
    for (double x = -0.02 * w; x < 1.05 * w; x += 0.055 * w) {
      canvas.drawCircle(Offset(x, y), r, bush);
    }
  }

  /// 栅栏:浅白横档两条 + 圆顶白尖桩。
  void _fence(Canvas canvas, double w, double h) {
    final top = 0.45 * h;
    final bottom = 0.585 * h;
    final rail = Paint()..color = _surface;
    canvas.drawRect(
      Rect.fromLTWH(0, top + 0.02 * h, w, 0.016 * h),
      rail,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, bottom - 0.05 * h, w, 0.016 * h),
      rail,
    );
    final picket = Paint()..color = _white;
    final pw = 0.042 * w;
    final topRadius = Radius.circular(pw / 2);
    for (double x = 0.012 * w; x < w; x += 0.075 * w) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, top, pw, bottom - top),
          topLeft: topRadius,
          topRight: topRadius,
        ),
        picket,
      );
    }
  }

  /// 草地:浅薄荷底 + 主色草缘 + 浅阶草斑。
  ///
  /// 上缘贴绿篱底带,让白尖桩整段衬在绿篱/草地上(白桩在白天
  /// /白天空上不可见)。
  void _lawn(Canvas canvas, double w, double h) {
    final top = 0.50 * h;
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, h - top),
      Paint()..color = _mintPot,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, top, w, 0.016 * h),
      Paint()..color = _green,
    );
    final patch = Paint()..color = _greenPale;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.20 * w, 0.90 * h),
        width: 0.16 * w,
        height: 0.035 * h,
      ),
      patch,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.78 * w, 0.94 * h),
        width: 0.20 * w,
        height: 0.032 * h,
      ),
      patch,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.50 * w, 0.97 * h),
        width: 0.14 * w,
        height: 0.028 * h,
      ),
      patch,
    );
  }

  /// 花畦:白沿圆角池 + 土壤棕 + 小苗(柠檬花心为花)。
  void _bed(Canvas canvas, double w, double h, Rect frame,
      {bool flower = false}) {
    final rim = Rect.fromLTWH(
      frame.left * w,
      frame.top * h,
      frame.width * w,
      frame.height * h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rim, Radius.circular(0.035 * w)),
      Paint()..color = _white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rim.deflate(0.012 * w),
        Radius.circular(0.024 * w),
      ),
      Paint()..color = _soil,
    );
    final cx = rim.center.dx;
    final cy = rim.center.dy;
    final stem = Paint()
      ..color = _greenDeep
      ..strokeWidth = 0.006 * w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy + 0.012 * h),
      Offset(cx, cy - 0.032 * h),
      stem,
    );
    final leaf = Paint()..color = _green;
    canvas.drawCircle(Offset(cx - 0.017 * w, cy - 0.024 * h), 0.013 * w, leaf);
    canvas.drawCircle(Offset(cx + 0.017 * w, cy - 0.024 * h), 0.013 * w, leaf);
    canvas.drawCircle(
      Offset(cx, cy - 0.042 * h),
      0.012 * w,
      Paint()..color = flower ? _lemon : _green,
    );
  }

  @override
  bool shouldRepaint(_GardenScenePainter oldDelegate) =>
      oldDelegate.timeOfDay != timeOfDay;
}
