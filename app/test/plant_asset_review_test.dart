import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Run explicitly to export all 30 production sprites on a dark background:
/// flutter test test/plant_asset_review_test.dart --dart-define=EXPORT_PLANT_REVIEW=true
void main() {
  testWidgets(
    'all plant stages decode and composite for visual review',
    (t) async {
      const species = [
        'sunflower',
        'hydrocotyle',
        'cyperus',
        'lavender',
        'rose',
      ];
      const export = bool.fromEnvironment('EXPORT_PLANT_REVIEW');
      if (export && Platform.isMacOS) {
        await t.runAsync(() async {
          final file = File('/System/Library/Fonts/Supplemental/Arial.ttf');
          if (await file.exists()) {
            final loader = FontLoader('PlantReview')
              ..addFont(
                file.readAsBytes().then(ByteData.sublistView),
              );
            await loader.load();
          }
        });
      }
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1440, 1300);
      addTearDown(t.view.reset);
      const key = ValueKey('plant-review');
      await t.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: const Color(0xFF253E2B),
              child: Column(
                children: [
                  for (final name in species)
                    Expanded(
                      child: Row(
                        children: [
                          for (var stage = 0; stage < 6; stage++)
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      'assets/game/plant_iso_${name}_stage$stage.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Text(
                                    '$name / $stage',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: 'PlantReview',
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final context = t.element(find.byKey(key));
      await t.runAsync(() async {
        await Future.wait([
          for (final name in species)
            for (var stage = 0; stage < 6; stage++)
              precacheImage(
                AssetImage('assets/game/plant_iso_${name}_stage$stage.png'),
                context,
              ),
        ]);
      });
      await t.pump();
      expect(find.byType(Image), findsNWidgets(30));
      expect(t.takeException(), isNull);
      if (export) {
        final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await t.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/plant-review.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
