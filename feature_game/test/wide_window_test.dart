import 'package:feature_game/src/catch_drop/catch_drop_board.dart';
import 'package:feature_game/src/game_play_area.dart';
import 'package:feature_game/src/garden_scene.dart';
import 'package:feature_game/src/garden/garden_scene_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phones and portrait tablets: the world stays edge to edge.
const _portrait = [
  Size(320, 640),
  Size(390, 844),
  Size(768, 1024),
  Size(820, 1180),
  Size(834, 1194),
  Size(1024, 1366),
  Size(800, 1280),
];

/// Landscape tablets and wide windows: both margins fit a side rail.
const _rails = [
  Size(1024, 768),
  Size(1082, 810),
  Size(1133, 744),
  Size(1180, 820),
  Size(1194, 834),
  Size(1280, 800),
  Size(1366, 1024),
  Size(2000, 600),
];

/// Wide enough to narrow the world, not wide enough to spare two rails.
const _narrowed = [
  Size(840, 700),
  Size(900, 700),
  Size(960, 640),
  Size(1000, 1000),
];

void main() {
  group('GardenStage', () {
    test('phones and portrait tablets stay edge to edge', () {
      for (final size in _portrait) {
        final stage = GardenStage(size);
        expect(stage.worldWidth, size.width, reason: '$size');
        expect(stage.hasRails, isFalse, reason: '$size');
      }
    });

    test('landscape tablets move the actions into side rails', () {
      for (final size in _rails) {
        final stage = GardenStage(size);
        expect(stage.hasRails, isTrue, reason: '$size');
        expect(stage.margin, greaterThanOrEqualTo(GardenStage.railWidth),
            reason: '$size');
        expect(stage.worldWidth, greaterThanOrEqualTo(GardenStage.minWorldWidth),
            reason: '$size');
      }
    });

    test('a window without room for rails narrows the world only', () {
      for (final size in _narrowed) {
        final stage = GardenStage(size);
        expect(stage.worldWidth, lessThan(size.width), reason: '$size');
        expect(stage.hasRails, isFalse, reason: '$size');
      }
    });

    test('narrowing never crops the master or the outer beds', () {
      for (final size in [..._rails, ..._narrowed]) {
        final stage = GardenStage(size);
        final layout = GardenSceneLayout(
          Size(stage.worldWidth, size.height),
          immersive: true,
        );
        // Cover keeps the master at least as wide as the world box.
        expect(
          GardenSceneLayout.imageSize.width * layout.scale,
          greaterThanOrEqualTo(stage.worldWidth - 1e-6),
          reason: '$size',
        );
        final world = Rect.fromLTWH(stage.margin, 0, stage.worldWidth, size.height);
        // The feathered edge is the same 7.5% (24–48px) GardenFramedScene uses.
        final feather = (stage.worldWidth * .075).clamp(24.0, 48.0);
        for (var i = 0; i < 4; i++) {
          final bed = layout.bedRect(i).shift(Offset(stage.margin, 0));
          expect(bed.left - world.left, greaterThanOrEqualTo(feather),
              reason: '$size bed $i');
          expect(world.right - bed.right, greaterThanOrEqualTo(feather),
              reason: '$size bed $i');
          final hit = layout.hitRect(i).shift(Offset(stage.margin, 0));
          expect(hit.width, greaterThanOrEqualTo(44), reason: '$size bed $i');
          expect(hit.height, greaterThanOrEqualTo(44), reason: '$size bed $i');
          expect(layout.hitTest(layout.bedRect(i).center), i);
        }
      }
    });

    test('without rails the beds leave room for the header and footer', () {
      for (final size in _narrowed) {
        final stage = GardenStage(size);
        final layout = GardenSceneLayout(
          Size(stage.worldWidth, size.height),
          immersive: true,
        );
        final beds = layout.bedRect(0).top;
        final nearBeds = layout.bedRect(2).bottom;
        expect(nearBeds - beds, lessThanOrEqualTo(size.height / 3),
            reason: '$size');
      }
    });
  });

  group('GardenFramedScene', () {
    const scene = Key('scene');

    Future<void> pump(
      WidgetTester t,
      Size window,
      double width, {
      String? mirror,
    }) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = window;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: GardenFramedScene(
            width: width,
            bands: kGardenEdgeBands[GardenTimeOfDay.noon]!,
            imageSize: GardenSceneLayout.imageSize,
            imageTop: -246,
            imageHeight: 1093,
            mirror: mirror,
            child: const SizedBox.expand(key: scene),
          ),
        ),
      );
      await t.pump();
    }

    testWidgets('narrows the scene and extends both margins', (t) async {
      await pump(t, const Size(1180, 820), 610);
      expect(t.getRect(find.byKey(scene)), const Rect.fromLTWH(285, 0, 610, 820));
      expect(find.byType(GardenEdgeWash), findsNWidgets(2));
      expect(find.byType(ShaderMask), findsOneWidget);
      // Each wash reaches the window edge and runs under the feathered
      // scene edge, but never further than the 48px feather.
      final left = t.getRect(find.byType(GardenEdgeWash).first);
      final right = t.getRect(find.byType(GardenEdgeWash).last);
      expect(left.left, 0);
      expect(right.right, 1180);
      expect(left.right, inInclusiveRange(285, 285 + 48));
      expect(right.left, inInclusiveRange(1180 - 285 - 48, 1180 - 285));
      expect(t.takeException(), isNull);
    });

    testWidgets('stays edge to edge when the margins are negligible', (t) async {
      await pump(t, const Size(650, 820), 610);
      expect(t.getRect(find.byKey(scene)), const Rect.fromLTWH(0, 0, 650, 820));
      expect(find.byType(GardenEdgeWash), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('a mirror that cannot load leaves the edge colours', (t) async {
      await pump(t, const Size(1180, 820), 610,
          mirror: 'assets/game/not_shipped.jpg');
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(GardenEdgeWash), findsNWidgets(2));
      expect(t.getRect(find.byKey(scene)), const Rect.fromLTWH(285, 0, 610, 820));
      expect(t.takeException(), isNull);
    });
  });

  group('play stage', () {
    test('phones and short windows stay full width', () {
      for (final safe in const [
        Size(320, 568),
        Size(390, 753),
        Size(430, 862),
        Size(640, 776),
        Size(753, 369),
        Size(932, 404),
      ]) {
        expect(playStageWidthFor(safe), safe.width, reason: '$safe');
      }
    });

    test('tall wide windows are capped', () {
      for (final safe in const [
        Size(820, 1136),
        Size(1024, 1322),
        Size(1194, 790),
        Size(1366, 980),
      ]) {
        expect(playStageWidthFor(safe), kPlayStageWidth, reason: '$safe');
      }
    });

    test('the night scene keeps its full composition at any height', () {
      for (final height in [600.0, 768.0, 820.0, 1024.0, 1366.0]) {
        expect(
          nightSceneWidthFor(height) / height,
          closeTo(kStarNightImageSize.width / kStarNightImageSize.height, 1e-12),
          reason: '$height',
        );
      }
    });

    test('the catch board keeps phone proportions on a wide stage', () {
      expect(CatchDropBoard.stageScaleFor(320), 1);
      expect(CatchDropBoard.stageScaleFor(390), 1);
      expect(CatchDropBoard.stageScaleFor(CatchDropBoard.referenceWidth), 1);
      // Uniform: the tray keeps the share of the stage it has on a large
      // phone, and so does the catch window (7.5% of the stage).
      final scale = CatchDropBoard.stageScaleFor(kPlayStageWidth);
      expect(scale, CatchDropBoard.maxStageScale);
      expect(
        CatchDropBoard.basketWidth * scale / kPlayStageWidth,
        closeTo(CatchDropBoard.basketWidth / CatchDropBoard.referenceWidth, 1e-9),
      );
      expect(
        CatchDropBoard.goldenDropSize * scale / kPlayStageWidth,
        closeTo(
          CatchDropBoard.goldenDropSize / CatchDropBoard.referenceWidth,
          1e-9,
        ),
      );
      expect(CatchDropBoard.stageScaleFor(1200), CatchDropBoard.maxStageScale);
    });
  });
}
