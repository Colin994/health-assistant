import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('引导页宽屏限宽、手表预告整卡满足 44dp 触控目标且去冗余文字', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(
          state: const OnboardingState(step: OnboardingStep.value),
          onIntent: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('时机准'), findsOneWidget);
    expect(find.text('懂你'), findsOneWidget);
    expect(find.text('零负担'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(
          state: const OnboardingState(
            step: OnboardingStep.tags,
            selectedTags: {'颈椎不适'},
          ),
          onIntent: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已选'), findsNothing);
    expect(tester.takeException(), isNull);

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
    expect(find.text('了解更多'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(AppContentWidth.contentKey)).width,
      lessThanOrEqualTo(AppContentWidth.maxWidth),
    );
    final target = tester.getSize(
      find.ancestor(
        of: find.text('连接智能手表'),
        matching: find.byType(InkWell),
      ),
    );
    expect(target.width, greaterThanOrEqualTo(44));
    expect(target.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
