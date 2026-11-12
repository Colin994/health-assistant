import 'package:flutter/material.dart';

/// 主题色彩 token 集：浅色 / 暗色两套，经 ThemeExtension 注入 ThemeData。
///
/// 屏幕代码一律 `context.tokens.xxx` 取色（随系统明暗自动切换）；
/// [AppColors] 静态常量仅保留给 game 画布等固定画板与浅色主题定义本身。
/// 暗色各文字色均按 WCAG AA（≥4.5:1）对底色校验（2026-11-12 P2 整改）。
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primary,
    required this.primaryText,
    required this.onPrimary,
    required this.primarySurface,
    required this.primarySurfaceDim,
    required this.danger,
    required this.shadowTint,
  });

  /// 页面底色。
  final Color background;

  /// 卡片与浅色分区。
  final Color surface;

  /// 标题与正文主色。
  final Color textPrimary;

  /// 次要信息。
  final Color textSecondary;

  /// 占位符。
  final Color textTertiary;

  /// 不可用状态（仅装饰）。
  final Color textDisabled;

  /// 主品牌色（底 / 框 / 大图形）。
  final Color primary;

  /// 可作文字/功能图标的青绿（同色相加深或提亮）。
  final Color primaryText;

  /// 主色背景上的文字（暗色下为深墨绿，反转保证对比度）。
  final Color onPrimary;

  /// 选中标签等浅色强调背景。
  final Color primarySurface;

  /// 更浅的强调背景。
  final Color primarySurfaceDim;

  /// 红色警示（仅破坏性操作等极少数场景）。
  final Color danger;

  /// 阴影色调。
  final Color shadowTint;

  /// 卡片投影（带品牌调；暗色换深影，不参与 lerp）。
  List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(color: shadowTint, blurRadius: 24, offset: const Offset(0, 8)),
      ];

  /// 次级投影。
  List<BoxShadow> get cardSubtleShadow => <BoxShadow>[
        BoxShadow(color: shadowTint, blurRadius: 12, offset: const Offset(0, 4)),
      ];

  /// 浅色（与 AppColors 现行值一致）。
  static const AppTokens light = AppTokens(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    textPrimary: Color(0xFF28332F),
    textSecondary: Color(0xFF5A625F),
    textTertiary: Color(0xFF6B7370),
    textDisabled: Color(0x1A28332F),
    primary: Color(0xFF27C3B0),
    primaryText: Color(0xFF0B7A6D),
    onPrimary: Color(0xFFFFFFFF),
    primarySurface: Color(0x1A27C3B0),
    primarySurfaceDim: Color(0x0D27C3B0),
    danger: Color(0xFFFF4747),
    shadowTint: Color(0x33062522),
  );

  /// 暗色（墨绿黑底 + 提亮青绿，同色相家族；白名单外不引入新色相）。
  static const AppTokens dark = AppTokens(
    background: Color(0xFF0E1613),
    surface: Color(0xFF18201C),
    textPrimary: Color(0xFFE1E8E5),
    textSecondary: Color(0xFFA6B0AC),
    textTertiary: Color(0xFF8A948F),
    textDisabled: Color(0xFF2C3631),
    primary: Color(0xFF2ED3BC),
    primaryText: Color(0xFF6FE3D2),
    onPrimary: Color(0xFF06251F),
    primarySurface: Color(0xFF1D2B27),
    primarySurfaceDim: Color(0xFF16211D),
    danger: Color(0xFFFF6B6B),
    shadowTint: Color(0x80000000),
  );

  @override
  AppTokens copyWith({
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? primary,
    Color? primaryText,
    Color? onPrimary,
    Color? primarySurface,
    Color? primarySurfaceDim,
    Color? danger,
    Color? shadowTint,
  }) =>
      AppTokens(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        textDisabled: textDisabled ?? this.textDisabled,
        primary: primary ?? this.primary,
        primaryText: primaryText ?? this.primaryText,
        onPrimary: onPrimary ?? this.onPrimary,
        primarySurface: primarySurface ?? this.primarySurface,
        primarySurfaceDim: primarySurfaceDim ?? this.primarySurfaceDim,
        danger: danger ?? this.danger,
        shadowTint: shadowTint ?? this.shadowTint,
      );

  @override
  ThemeExtension<AppTokens> lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      textDisabled: mix(textDisabled, other.textDisabled),
      primary: mix(primary, other.primary),
      primaryText: mix(primaryText, other.primaryText),
      onPrimary: mix(onPrimary, other.onPrimary),
      primarySurface: mix(primarySurface, other.primarySurface),
      primarySurfaceDim: mix(primarySurfaceDim, other.primarySurfaceDim),
      danger: mix(danger, other.danger),
      shadowTint: mix(shadowTint, other.shadowTint),
    );
  }

  /// 供调试与相等性比较（Flutter 3.44 起 ThemeExtension 不再要求 props）。
  List<Object?> get props => <Object?>[
        background,
        surface,
        textPrimary,
        textSecondary,
        textTertiary,
        textDisabled,
        primary,
        primaryText,
        onPrimary,
        primarySurface,
        primarySurfaceDim,
        danger,
        shadowTint,
      ];
}

/// `context.tokens.background` 式取色入口。
extension AppTokensX on BuildContext {
  /// 当前主题的色彩 token（浅色 / 暗色随系统）。
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
