import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Semantic button materials for the woodland courtyard five-material craft system.
enum GardenButtonStyle { honey, starlight, sage, paper, disabled }

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

  // Five-material tactile craft palette for the woodland courtyard.
  // 1. Warm walnut wood plaque (押花册 / 商店 / 悬挂招牌)
  static const wood = Color(0xFF7E4D29);
  static const woodLight = Color(0xFF9E643A);
  static const woodHighlight = Color(0xFFBC8558);
  static const woodEdge = Color(0xFF5C371C);
  static const rope = Color(0xFF715138);

  // 2. Warm translucent parchment (HUD pills / secondary buttons / panels)
  static const paperTop = Color(0xFFFFFDF6);
  static const paper = Color(0xFFFFF7E7);
  static const paperBottom = Color(0xFFF6ECD6);
  static const paperSurface = Color(0xFFF4EFE0);
  static const paperEdge = Color(0xFFD4C39E);
  static const ink = Color(0xFF443A2B);
  static const mutedInk = Color(0xFF6E6049);
  static const amberDot = Color(0xFFE8A631);

  // 3. Warm honey gold (接阳光 / 提前完成 / 开始练习)
  static const honeyTop = Color(0xFFFFE08A);
  static const honey = Color(0xFFFFD574);
  static const honeyTint = Color(0xFFF6EFD8);
  static const honeyDeep = Color(0xFFF2BE52);
  static const honeyHighlight = Color(0xFFFFF3C4);
  static const sunInk = Color(0xFF8C5B0C);
  static const honeyEdge = Color(0xFFC99534);

  // 4. Night starlight indigo (解锁态看星星)
  static const starTop = Color(0xFF495C8A);
  static const starBottom = Color(0xFF314068);
  static const starHighlight = Color(0xFF8598C7);
  static const starEdge = Color(0xFF1F2A47);
  static const starDot = Color(0xFF9A84D6);

  // 5. Sage leaf green (照料 / 种植 / 购买 / 返回花园)
  static const leafTop = Color(0xFF52784F);
  static const leaf = Color(0xFF3B5C3A);
  static const leafHighlight = Color(0xFF8AB086);
  static const leafEdge = Color(0xFF273F26);

  // Disabled / locked mist (无厚边无阴影)
  static const disabledSurface = Color(0xD9F1EDE2);
  static const disabledEdge = Color(0xFFD2C9B6);

  // Scene overlays & life traces
  static const dampSoil = Color(0x663A2412);
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

/// A small warm-parchment game object, never a full-width application toolbar.
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
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [GardenUiTheme.paperTop, GardenUiTheme.paperBottom],
      ),
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

/// Five-material handcrafted tactile button with 90ms press sink & Reduce Motion support.
class GardenPlayButton extends StatefulWidget {
  const GardenPlayButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.style,
    this.hint,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool primary;
  final GardenButtonStyle? style;
  final String? hint;

  @override
  State<GardenPlayButton> createState() => _GardenPlayButtonState();
}

class _GardenPlayButtonState extends State<GardenPlayButton> {
  bool _pressed = false;

  GardenButtonStyle get _effectiveStyle =>
      widget.style ??
      (widget.primary ? GardenButtonStyle.honey : GardenButtonStyle.paper);

  @override
  Widget build(BuildContext context) {
    final style = _effectiveStyle;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isDisabledLook = style == GardenButtonStyle.disabled;
    final activePress = _pressed && widget.onPressed != null;

    final (topColor, bottomColor, edgeColor, highlightColor, textColor) =
        switch (style) {
          GardenButtonStyle.honey => (
            GardenUiTheme.honeyTop,
            GardenUiTheme.honeyDeep,
            GardenUiTheme.honeyEdge,
            GardenUiTheme.honeyHighlight,
            GardenUiTheme.ink,
          ),
          GardenButtonStyle.starlight => (
            GardenUiTheme.starTop,
            GardenUiTheme.starBottom,
            GardenUiTheme.starEdge,
            GardenUiTheme.starHighlight,
            GardenUiTheme.paper,
          ),
          GardenButtonStyle.sage => (
            GardenUiTheme.leafTop,
            GardenUiTheme.leaf,
            GardenUiTheme.leafEdge,
            GardenUiTheme.leafHighlight,
            GardenUiTheme.paper,
          ),
          GardenButtonStyle.paper => (
            GardenUiTheme.paperTop,
            GardenUiTheme.paperBottom,
            GardenUiTheme.paperEdge,
            GardenUiTheme.paperTop,
            GardenUiTheme.ink,
          ),
          GardenButtonStyle.disabled => (
            GardenUiTheme.disabledSurface,
            GardenUiTheme.disabledSurface,
            GardenUiTheme.disabledEdge,
            GardenUiTheme.disabledEdge,
            GardenUiTheme.mutedInk,
          ),
        };

    final bottomEdgeWidth = isDisabledLook
        ? 0.0
        : (activePress && !reduceMotion ? 1.0 : 3.5);
    final translateY = !isDisabledLook && activePress && !reduceMotion
        ? 2.0
        : 0.0;
    final scale = !isDisabledLook && activePress && !reduceMotion ? 0.97 : 1.0;

    return Tooltip(
      message: widget.hint ?? widget.label,
      child: Semantics(
        button: true,
        enabled: widget.onPressed != null,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : (activePress
                    ? const Duration(milliseconds: 90)
                    : const Duration(milliseconds: 160)),
          curve: activePress ? Curves.easeOut : Curves.easeOutBack,
          transformAlignment: Alignment.center,
          transform: Matrix4.translationValues(0, translateY, 0)
            ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
          decoration: BoxDecoration(
            color: isDisabledLook ? GardenUiTheme.groundFade : edgeColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDisabledLook
                ? null
                : const [
                    BoxShadow(
                      color: GardenUiTheme.softShadow,
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          padding: EdgeInsets.only(bottom: bottomEdgeWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  activePress && reduceMotion ? bottomColor : topColor,
                  bottomColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabledLook
                    ? GardenUiTheme.disabledEdge
                    : highlightColor.withValues(alpha: 0.72),
                width: 1,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                overlayColor: WidgetStatePropertyAll(
                  textColor.withValues(alpha: .08),
                ),
                onTapDown: widget.onPressed == null
                    ? null
                    : (_) {
                        if (!isDisabledLook) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _pressed = true);
                      },
                onTapCancel: () => setState(() => _pressed = false),
                onTap: widget.onPressed == null
                    ? null
                    : () {
                        setState(() => _pressed = false);
                        widget.onPressed!();
                      },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        widget.icon,
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.onPressed == null
                                ? GardenUiTheme.mutedInk
                                : textColor,
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
      ),
    );
  }
}

/// A warm walnut wood plaque sign; supports hanging title or tactile plaque button.
class GardenWood extends StatefulWidget {
  const GardenWood({
    super.key,
    required this.child,
    this.hanging = false,
    this.onTap,
  });

  final Widget child;
  final bool hanging;
  final VoidCallback? onTap;

  @override
  State<GardenWood> createState() => _GardenWoodState();
}

class _GardenWoodState extends State<GardenWood> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final activePress = _pressed && widget.onTap != null;
    final bottomEdge = activePress && !reduceMotion ? 1.0 : 3.5;
    final translateY = activePress && !reduceMotion ? 2.0 : 0.0;
    final scale = activePress && !reduceMotion ? 0.97 : 1.0;

    final plaque = AnimatedContainer(
      duration: reduceMotion
          ? Duration.zero
          : (activePress
                ? const Duration(milliseconds: 90)
                : const Duration(milliseconds: 160)),
      curve: activePress ? Curves.easeOut : Curves.easeOutBack,
      transformAlignment: Alignment.center,
      transform: Matrix4.translationValues(0, translateY, 0)
        ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
      decoration: BoxDecoration(
        color: GardenUiTheme.woodEdge,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: GardenUiTheme.softShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomEdge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              activePress && reduceMotion
                  ? GardenUiTheme.wood
                  : GardenUiTheme.woodLight,
              GardenUiTheme.wood,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GardenUiTheme.woodHighlight.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: GardenUiTheme.paper),
          child: widget.child,
        ),
      ),
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.hanging)
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
        plaque,
      ],
    );

    if (widget.onTap == null) return body;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: body,
      ),
    );
  }
}
