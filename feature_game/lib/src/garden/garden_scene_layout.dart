import 'package:flutter/semantics.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:core_database/core_database.dart';
import '../garden_scene.dart';
import 'garden_asset_catalog.dart';
import 'garden_ui_theme.dart';

/// One source-image transform owns background, plants, decoration and hit tests.
class GardenSceneLayout {
  const GardenSceneLayout(this.size, {this.immersive = false});
  final bool immersive;
  final Size size;
  static const imageSize = Size(1024, 1488);
  static const focus = Rect.fromLTRB(.10, .39, .90, .75);
  static const beds = [
    Offset(.516, .464),
    Offset(.293, .548),
    Offset(.748, .548),
    Offset(.520, .629),
  ];
  static const decorationAnchors = <String, Offset>{
    'pavilion': Offset(.79, .35),
    'fence': Offset(.20, .75),
    'hanging_pot': Offset(.35, .32),
    'gnome': Offset(.30, .66),
    'path': Offset(.52, .75),
    'lantern': Offset(.79, .69),
    'bench': Offset(.20, .67),
    'wheelbarrow': Offset(.79, .77),
  };
  double get scale => immersive
      ? math.max(size.width / imageSize.width, size.height / imageSize.height)
      : math.min(
          size.width / (imageSize.width * focus.width),
          size.height / (imageSize.height * focus.height),
        );
  Offset get translation =>
      Offset(size.width / 2, size.height / 2) -
      Offset(
            (immersive ? .5 : focus.center.dx) * imageSize.width,
            (immersive ? .5 : focus.center.dy) * imageSize.height,
          ) *
          scale;
  Offset point(Offset normalized) =>
      translation +
      Offset(
            normalized.dx * imageSize.width,
            normalized.dy * imageSize.height,
          ) *
          scale;
  Rect bedRect(int index) => Rect.fromCenter(
    center: point(beds[index]),
    width: imageSize.width * .174 * scale,
    height: imageSize.height * .074 * scale,
  );

  /// The sprite's cropped/faded base sits in the front half of the soil surface.
  /// Aligning that base to the bed centre lifts the visible roots above centre.
  /// Keep this offset in source-image coordinates so it scales with the scene.
  Rect plantRect(int index) {
    final bed = bedRect(index);
    final width = bed.width * .86;
    final bottom = bed.center.dy + bed.height * .22;
    return Rect.fromLTWH(
      bed.center.dx - width / 2,
      bottom - bed.width * 1.2,
      width,
      bed.width * 1.2,
    );
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

class GardenSceneView extends StatelessWidget {
  const GardenSceneView({
    super.key,
    required this.plots,
    required this.decorations,
    required this.time,
    required this.onPlot,
    this.immersive = false,
  });
  final List<PlotState?> plots;
  final List<String> decorations;
  final GardenTimeOfDay time;
  final ValueChanged<int> onPlot;
  final bool immersive;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final layout = GardenSceneLayout(
          Size(c.maxWidth, c.maxHeight),
          immersive: immersive,
        );
        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (event) {
              final i = layout.hitTest(event.localPosition);
              if (i != null) onPlot(i);
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
                    GardenAssetCatalog.scene(time),
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                for (final id in decorations)
                  if (GardenSceneLayout.decorationAnchors.containsKey(id))
                    Positioned(
                      left:
                          layout
                              .point(GardenSceneLayout.decorationAnchors[id]!)
                              .dx -
                          80 * layout.scale,
                      top:
                          layout
                              .point(GardenSceneLayout.decorationAnchors[id]!)
                              .dy -
                          128 * layout.scale,
                      width: 160 * layout.scale,
                      height: 160 * layout.scale,
                      child: Image.asset(
                        GardenAssetCatalog.decoration(id),
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                      ),
                    ),
                for (var i = 0; i < plots.length; i++) ...[
                  if (plots[i] != null)
                    Positioned.fromRect(
                      key: ValueKey('plant-$i'),
                      rect: layout.plantRect(i),
                      child: IgnorePointer(
                        child: GardenPlantSprite(
                          species: plots[i]!.species,
                          stage: plots[i]!.stage,
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
                      label: plots[i] == null
                          ? '第 ${i + 1} 块花畦，种花'
                          : '第 ${i + 1} 块花畦，${seedCatalog.firstWhere((s) => s.id == plots[i]!.species).name}，${plantStageLabel(plots[i]!)}',
                      onTap: () => onPlot(i),
                      excludeSemantics: true,
                      child: IgnorePointer(
                        child: Align(
                          alignment: plots[i] == null
                              ? Alignment.center
                              : Alignment.bottomRight,
                          child: plots[i] != null && !plots[i]!.harvestable
                              ? const SizedBox.shrink()
                              : Container(
                                  width: plots[i] == null ? 36 : 32,
                                  height: plots[i] == null ? 36 : 32,
                                  decoration: BoxDecoration(
                                    color: GardenUiTheme.paper,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: GardenUiTheme.paperEdge,
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
                                    plots[i] == null
                                        ? Icons.add_rounded
                                        : Icons.local_florist_rounded,
                                    size: 20,
                                    color: GardenUiTheme.leaf,
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

String plantStageLabel(PlotState plot) => plot.harvestable
    ? '可收获'
    : const ['发芽', '幼苗', '成长', '花苞', '盛开', '盛开，接近收获'][plot.stage];
