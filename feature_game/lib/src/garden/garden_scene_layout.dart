import 'dart:math' as math;
import 'package:core_database/core_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../game_state.dart';
import '../garden_scene.dart';
import 'garden_asset_catalog.dart';
import 'garden_ui_theme.dart';

/// One source-image transform owns background, plants, decoration and hit tests.
class GardenSceneLayout {
  const GardenSceneLayout(this.size, {this.immersive = false});
  final bool immersive;
  final Size size;

  /// Matches `garden_woodland_{morning,noon,dusk,night}.jpg` (768×1376).
  static const imageSize = Size(768, 1376);
  static const focus = Rect.fromLTRB(.04, .46, .96, .80);

  /// 2×2 stone-edged soil beds in far-to-near painter order.
  static const beds = [
    Offset(.295, .562),
    Offset(.722, .562),
    Offset(.285, .700),
    Offset(.738, .700),
  ];

  /// Woodland courtyard decoration anchors (sorted far-to-near at draw time).
  static const decorationAnchors = <String, Offset>{
    'hanging_pot': Offset(.41, .24),
    'pavilion': Offset(.76, .34),
    'lantern': Offset(.67, .43),
    'fence': Offset(.55, .44),
    'bench': Offset(.37, .46),
    'gnome': Offset(.15, .48),
    'wheelbarrow': Offset(.80, .48),
    'path': Offset(.17, .78),
  };

  static const _decorationSizes = <String, double>{
    'pavilion': 210,
    'fence': 170,
    'path': 170,
    'bench': 140,
    'wheelbarrow': 130,
    'lantern': 115,
    'hanging_pot': 105,
    'gnome': 96,
  };

  double get scale => immersive
      ? math.max(size.width / imageSize.width, size.height / imageSize.height)
      : math.min(
          size.width / (imageSize.width * focus.width),
          size.height / (imageSize.height * focus.height),
        );

  Offset get translation {
    if (!immersive) {
      return Offset(size.width / 2, size.height / 2) -
          Offset(
                focus.center.dx * imageSize.width,
                focus.center.dy * imageSize.height,
              ) *
              scale;
    }
    final renderedW = imageSize.width * scale;
    final renderedH = imageSize.height * scale;
    final dx = (size.width - renderedW) / 2;
    // On wide/landscape screens where vertical cropping occurs, center on the
    // 2×2 soil beds (y = 0.60) while clamping so the backdrop always fills
    // [0, size.height] with no gaps. On portrait phones renderedH == size.height
    // so dy stays 0.
    final desiredDy = size.height / 2 - 0.60 * renderedH;
    final minDy = math.min(0.0, size.height - renderedH);
    final dy = desiredDy.clamp(minDy, 0.0);
    return Offset(dx, dy);
  }

  Offset point(Offset normalized) =>
      translation +
      Offset(
            normalized.dx * imageSize.width,
            normalized.dy * imageSize.height,
          ) *
          scale;

  Rect bedRect(int index) => Rect.fromCenter(
    center: point(beds[index]),
    width: imageSize.width * .36 * scale,
    height: imageSize.height * .105 * scale,
  );

  /// The sprite's cropped/faded base sits in the front half of the soil surface.
  /// Aligning that base to the bed centre lifts the visible roots above centre.
  /// Keep this offset in source-image coordinates so it scales with the scene.
  Rect plantRect(int index) {
    final bed = bedRect(index);
    final width = bed.width * .62;
    final height = width * 1.25;
    final bottom = bed.center.dy + bed.height * .22;
    return Rect.fromLTWH(bed.center.dx - width / 2, bottom - height, width, height);
  }

  Rect decorationRect(String id) {
    final anchor = point(decorationAnchors[id]!);
    final dim = (_decorationSizes[id] ?? 140) * scale;
    return Rect.fromLTWH(anchor.dx - dim / 2, anchor.dy - dim * .80, dim, dim);
  }

  Rect hitRect(int index) {
    final r = bedRect(index);
    return Rect.fromCenter(
      center: r.center,
      width: math.max(44, r.width),
      height: math.max(44, r.height),
    ).intersect(Offset.zero & size);
  }

  int? hitTest(Offset position) {
    int? result;
    double nearest = double.infinity;
    for (var i = 0; i < beds.length; i++) {
      if (!hitRect(i).contains(position)) continue;
      final distance = (position - bedRect(i).center).distanceSquared;
      if (distance < nearest) {
        nearest = distance;
        result = i;
      }
    }
    return result;
  }
}

/// A margin beside the narrowed world.
enum GardenEdge { left, right }

/// How the world is framed on a wide window, and whether the actions move
/// into a side rail. Pure, so the tablet breakpoints stay unit-testable.
///
/// Portrait and near-portrait windows keep the world edge to edge. Once the
/// window is wide enough the world narrows to the full composition and the
/// margins carry the master's edge colours. When each margin fits a rail the
/// actions leave the bottom of the scene, so they never cover the beds.
class GardenStage {
  const GardenStage(this.window);

  final Size window;

  /// Room for the 248 wide action block plus a 16 margin on either side.
  static const double railWidth = 280;

  /// Narrowest world worth squeezing for the sake of the rails.
  static const double minWorldWidth = 440;

  /// World width that keeps the whole composition in view, from the canopy
  /// down to the near lawn (about 75% of the master's height).
  double get _framedWidth =>
      GardenSceneLayout.imageSize.width /
      GardenSceneLayout.imageSize.height /
      .75 *
      window.height;

  /// World width that still shows the master's full width, so narrowing
  /// never crops the outer beds.
  double get _uncroppedWidth =>
      GardenSceneLayout.imageSize.width /
      GardenSceneLayout.imageSize.height *
      window.height;

  /// On-screen width of the world.
  double get worldWidth {
    final width = window.width;
    final framed = math.min(_framedWidth, width);
    final betweenRails = width - 2 * railWidth;
    final world =
        betweenRails >= math.max(minWorldWidth, _uncroppedWidth) &&
            betweenRails < framed
        ? betweenRails
        : framed;
    return width - world < 2 * GardenFramedScene.minMargin ? width : world;
  }

  /// Symmetric margin on either side of the world.
  double get margin => (window.width - worldWidth) / 2;

  /// Both margins fit a rail, so the actions move beside the scene.
  bool get hasRails => margin >= railWidth - .01;
}

/// One scene narrower than its window.
///
/// The margins carry the master's edge colours, a heavily blurred mirror of
/// the same master and a light shade towards the window edge, and the scene
/// feathers into them. The painting therefore reads as continuous instead of
/// ending at a rectangular seam, while plants, decorations and hit testing
/// stay on the single sharp transform in [child].
class GardenFramedScene extends StatelessWidget {
  const GardenFramedScene({
    required this.width,
    required this.bands,
    required this.imageSize,
    required this.imageTop,
    required this.imageHeight,
    required this.child,
    this.mirror,
    super.key,
  });

  /// On-screen width of the scene.
  final double width;

  /// Edge colours of the master, `[left, right]`; see [kGardenEdgeBands].
  final List<List<Color>> bands;

  /// Pixel size of the master. With [imageTop] and [imageHeight] it keeps
  /// every colour band at the height it was sampled from.
  final Size imageSize;
  final double imageTop;
  final double imageHeight;

  /// Asset drawn as a blurred mirror in the margins; null for colour only.
  final String? mirror;
  final Widget child;

  /// Margins narrower than this are treated as edge to edge.
  static const double minMargin = 24;

  /// The mirrored copy is reduced to this width, so it reads as soft colour
  /// rather than a second, recognisable scene.
  static const int _mirrorWidth = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final margin = (c.maxWidth - width) / 2;
        if (margin < minMargin) return child;
        // The fade ends well inside the outer bed, which begins at 11.5%.
        final t = (width * .075).clamp(24.0, 48.0) / width;
        final washWidth = margin + width * t;
        final imageWidth = imageHeight * imageSize.width / imageSize.height;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final edge in GardenEdge.values) ...[
              _margin(
                edge,
                washWidth,
                top: 0,
                height: c.maxHeight,
                child: GardenEdgeWash(
                  edge: edge,
                  bands: bands[edge.index],
                  imageTop: imageTop,
                  imageHeight: imageHeight,
                ),
              ),
              if (mirror != null)
                _margin(
                  edge,
                  washWidth,
                  top: imageTop,
                  height: imageHeight,
                  child: _BlurredMirror(
                    asset: mirror!,
                    edge: edge,
                    width: imageWidth,
                    height: imageHeight,
                    thumbHeight:
                        (_mirrorWidth * imageSize.height / imageSize.width)
                            .round(),
                  ),
                ),
              // Shade towards the window edge keeps the controls legible.
              _margin(
                edge,
                washWidth,
                top: 0,
                height: c.maxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: -_outward(edge),
                      end: _outward(edge),
                      colors: [
                        GardenUiTheme.standard.hud.withValues(alpha: 0),
                        GardenUiTheme.standard.hud.withValues(alpha: .22),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              left: margin,
              top: 0,
              width: width,
              height: c.maxHeight,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    GardenUiTheme.groundFade,
                    GardenUiTheme.groundSolid,
                    GardenUiTheme.groundSolid,
                    GardenUiTheme.groundFade,
                  ],
                  stops: [0, t, 1 - t, 1],
                ).createShader(rect),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  static Alignment _outward(GardenEdge edge) =>
      edge == GardenEdge.left ? Alignment.centerLeft : Alignment.centerRight;

  static Widget _margin(
    GardenEdge edge,
    double width, {
    required double top,
    required double height,
    required Widget child,
  }) => Positioned(
    left: edge == GardenEdge.left ? 0 : null,
    right: edge == GardenEdge.right ? 0 : null,
    top: top,
    width: width,
    height: height,
    child: child,
  );
}

/// The master's edge colours laid down in a margin, each band at the height
/// it was sampled from.
class GardenEdgeWash extends StatelessWidget {
  const GardenEdgeWash({
    required this.edge,
    required this.bands,
    required this.imageTop,
    required this.imageHeight,
    super.key,
  });

  final GardenEdge edge;
  final List<Color> bands;
  final double imageTop;
  final double imageHeight;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _EdgeWashPainter(
      edge: edge,
      bands: bands,
      imageTop: imageTop,
      imageHeight: imageHeight,
    ),
    size: Size.infinite,
  );
}

class _EdgeWashPainter extends CustomPainter {
  const _EdgeWashPainter({
    required this.edge,
    required this.bands,
    required this.imageTop,
    required this.imageHeight,
  });

  final GardenEdge edge;
  final List<Color> bands;
  final double imageTop;
  final double imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bands,
          stops: kGardenEdgeBandStops,
        ).createShader(
          Rect.fromLTRB(0, imageTop, size.width, imageTop + imageHeight),
        ),
    );
  }

  @override
  bool shouldRepaint(_EdgeWashPainter oldDelegate) =>
      oldDelegate.edge != edge ||
      oldDelegate.bands != bands ||
      oldDelegate.imageTop != imageTop ||
      oldDelegate.imageHeight != imageHeight;
}

/// The master mirrored at the scene's edge and softened to colour, so the
/// margin continues what is right next to it.
class _BlurredMirror extends StatelessWidget {
  const _BlurredMirror({
    required this.asset,
    required this.edge,
    required this.width,
    required this.height,
    required this.thumbHeight,
  });

  final String asset;
  final GardenEdge edge;
  final double width;
  final double height;
  final int thumbHeight;

  @override
  Widget build(BuildContext context) {
    final seam = edge == GardenEdge.left
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      // Solid next to the scene, thinning towards the window edge where the
      // edge colours take over.
      shaderCallback: (rect) => LinearGradient(
        begin: -seam,
        end: seam,
        colors: [
          GardenUiTheme.groundSolid.withValues(alpha: .3),
          GardenUiTheme.groundSolid,
        ],
      ).createShader(rect),
      child: ClipRect(
        child: OverflowBox(
          alignment: seam,
          minWidth: width,
          maxWidth: width,
          minHeight: height,
          maxHeight: height,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1, 1, 1),
            child: Image.asset(
              asset,
              cacheWidth: GardenFramedScene._mirrorWidth,
              cacheHeight: thumbHeight,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) {
                debugPrint('Garden mirror fallback: $asset ($error)');
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GardenSceneView extends StatefulWidget {
  const GardenSceneView({
    super.key,
    required this.plots,
    required this.decorations,
    required this.time,
    required this.onPlot,
    this.feedback,
    this.immersive = false,
  });

  final List<PlotState?> plots;
  final List<String> decorations;
  final GardenTimeOfDay time;
  final ValueChanged<int> onPlot;
  final GardenFeedback? feedback;
  final bool immersive;

  @override
  State<GardenSceneView> createState() => _GardenSceneViewState();
}

class _GardenSceneViewState extends State<GardenSceneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _traceController;
  int? _lastFeedbackSeq;
  int? _tracedPlot;

  @override
  void initState() {
    super.initState();
    _traceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _tracedPlot = null);
        }
      });
    _consumeFeedback(widget.feedback);
  }

  @override
  void didUpdateWidget(GardenSceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consumeFeedback(widget.feedback);
  }

  void _consumeFeedback(GardenFeedback? feedback) {
    if (feedback == null || feedback.sequence == _lastFeedbackSeq) return;
    _lastFeedbackSeq = feedback.sequence;
    if (!feedback.success || feedback.action != GardenAction.invest) return;
    final plotIndex = int.tryParse(feedback.target);
    if (plotIndex == null || plotIndex < 0 || plotIndex >= 4) return;
    _tracedPlot = plotIndex;
    _traceController.forward(from: 0);
  }

  @override
  void dispose() {
    _traceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final sortedDecorations = [
      for (final id in widget.decorations)
        if (GardenSceneLayout.decorationAnchors.containsKey(id)) id,
    ]..sort(
        (a, b) => GardenSceneLayout.decorationAnchors[a]!.dy.compareTo(
          GardenSceneLayout.decorationAnchors[b]!.dy,
        ),
      );

    return LayoutBuilder(
      builder: (context, c) {
        final layout = GardenSceneLayout(
          Size(c.maxWidth, c.maxHeight),
          immersive: widget.immersive,
        );
        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (event) {
              final i = layout.hitTest(event.localPosition);
              if (i != null) widget.onPlot(i);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: layout.translation.dx,
                  top: layout.translation.dy,
                  width: GardenSceneLayout.imageSize.width * layout.scale,
                  height: GardenSceneLayout.imageSize.height * layout.scale,
                  child: Image.asset(
                    GardenAssetCatalog.scene(widget.time),
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stack) {
                      debugPrint('Garden scene fallback: ${widget.time} ($error)');
                      return GardenScene(timeOfDay: widget.time);
                    },
                  ),
                ),
                for (final id in sortedDecorations)
                  Positioned.fromRect(
                    rect: layout.decorationRect(id),
                    child: IgnorePointer(
                      child: Image.asset(
                        GardenAssetCatalog.decoration(id),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                for (var i = 0; i < widget.plots.length; i++) ...[
                  if (_tracedPlot == i)
                    _DampSoilTrace(
                      bed: layout.bedRect(i),
                      animation: _traceController,
                    ),
                  if (widget.plots[i] != null)
                    Positioned.fromRect(
                      key: ValueKey('plant-$i'),
                      rect: layout.plantRect(i),
                      child: IgnorePointer(
                        child: _tracedPlot == i && !reduceMotion
                            ? AnimatedBuilder(
                                animation: _traceController,
                                builder: (context, child) {
                                  // Single gentle damped leaf-tip sway in first 700ms.
                                  final t =
                                      (_traceController.value * 3000 / 700)
                                          .clamp(0.0, 1.0);
                                  final sway = t >= 1
                                      ? 0.0
                                      : 0.055 *
                                            math.exp(-3.5 * t) *
                                            math.sin(2 * math.pi * 1.5 * t);
                                  return Transform.rotate(
                                    angle: sway,
                                    alignment: Alignment.bottomCenter,
                                    child: child,
                                  );
                                },
                                child: GardenPlantSprite(
                                  species: widget.plots[i]!.species,
                                  stage: widget.plots[i]!.stage,
                                  planted: true,
                                ),
                              )
                            : GardenPlantSprite(
                                species: widget.plots[i]!.species,
                                stage: widget.plots[i]!.stage,
                                planted: true,
                              ),
                      ),
                    ),
                  Positioned.fromRect(
                    rect: layout.hitRect(i),
                    child: Semantics(
                      key: ValueKey('plot-$i'),
                      sortKey: OrdinalSortKey(i.toDouble()),
                      button: true,
                      label: widget.plots[i] == null
                          ? '第 ${i + 1} 块花畦，种花'
                          : '第 ${i + 1} 块花畦，${seedCatalog.firstWhere((s) => s.id == widget.plots[i]!.species).name}，${plantStageLabel(widget.plots[i]!)}',
                      onTap: () => widget.onPlot(i),
                      excludeSemantics: true,
                      child: IgnorePointer(
                        child: Align(
                          alignment: widget.plots[i] == null
                              ? Alignment.center
                              : Alignment.bottomRight,
                          child: widget.plots[i] != null &&
                                  !widget.plots[i]!.harvestable
                              ? const SizedBox.shrink()
                              : Container(
                                  width: widget.plots[i] == null ? 36 : 34,
                                  height: widget.plots[i] == null ? 36 : 34,
                                  decoration: BoxDecoration(
                                    color: widget.plots[i] == null
                                        ? GardenUiTheme.paper
                                        : GardenUiTheme.honey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: widget.plots[i] == null
                                          ? GardenUiTheme.paperEdge
                                          : GardenUiTheme.honeyEdge,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: GardenUiTheme.softShadow,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.plots[i] == null
                                        ? Icons.add_rounded
                                        : Icons.local_florist_rounded,
                                    size: 20,
                                    color: widget.plots[i] == null
                                        ? GardenUiTheme.leaf
                                        : GardenUiTheme.ink,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Short-lived damp soil tint right around the plant roots after investing sunshine.
class _DampSoilTrace extends StatelessWidget {
  const _DampSoilTrace({required this.bed, required this.animation});

  final Rect bed;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final oval = Rect.fromCenter(
      center: Offset(bed.center.dx, bed.center.dy + bed.height * .06),
      width: bed.width * .68,
      height: bed.height * .58,
    );
    return Positioned.fromRect(
      rect: oval,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final opacity = (1 - Curves.easeIn.transform(animation.value))
                .clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GardenUiTheme.dampSoil,
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(oval.width / 2, oval.height / 2),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String plantStageLabel(PlotState plot) => plot.harvestable
    ? '可收获'
    : const ['发芽', '幼苗', '成长', '花苞', '盛开', '盛开，接近收获'][plot.stage];
