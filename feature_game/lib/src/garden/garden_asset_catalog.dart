import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../garden_scene.dart';
import 'garden_ui_theme.dart';

part 'garden_asset_metadata.dart';

@immutable
class GardenSpriteMetadata {
  const GardenSpriteMetadata(this.imageSize, this.visibleBounds);
  final Size imageSize;
  final Rect visibleBounds;
}

abstract final class GardenAssetCatalog {
  static String scene(GardenTimeOfDay time) => kGardenIsoAssets[time]!;
  static String plant(String species, int stage) =>
      'assets/game/plant_iso_${species}_stage$stage.png';
  static String fallbackPlant(String species, int stage) =>
      'assets/game/plant_${species}_stage$stage.png';
  static String decoration(String id) => 'assets/game/deco_iso_$id.png';
  static const sunshine = 'assets/game/sun_sprite.png';
  static const stardustBackdrop = 'assets/game/star_backdrop.png';
  static GardenSpriteMetadata metadata(String species, int stage) =>
      gardenSpriteMetadata['${species}_$stage']!;
}

/// Crops transparent margins without distorting the bitmap. Its visible base
/// is the bottom-centre, shared by every growth stage and detail panel.
class GardenPlantSprite extends StatelessWidget {
  const GardenPlantSprite({
    super.key,
    required this.species,
    required this.stage,
    this.label,
    this.planted = false,
  });
  final String species;
  final int stage;
  final String? label;
  final bool planted;
  @override
  Widget build(BuildContext context) {
    final meta = GardenAssetCatalog.metadata(species, stage);
    final visible = meta.visibleBounds;
    // Stage sprites include a free-standing earth mound. In the garden, the
    // flowerbed already supplies soil: bury the lower mound instead of stacking
    // two pieces of terrain. Detail panels retain the complete specimen.
    final bounds = planted && stage > 0
        ? Rect.fromLTWH(
            visible.left,
            visible.top,
            visible.width,
            visible.height * .80,
          )
        : visible;
    return Semantics(
      label: label,
      image: label != null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          final scale = math.min(
            c.maxWidth / bounds.width,
            c.maxHeight / bounds.height,
          );
          final width = bounds.width * scale;
          final artwork = Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: (c.maxWidth - width) / 2 - bounds.left * scale,
                bottom: -(meta.imageSize.height - bounds.bottom) * scale,
                width: meta.imageSize.width * scale,
                height: meta.imageSize.height * scale,
                child: Image.asset(
                  GardenAssetCatalog.plant(species, stage),
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) {
                    debugPrint(
                      'Garden asset fallback: $species/$stage ($error)',
                    );
                    return Image.asset(
                      GardenAssetCatalog.fallbackPlant(species, stage),
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    );
                  },
                ),
              ),
            ],
          );
          if (!planted || stage == 0) return artwork;
          return ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                GardenUiTheme.groundSolid,
                GardenUiTheme.groundSolid,
                GardenUiTheme.groundFade,
              ],
              stops: [0, .90, 1],
            ).createShader(rect),
            child: artwork,
          );
        },
      ),
    );
  }
}
