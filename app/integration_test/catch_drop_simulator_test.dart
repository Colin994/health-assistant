import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_database/core_database.dart';
import 'package:core_health/core_health.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/feature_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopPoseStream implements PoseStream {
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final shotKey = GlobalKey();

  Future<void> capture(WidgetTester t, String name) async {
    // Allow image assets & CustomPainter to finish decoding and rasterizing.
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    final boundary =
        shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${Directory.systemTemp.path}/$name.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      debugPrint('SIM_SHOT:$name=${file.path}');
    });
  }

  testWidgets('接阳光 iOS 模拟器全流程视觉走查', (t) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // 1. 花园入口 -> 点击「接阳光」打开局前引导弹窗
    await t.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: ProviderScope(
          overrides: [
            gamePoseStreamProvider.overrideWithValue(_NoopPoseStream()),
            gameEconomyProvider.overrideWithValue(GameEconomyStore()),
            todayStepsProvider.overrideWithValue(const Stream<int>.empty()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const GameScreenRoute(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('接阳光'));
    await t.pumpAndSettle();
    expect(find.text('接阳光 · 40 秒'), findsOneWidget);
    expect(find.textContaining('耳靠向肩'), findsOneWidget);
    expect(find.text('开始练习'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, '01_catch_guide_dialog');

    // 2. 校准页（中立位采集）
    await t.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(
            state: const GameState(
              phase: GamePhase.calibrating,
              kind: GameKind.catchDrop,
              statusText: '正在校准中立位',
            ),
            onIntent: (_) {},
          ),
        ),
      ),
    );
    await t.pump();
    expect(find.textContaining('记录你的舒适中立位'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, '02_catch_calibrating');

    // 3. 游戏中（常规阳光 + 枫木托盘 + 晴朗草地 + 底部单槽引导）
    final normalSnap = CatchDropSnapshot(
      phase: CatchDropPhase.playing,
      containerX: 0.48,
      elapsed: const Duration(seconds: 8),
      score: 15,
      caughtNormal: 3,
      caughtGolden: 0,
      activeDrops: const [
        Drop(
          id: 1,
          kind: DropKind.normal,
          x: 0.34,
          spawnedAt: Duration(seconds: 5),
          fallDuration: Duration(milliseconds: 5200),
        ),
        Drop(
          id: 2,
          kind: DropKind.normal,
          x: 0.68,
          spawnedAt: Duration(seconds: 7),
          fallDuration: Duration(milliseconds: 5200),
        ),
      ],
      goldenChargeProgress: 0,
      goldenCharging: false,
      canFinishEarly: false,
      goldenPresent: false,
      goldenSide: 0,
      combo: 3,
    );
    await t.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(
            state: GameState(
              phase: GamePhase.playing,
              kind: GameKind.catchDrop,
              catchSnapshot: normalSnap,
              statusText: '耳靠向肩轻轻侧头，移托盘接住阳光',
            ),
            onIntent: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('剩余 32s'), findsOneWidget);
    expect(find.text('15 分'), findsOneWidget);
    expect(find.text('3 连击 ×1.2'), findsOneWidget);
    expect(find.text('耳靠向肩轻轻侧头，移托盘接住阳光'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, '03_catch_playing_normal');

    // 4. 游戏中（大金阳光左侧充能 + 余光边缘光带 + 45分提前完成按钮）
    final goldenSnap = CatchDropSnapshot(
      phase: CatchDropPhase.playing,
      containerX: 0.22,
      elapsed: const Duration(seconds: 26),
      score: 45,
      caughtNormal: 4,
      caughtGolden: 1,
      activeDrops: const [
        Drop(
          id: 3,
          kind: DropKind.golden,
          x: 0.22,
          spawnedAt: Duration(seconds: 24),
          fallDuration: Duration(milliseconds: 6200),
        ),
      ],
      goldenChargeProgress: 0.64,
      goldenCharging: true,
      canFinishEarly: true,
      goldenPresent: true,
      goldenSide: -1,
      goldenAligned: true,
      goldenTiltOk: true,
    );
    await t.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(
            state: GameState(
              phase: GamePhase.playing,
              kind: GameKind.catchDrop,
              catchSnapshot: goldenSnap,
              statusText: '慢呼气 · 向左保持舒展 64%',
            ),
            onIntent: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('提前完成'), findsOneWidget);
    expect(find.text('慢呼气 · 向左保持舒展 64%'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, '04_catch_playing_golden');

    // 5. 结算页（暖纸结算卡 + 体态自查 + 返回花园）
    await t.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(
            state: GameState(
              phase: GamePhase.result,
              kind: GameKind.catchDrop,
              catchSnapshot: goldenSnap,
              resultScore: 70,
              resultElapsedSeconds: 40,
              resultCaughtNormal: 4,
              resultCaughtGolden: 2,
              resultSunshine: 22,
            ),
            onIntent: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('获得 22 阳光'), findsOneWidget);
    expect(find.textContaining('左右颈侧有没有松一点'), findsOneWidget);
    expect(find.text('返回花园'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, '05_catch_result');

    await t.pumpWidget(const SizedBox.shrink());
  });
}
