import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:core_database/core_database.dart';
import 'package:core_health/core_health.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_game/src/catch_drop/catch_drop_board.dart';
import 'package:feature_game/src/garden/garden_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future<void> pumpGarden(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1,
  int invested = 150,
  int sunshine = 120,
  int stardust = 110,
  bool dark = false,
  bool reduce = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'l4_game_economy': jsonEncode({
      'sunshineTotal': sunshine,
      'stardustTotal': stardust,
      'harvestedCount': invested == 0 ? 0 : 2,
      'harvestCounts': {'sunflower': 2},
      'plots': [
        {'species': 'sunflower', 'invested': invested},
        null,
        null,
        null,
      ],
    }),
  });
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        gamePoseStreamProvider.overrideWithValue(_Pose()),
        gameEconomyProvider.overrideWithValue(GameEconomyStore()),
        todayStepsProvider.overrideWithValue(const Stream<int>.empty()),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            boldText: scale > 1,
            disableAnimations: reduce,
          ),
          child: child!,
        ),
        home: const GameScreenRoute(),
      ),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> openPlant(WidgetTester t) async {
  await t.ensureVisible(find.byKey(const ValueKey('plot-0')));
  await t.tapAt(t.getCenter(find.byKey(const ValueKey('plot-0'))));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final scale in [1.0, 2.0, 3.2]) {
    testWidgets('resources right-align without forced equal widths at $scale', (
      t,
    ) async {
      await pumpGarden(t, sunshine: 12, stardust: 110, scale: scale);
      final sun = t.getRect(find.byKey(const ValueKey('resource-sunshine')));
      final star = t.getRect(find.byKey(const ValueKey('resource-stardust')));
      expect(sun.right, closeTo(star.right, .01));
      expect(sun.height, closeTo(star.height, .01));
      expect((sun.width - star.width).abs(), greaterThan(1));
      for (final resource in ['sunshine', 'stardust']) {
        final card = find.byKey(ValueKey('resource-$resource'));
        final icon = t.getCenter(
          find.descendant(of: card, matching: find.byType(Icon)),
        );
        final value = t.getCenter(
          find.descendant(of: card, matching: find.byType(Text)),
        );
        expect(icon.dy, closeTo(value.dy, .01));
      }
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('resources sit below exit and title keeps the selected angle', (
    t,
  ) async {
    await pumpGarden(t);
    final exit = t.getRect(find.byKey(const ValueKey('garden-exit')));
    final sunshine = t.getRect(find.byKey(const ValueKey('resource-sunshine')));
    expect(sunshine.top, closeTo(exit.bottom + 12, .01));
    expect(sunshine.right, closeTo(exit.right - 4, .01));

    final rotation = t.widget<Transform>(
      find.byKey(const ValueKey('garden-title-rotation')),
    );
    final angle = math.atan2(
      rotation.transform.storage[1],
      rotation.transform.storage[0],
    );
    expect(angle, closeTo(-3 * math.pi / 180, 1e-9));
    expect(t.takeException(), isNull);
  });
  testWidgets('exit button pops the garden route', (t) async {
    await pumpGarden(t);
    final context = t.element(find.byType(GameScreen));
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const GameScreenRoute())),
    );
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('退出'));
    await t.pumpAndSettle();
    expect(find.byType(GameScreenRoute), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('resource chips explain balances and close cleanly', (t) async {
    await pumpGarden(t);
    for (final resource in ['sunshine', 'stardust']) {
      await t.tap(find.byKey(ValueKey('resource-$resource')));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('当前余额'), findsOneWidget);
      await t.tap(find.text('知道了'));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    }
  });
  testWidgets('locked garden hides only an empty stardust balance', (t) async {
    await pumpGarden(t, invested: 0, stardust: 0);
    expect(find.byKey(const ValueKey('resource-stardust')), findsNothing);
    expect(find.text('看星星'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
    await pumpGarden(t, invested: 0, stardust: 7);
    expect(find.byKey(const ValueKey('resource-stardust')), findsOneWidget);
  });
  testWidgets('practice prompts prevent repeated entry and respect cancel', (
    t,
  ) async {
    await pumpGarden(t);
    for (final label in ['接阳光', '看星星']) {
      await t.ensureVisible(find.text(label));
      final onTap = t
          .widget<InkWell>(
            find
                .ancestor(of: find.text(label), matching: find.byType(InkWell))
                .first,
          )
          .onTap!;
      onTap();
      onTap();
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('$label · 40 秒'), findsOneWidget);
      await t.tap(find.text('先不练'));
      await t.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    }
  });
  testWidgets('exhausted practice explains rest without entering camera', (
    t,
  ) async {
    final intents = <GameIntent>[];
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(
          state: const GameState(quotaRemaining: 0, starGazeUnlocked: true),
          onIntent: intents.add,
        ),
      ),
    );
    for (final label in ['接阳光', '看星星']) {
      await t.ensureVisible(find.text(label));
      await t.tap(find.text(label));
      await t.pumpAndSettle();
      expect(find.text('今天的练习次数已用完'), findsOneWidget);
      expect(find.text('开始练习'), findsNothing);
      await t.tap(find.text('知道了'));
      await t.pumpAndSettle();
    }
    expect(intents, isEmpty);
  });
  testWidgets('herbarium opens and its close button returns to garden', (
    t,
  ) async {
    await pumpGarden(t);
    await t.ensureVisible(find.text('押花册'));
    await t.tap(find.text('押花册'));
    await t.pumpAndSettle();
    expect(find.byType(GardenPanelRoute), findsOneWidget);
    await t.tap(find.byTooltip('关闭'));
    await t.pumpAndSettle();
    expect(find.byType(GardenPanelRoute), findsNothing);
    expect(find.text('接阳光'), findsOneWidget);
  });
  testWidgets('plant sheet subscribes to commits without reopen', (t) async {
    await pumpGarden(t);
    await openPlant(t);
    expect(find.text('全程累计 150 / 450 阳光'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('invest')));
    await t.tap(find.byKey(const ValueKey('invest')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('全程累计 180 / 450 阳光'), findsOneWidget);
    expect(find.text('可用阳光 90'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  for (final dark in [false, true]) {
    for (final size in [const Size(320, 568), const Size(844, 390)]) {
      testWidgets('plant panel remains scrollable at 3.2x $size dark=$dark', (
        t,
      ) async {
        await pumpGarden(t, size: size, scale: 3.2, dark: dark);
        await openPlant(t);
        expect(find.text('向日葵 · 成长'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('garden-panel-surface')),
          findsOneWidget,
        );
        await t.ensureVisible(find.byKey(const ValueKey('invest')));
        expect(
          t.getRect(find.byKey(const ValueKey('invest'))).height,
          greaterThanOrEqualTo(44),
        );
        expect(t.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'actual small balance is shown; final investment switches to harvest',
    (t) async {
      await pumpGarden(t, invested: 440, sunshine: 12);
      await openPlant(t);
      expect(find.text('投入 10 阳光'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('invest')));
      await t.tap(find.byKey(const ValueKey('invest')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('向日葵 · 可收获'), findsOneWidget);
      expect(find.text('收获并收入押花册'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('harvest')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(GardenPanelRoute), findsNothing);
      expect(find.text('已收入押花册'), findsOneWidget);
      expect(find.textContaining('累计收获 3 次'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('shop balance, ownership and seed unlock update in place', (
    t,
  ) async {
    await pumpGarden(t);
    await t.ensureVisible(find.text('商店'));
    await t.tap(find.text('商店'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.ensureVisible(find.byKey(const ValueKey('buy-path')));
    await t.tap(find.byKey(const ValueKey('buy-path')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('已拥有'), findsOneWidget);
    expect(find.text('当前余额 · 阳光 90 · 星屑 110'), findsOneWidget);
    await t.ensureVisible(find.text('兑换玫瑰种子'));
    await t.tap(find.text('兑换玫瑰种子'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('高级种子已全部解锁'), findsOneWidget);
    expect(find.text('当前余额 · 阳光 90 · 星屑 10'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0, 3.2]) {
      testWidgets('garden and seed layout $size scale $scale', (t) async {
        await pumpGarden(t, size: size, scale: scale, reduce: true);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName.startsWith(
                  'assets/game/scene_',
                ),
          ),
          findsOneWidget,
          reason: '背景只绘制一次，避免大字号和横屏出现裁切接缝',
        );
        expect(t.takeException(), isNull);
        await t.ensureVisible(find.byKey(const ValueKey('plot-1')));
        await t.tapAt(t.getCenter(find.byKey(const ValueKey('plot-1'))));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text('选一颗种子'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.ensureVisible(find.byKey(const ValueKey('plant-lavender')));
        await t.tap(find.byKey(const ValueKey('plant-lavender')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        expect(find.byType(GardenPanelRoute), findsNothing);
        expect(t.takeException(), isNull);
      });
    }
  }
  for (final dark in [false, true]) {
    testWidgets('locked stars do not request camera; theme $dark', (t) async {
      await pumpGarden(t, dark: dark, invested: 0);
      await t.ensureVisible(find.text('看星星'));
      await t.tap(find.text('看星星'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('星空还在等你'), findsOneWidget);
      expect(find.textContaining('首株植物盛开'), findsOneWidget);
      expect(find.text('开始练习'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }
  for (final phase in [
    GamePhase.countdown,
    GamePhase.calibrating,
    GamePhase.error,
    GamePhase.paused,
    GamePhase.result,
  ]) {
    testWidgets('session surface $phase scrolls at large text landscape', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(844, 390);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(3.2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: GameScreen(
            state: GameState(
              phase: phase,
              statusText: '调整位置后可以继续练习',
              resultElapsedSeconds: 40,
            ),
            onIntent: (_) {},
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      if (phase == GamePhase.result) {
        await t.ensureVisible(find.text('返回花园'));
        expect(find.text('练习时长 40 秒'), findsOneWidget);
      }
    });
  }
  testWidgets(
    'runtime Reduce Motion cancels basket decoration without changing session',
    (t) async {
      final session = CatchDropSession();
      var reduce = false;
      var sequence = 0;
      late StateSetter update;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: StatefulBuilder(
            builder: (context, set) {
              update = set;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduce),
                child: CatchDropBoard(
                  snapshot: session.snapshot,
                  remainingSeconds: 40,
                  totalSeconds: 40,
                  eventSeq: sequence,
                  events: sequence == 0
                      ? const []
                      : const [
                          DropCaught(
                            kind: DropKind.normal,
                            gained: 5,
                            combo: 1,
                            x: .5,
                          ),
                        ],
                ),
              );
            },
          ),
        ),
      );
      update(() {
        sequence = 1;
      });
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final transforms = find.descendant(
        of: find.byType(CatchDropBoard),
        matching: find.byType(Transform),
      );
      expect(
        t.widget<Transform>(transforms.first).transform.storage[0],
        isNot(1),
      );
      update(() {
        reduce = true;
      });
      await t.pump();
      expect(t.widget<Transform>(transforms.first).transform.storage[0], 1);
      expect(session.score, 0);
      expect(session.elapsed, Duration.zero);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('runtime Reduce Motion removes pressed button scaling', (
    t,
  ) async {
    var reduce = false;
    late StateSetter update;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, set) {
            update = set;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
              child: Center(
                child: GameRoundButton(
                  icon: Icons.close,
                  semanticLabel: '退出',
                  onTap: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
    final gesture = await t.startGesture(
      t.getCenter(find.byType(GameRoundButton)),
    );
    await t.pump();
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .9);
    update(() {
      reduce = true;
    });
    await t.pump();
    expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
    expect(t.takeException(), isNull);
  });
}
