import 'dart:convert';
import 'dart:io';

import 'package:core_database/core_database.dart';
import 'package:core_health/core_health.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/feature_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Pose implements PoseStream {
  @override
  Stream<PoseSample> get poses => const Stream.empty();
  @override
  Stream<PoseEvent> get events => const Stream.empty();
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> calibrate({Duration hold = const Duration(seconds: 2)}) async {}
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final dark in [false, true]) {
    testWidgets('simulator plant panel ${dark ? 'dark' : 'light'}', (t) async {
      SharedPreferences.setMockInitialValues({
        'l4_game_economy': jsonEncode({
          'sunshineTotal': 120,
          'plots': [
            {'species': 'sunflower', 'invested': 150},
            null,
            null,
            null,
          ],
        }),
      });
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            gamePoseStreamProvider.overrideWithValue(_Pose()),
            gameEconomyProvider.overrideWithValue(GameEconomyStore()),
            todayStepsProvider.overrideWithValue(const Stream<int>.empty()),
          ],
          child: MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: const GameScreenRoute(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tapAt(t.getCenter(find.byKey(const ValueKey('plot-0'))));
      await t.pumpAndSettle();
      expect(find.text('向日葵 · 成长'), findsOneWidget);
      expect(find.text('投入 30 阳光'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('garden-panel-surface')),
        findsOneWidget,
      );
      await t.runAsync(() async {
        final name = dark ? 'garden-panel-dark.png' : 'garden-panel-light.png';
        final bytes = await binding.takeScreenshot(name);
        await File('${Directory.systemTemp.path}/$name').writeAsBytes(bytes);
      });
      await t.tap(find.byTooltip('关闭'));
      await t.pumpAndSettle();
      expect(find.text('接阳光'), findsOneWidget);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
