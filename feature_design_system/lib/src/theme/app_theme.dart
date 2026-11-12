import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// 应用主题：设计 token → ThemeData 的统一落地。
///
/// 浅色 + 暗色两套（暗色随系统，ThemeMode.system）；组件默认样式以此为准，
/// 页面级代码不允许散写颜色/字号，必须经 `context.tokens` 取色
/// （game 画布等固定画板除外）。
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      onSecondary: AppColors.onPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surface,
      error: AppColors.danger,
      onError: AppColors.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[AppTokens.light],
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // 显式给色：裸 TextStyle 无 color 时，标题在 M3 AppBar 上会
        // 失去主题继承而渲染为白（2026-11-12 audit P1）。
        titleTextStyle: AppTypography.title.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 可交互填充面用 primaryText：白字对 #0B7A6D 5.2:1 过 AA
          // （primary 仅作装饰面，白字对 #27C3B0 仅 1.98:1）。
          backgroundColor: AppColors.primaryText,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTypography.subtitle,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // 文字用 primaryText（对比度预算），边框保持品牌主色。
          foregroundColor: AppColors.primaryText,
          textStyle: AppTypography.subtitle,
          side: const BorderSide(color: AppColors.primary),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.captionMedium,
        side: BorderSide.none,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.textDisabled,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  /// 暗色：墨绿黑底 + 提亮青绿（同色相家族），文字色均过 AA。
  static ThemeData dark() {
    const t = AppTokens.dark;
    final colorScheme = ColorScheme.dark(
      primary: t.primary,
      onPrimary: t.onPrimary,
      secondary: t.primary,
      onSecondary: t.onPrimary,
      surface: t.background,
      onSurface: t.textPrimary,
      surfaceContainerHighest: t.surface,
      error: t.danger,
      onError: t.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[AppTokens.dark],
      scaffoldBackgroundColor: t.background,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: t.textPrimary,
        displayColor: t.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.title.copyWith(color: t.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: t.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // 与浅色统一：可交互填充面 = primaryText（暗色为提亮青绿，
          // 深墨绿字 8.6:1）。
          backgroundColor: t.primaryText,
          foregroundColor: t.onPrimary,
          textStyle: AppTypography.subtitle,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.primaryText,
          textStyle: AppTypography.subtitle,
          side: BorderSide(color: t.primary),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.primarySurface,
        labelStyle: AppTypography.captionMedium,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTypography.body.copyWith(color: t.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: t.textDisabled,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
