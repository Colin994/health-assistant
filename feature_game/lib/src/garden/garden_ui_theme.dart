import 'package:flutter/material.dart';

/// Opaque scene chrome remains readable over every garden time of day.
@immutable
class GardenUiTheme extends ThemeExtension<GardenUiTheme> {
  const GardenUiTheme({
    this.hud = const Color(0xFF16322B),
    this.onHud = const Color(0xFFF3F7F1),
    this.secondary = const Color(0xFFC5D2CC),
    this.sunshine = const Color(0xFFFCFF7D),
    this.stardust = const Color(0xFFD7C7FF),
  });
  final Color hud;
  final Color onHud;
  final Color secondary;
  final Color sunshine;
  final Color stardust;
  // Parchment, honey and sage belong to the garden, not the medical app chrome.
  static const wood = Color(0xFF8A552F);
  static const woodLight = Color(0xFF9D6238);
  static const woodEdge = Color(0xFF704A2E);
  static const rope = Color(0xFF715138);
  static const paper = Color(0xFFFFF7E7);
  static const paperEdge = Color(0xFFD6C7A6);
  static const ink = Color(0xFF443A2B);
  static const mutedInk = Color(0xFF6E6049);
  static const honey = Color(0xFFFFD574);
  static const sunInk = Color(0xFF8C5B0C);
  static const honeyEdge = Color(0xFFD3A448);
  static const leaf = Color(0xFF4C7049);
  static const softShadow = Color(0x30473320);
  static const groundFade = Color(0x00FFFFFF);
  static const groundSolid = Color(0xFFFFFFFF);
  static const standard = GardenUiTheme();
  static const radius = 24.0;
  static const spacing = 12.0;
  static const panelWidth = 480.0;
  static GardenUiTheme of(BuildContext context) =>
      Theme.of(context).extension<GardenUiTheme>() ?? standard;
  @override
  GardenUiTheme copyWith({
    Color? hud,
    Color? onHud,
    Color? secondary,
    Color? sunshine,
    Color? stardust,
  }) => GardenUiTheme(
    hud: hud ?? this.hud,
    onHud: onHud ?? this.onHud,
    secondary: secondary ?? this.secondary,
    sunshine: sunshine ?? this.sunshine,
    stardust: stardust ?? this.stardust,
  );
  @override
  GardenUiTheme lerp(covariant GardenUiTheme? other, double t) {
    if (other == null) return this;
    return GardenUiTheme(
      hud: Color.lerp(hud, other.hud, t)!,
      onHud: Color.lerp(onHud, other.onHud, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      sunshine: Color.lerp(sunshine, other.sunshine, t)!,
      stardust: Color.lerp(stardust, other.stardust, t)!,
    );
  }
}

class GardenHud extends StatelessWidget {
  const GardenHud({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final g = GardenUiTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: g.hud,
        borderRadius: BorderRadius.circular(GardenUiTheme.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GardenUiTheme.spacing),
        child: IconTheme(
          data: IconThemeData(color: g.onHud),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: g.onHud),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A small game object, never a full-width application toolbar.
class GardenPaper extends StatelessWidget {
  const GardenPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: GardenUiTheme.paper,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GardenUiTheme.paperEdge),
      boxShadow: const [
        BoxShadow(
          color: GardenUiTheme.softShadow,
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: padding,
      child: IconTheme(
        data: const IconThemeData(color: GardenUiTheme.ink),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: GardenUiTheme.ink),
          child: child,
        ),
      ),
    ),
  );
}

class GardenPlayButton extends StatelessWidget {
  const GardenPlayButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.hint,
  });
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool primary;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    final edge = primary ? GardenUiTheme.honeyEdge : GardenUiTheme.paperEdge;
    return Tooltip(
      message: hint ?? label,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: edge,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: GardenUiTheme.softShadow,
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: primary ? GardenUiTheme.honey : GardenUiTheme.paper,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onPressed,
                overlayColor: WidgetStatePropertyAll(
                  GardenUiTheme.ink.withValues(alpha: .08),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      icon,
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: onPressed == null
                              ? GardenUiTheme.mutedInk
                              : GardenUiTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sign and its suspension are scene objects; sizing follows the label.
class GardenWood extends StatelessWidget {
  const GardenWood({super.key, required this.child, this.hanging = false});
  final Widget child;
  final bool hanging;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (hanging)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 2, height: 22, color: GardenUiTheme.rope),
              const SizedBox(width: 68),
              Container(width: 2, height: 22, color: GardenUiTheme.rope),
            ],
          ),
        ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GardenUiTheme.woodLight, GardenUiTheme.wood],
          ),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            bottom: BorderSide(color: GardenUiTheme.woodEdge, width: 4),
          ),
          boxShadow: const [
            BoxShadow(
              color: GardenUiTheme.softShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: GardenUiTheme.paper),
          child: child,
        ),
      ),
    ],
  );
}
