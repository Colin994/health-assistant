import 'package:feature_game/src/garden_scene.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GardenIsoMetrics(cover 映射)', () {
    // 图 1024×1488(比例 0.688),屏 360×800dp(比例 0.45,更瘦长)。
    // cover → scale = 800/1488 ≈ 0.5376(高度撑满,左右裁切)。
    const metrics = GardenIsoMetrics(
      screenSize: Size(360, 800),
      imageSize: Size(1024, 1488),
    );

    test('scale 取 max(屏宽/图宽, 屏高/图高)', () {
      expect(metrics.scale, closeTo(800 / 1488, 1e-9));
    });

    test('topLeft 居中裁切:横向负偏移,纵向为 0', () {
      final tl = metrics.topLeft;
      final dispW = 1024 * metrics.scale;
      expect(tl.dy, 0);
      expect(tl.dx, closeTo((360 - dispW) / 2, 1e-9));
      expect(tl.dx, lessThan(0));
    });

    test('point:图内归一化中心 → 屏幕中心线', () {
      final p = metrics.point(0.5, 0.5);
      expect(p.dx, closeTo(180, 1e-9)); // 横向居中
      expect(p.dy, closeTo(400, 1e-9)); // 纵向居中
    });

    test('point:花畦锚点落在屏幕范围内(不越界)', () {
      const beds = [
        (0.51, 0.49),
        (0.255, 0.55),
        (0.74, 0.56),
        (0.50, 0.62),
      ];
      for (final (nx, ny) in beds) {
        final p = metrics.point(nx, ny);
        expect(p.dx, inInclusiveRange(0, 360), reason: 'nx=$nx');
        expect(p.dy, inInclusiveRange(0, 800), reason: 'ny=$ny');
      }
    });

    test('rect:花畦矩形宽高按图比例换算', () {
      final r = metrics.rect(const Offset(0.51, 0.49), const Size(0.30, 0.085));
      expect(r.width, closeTo(0.30 * 1024 * metrics.scale, 1e-9));
      expect(r.height, closeTo(0.085 * 1488 * metrics.scale, 1e-9));
    });

    test('横宽屏(比例更胖时)改为宽度撑满', () {
      const fat = GardenIsoMetrics(
        screenSize: Size(800, 360),
        imageSize: Size(1024, 1488),
      );
      expect(fat.scale, closeTo(800 / 1024, 1e-9));
      expect(fat.topLeft.dy, lessThan(0)); // 纵向裁切
      expect(fat.topLeft.dx, 0);
    });
  });

  group('GardenIsoBackdrop 资产表', () {
    test('四时段资产键齐全且命名规范', () {
      expect(kGardenIsoAssets.length, 4);
      for (final period in GardenTimeOfDay.values) {
        expect(
          kGardenIsoAssets[period],
          'assets/game/scene_${period.name}.png',
          reason: 'scene_${period.name}.png 应与 GardenTimeOfDay.name 对应',
        );
      }
    });

    test('位图尺寸常量与出图规格一致', () {
      expect(kGardenIsoImageSize, const Size(1024, 1488));
    });
  });
}
