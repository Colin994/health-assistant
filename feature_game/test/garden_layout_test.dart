import 'package:core_database/core_database.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_game/src/garden/garden_scene_layout.dart';
import 'package:feature_game/src/garden/garden_asset_catalog.dart';
import 'package:feature_game/src/garden/garden_ui_theme.dart';

void main() {
  for (final size in [
    const Size(320, 280),
    const Size(390, 400),
    const Size(844, 390),
    const Size(744, 768),
  ]) {
    test('four visible, accessible plot targets share transform at $size', () {
      final layout = GardenSceneLayout(size);
      for (var i = 0; i < 4; i++) {
        final rect = layout.hitRect(i);
        expect(rect.width, greaterThanOrEqualTo(44));
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(layout.hitTest(rect.center), i);
        expect((Offset.zero & size).contains(rect.center), isTrue);
      }
      final p = GardenSceneLayout.decorationAnchors['gnome']!;
      expect(
        layout.point(p),
        layout.translation + Offset(p.dx * 1024, p.dy * 1488) * layout.scale,
      );
    });
  }
  test('honest stage names at every boundary', () {
    for (final n in [74, 75, 149, 150, 299, 300, 374, 375, 449, 450]) {
      final p = PlotState(species: 'sunflower', invested: n);
      expect(plantStageLabel(p).contains('可收获'), n >= 450);
      if (n >= 375 && n < 450) expect(plantStageLabel(p), '盛开，接近收获');
    }
  });
  test('plant bases stay centred in their own beds across scene cameras', () {
    for (final immersive in [false, true]) {
      for (final size in [
        const Size(320, 640),
        const Size(402, 874),
        const Size(844, 390),
        const Size(744, 768),
      ]) {
        final layout = GardenSceneLayout(size, immersive: immersive);
        for (var i = 0; i < 4; i++) {
          final bed = layout.bedRect(i);
          final plant = layout.plantRect(i);
          final base = plant.bottomCenter;
          expect(base.dx, closeTo(bed.center.dx, .001));
          // The fade/crop must not pull the visible roots towards the back rim.
          expect(base.dy, greaterThan(bed.center.dy + bed.height * .15));
          expect(base.dy, lessThan(bed.center.dy + bed.height * .30));
          expect(layout.hitTest(base), i);
          expect(plant.width, lessThan(bed.width));
        }
      }
    }
  });
  test('all 30 assets have natural-size, nonempty alpha bounds', () {
    for (final seed in seedCatalog) {
      for (var stage = 0; stage < 6; stage++) {
        final m = GardenAssetCatalog.metadata(seed.id, stage);
        expect(m.visibleBounds.isEmpty, isFalse);
        expect(m.visibleBounds.right, lessThanOrEqualTo(m.imageSize.width));
        expect(m.visibleBounds.bottom, lessThanOrEqualTo(m.imageSize.height));
      }
    }
  });
  test('immersive phone camera keeps four plots hittable', () {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(402, 874),
    ]) {
      final layout = GardenSceneLayout(size, immersive: true);
      for (var i = 0; i < 4; i++) {
        final hit = layout.hitRect(i);
        expect(hit.width, greaterThanOrEqualTo(44));
        expect(hit.height, greaterThanOrEqualTo(44));
        expect(layout.hitTest(hit.center), i);
      }
      expect(
        layout.scale * GardenSceneLayout.imageSize.height,
        greaterThanOrEqualTo(size.height),
      );
    }
  });
  test('parchment game text and resource icons retain AA contrast', () {
    for (final background in [GardenUiTheme.wood, GardenUiTheme.woodLight]) {
      expect(
        (GardenUiTheme.paper.computeLuminance() + .05) /
            (background.computeLuminance() + .05),
        greaterThanOrEqualTo(4.5),
      );
    }
    for (final foreground in [
      GardenUiTheme.ink,
      GardenUiTheme.mutedInk,
      GardenUiTheme.leaf,
      GardenUiTheme.sunInk,
    ]) {
      final ratio =
          (GardenUiTheme.paper.computeLuminance() + .05) /
          (foreground.computeLuminance() + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
    expect(
      (GardenUiTheme.honey.computeLuminance() + .05) /
          (GardenUiTheme.ink.computeLuminance() + .05),
      greaterThanOrEqualTo(4.5),
    );
  });
}
