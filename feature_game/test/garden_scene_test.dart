import 'package:feature_game/src/garden_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GardenTimeOfDay.fromClock', () {
    test('5–9 点解析为晨', () {
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 5)),
          GardenTimeOfDay.morning);
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 9)),
          GardenTimeOfDay.morning);
    });

    test('10–15 点解析为午', () {
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 10)),
          GardenTimeOfDay.noon);
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 15)),
          GardenTimeOfDay.noon);
    });

    test('16–18 点解析为暮', () {
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 16)),
          GardenTimeOfDay.dusk);
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 18)),
          GardenTimeOfDay.dusk);
    });

    test('19–4 点解析为夜', () {
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 19)),
          GardenTimeOfDay.night);
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 23)),
          GardenTimeOfDay.night);
      expect(GardenTimeOfDay.fromClock(DateTime(2026, 11, 13, 4)),
          GardenTimeOfDay.night);
    });
  });

  group('GardenScene 四时段渲染', () {
    const variants = {
      GardenTimeOfDay.morning: 'garden_scene_morning',
      GardenTimeOfDay.noon: 'garden_scene_noon',
      GardenTimeOfDay.dusk: 'garden_scene_dusk',
      GardenTimeOfDay.night: 'garden_scene_night',
    };

    testWidgets('每个时段可完整绘制一层场景', (tester) async {
      tester.view.physicalSize = const Size(411, 823);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final entry in variants.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GardenScene(timeOfDay: entry.key),
            ),
          ),
        );
        await expectLater(
          find.byType(GardenScene),
          matchesGoldenFile('goldens/${entry.value}.png'),
        );
      }
    });
  });
}
