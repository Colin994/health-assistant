import 'dart:math' as math;
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  for (final t in [AppTokens.light, AppTokens.dark]) {
    test('readable foregrounds over real theme surfaces ${t.background}', () {
      for (final bg in [
        t.background,
        t.surface,
        Color.alphaBlend(t.primarySurface, t.background),
      ]) {
        for (final fg in [
          t.textPrimary,
          t.textSecondary,
          t.textTertiary,
          t.primaryText,
          t.dangerText,
        ]) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$fg over $bg',
          );
        }
      }
    });
  }
  test('danger text participates in copy and interpolation', () {
    expect(AppTokens.light.copyWith().dangerText, AppTokens.light.dangerText);
    final mixed = AppTokens.light.lerp(AppTokens.dark, .5) as AppTokens;
    expect(
      mixed.dangerText,
      Color.lerp(AppTokens.light.dangerText, AppTokens.dark.dangerText, .5),
    );
  });
  for (final dark in [false, true]) {
    testWidgets('text buttons and chips consume readable theme roles $dark', (
      t,
    ) async {
      final theme = dark ? AppTheme.dark() : AppTheme.light();
      final tokens = dark ? AppTokens.dark : AppTokens.light;
      expect(
        theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        tokens.primaryText,
      );
      expect(theme.chipTheme.selectedColor, tokens.primarySurface);
      expect(theme.chipTheme.labelStyle!.color, tokens.primaryText);
      expect(
        theme.navigationBarTheme.labelTextStyle!
            .resolve({WidgetState.selected})!
            .color,
        tokens.primaryText,
      );
      expect(
        theme.navigationBarTheme.labelTextStyle!.resolve({})!.color,
        tokens.textSecondary,
      );
      expect(
        theme.navigationRailTheme.unselectedLabelTextStyle!.color,
        tokens.textSecondary,
      );
      await t.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  expect(
                    resolveMotion(context, AppMotion.standard),
                    Duration.zero,
                  );
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}
