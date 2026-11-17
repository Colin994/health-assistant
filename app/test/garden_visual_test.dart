import 'dart:io' show Platform;
import 'package:core_database/core_database.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/src/game_screen.dart';
import 'package:feature_game/src/game_state.dart';
import 'package:feature_game/src/garden_scene.dart';
import 'package:feature_game/src/garden/garden_asset_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final variants = <String, GameState>{
    'empty': const GameState(gardenTime: GardenTimeOfDay.morning),
    'growth': const GameState(
      gardenTime: GardenTimeOfDay.noon,
      todaySunshineTotal: 120,
      plots: [
        PlotState(species: 'sunflower', invested: 0),
        PlotState(species: 'hydrocotyle', invested: 75),
        PlotState(species: 'lavender', invested: 225),
        PlotState(species: 'rose', invested: 375),
      ],
    ),
    'decorations': GameState(
      gardenTime: GardenTimeOfDay.dusk,
      decorations: [for (final d in decorationCatalog) d.id],
    ),
    'harvest': const GameState(
      gardenTime: GardenTimeOfDay.night,
      starGazeUnlocked: true,
      plots: [
        PlotState(species: 'sunflower', invested: 450),
        null,
        null,
        null,
      ],
    ),
  };
  for (final e in variants.entries) {
    testWidgets('production isometric scene ${e.key}', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(390, 844);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('golden'),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: GameScreen(state: e.value, onIntent: (_) {}),
          ),
        ),
      );
      final context = t.element(find.byType(GameScreen));
      await t.runAsync(() async {
        await Future.wait([
          precacheImage(
            AssetImage(GardenAssetCatalog.scene(e.value.gardenTime)),
            context,
          ),
          for (final plot in e.value.plots)
            if (plot != null)
              precacheImage(
                AssetImage(GardenAssetCatalog.plant(plot.species, plot.stage)),
                context,
              ),
          for (final d in e.value.decorations)
            precacheImage(
              AssetImage(GardenAssetCatalog.decoration(d)),
              context,
            ),
        ]);
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('goldens/garden_iso_${e.key}.png'),
      );
      expect(t.takeException(), isNull);
    }, skip: !Platform.isMacOS);
  }
  testWidgets('every production asset exists and decodes', (t) async {
    final paths = [
      ...kGardenIsoAssets.values,
      for (final seed in seedCatalog)
        for (var stage = 0; stage < 6; stage++)
          GardenAssetCatalog.plant(seed.id, stage),
      for (final d in decorationCatalog) GardenAssetCatalog.decoration(d.id),
    ];
    await t.runAsync(() async {
      for (final path in paths) {
        final bytes = await rootBundle.load(path);
        final image = await decodeImageFromList(bytes.buffer.asUint8List());
        expect(image.width, greaterThan(0));
        expect(image.height, greaterThan(0));
        image.dispose();
      }
    });
    expect(paths.length, 42);
  });
}
