import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('引导页宽屏限宽且了解更多满足 44dp 触控目标', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(
          state: const OnboardingState(step: OnboardingStep.permissions),
          onIntent: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(AppContentWidth.contentKey)).width,
      lessThanOrEqualTo(AppContentWidth.maxWidth),
    );
    final target = tester.getSize(find.widgetWithText(TextButton, '了解更多'));
    expect(target.width, greaterThanOrEqualTo(44));
    expect(target.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
