import 'package:app/app.dart';
import 'package:app/di/injector.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('主导航按可用宽度在底部栏和侧边栏之间切换', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'health_tags_v1': ['颈椎不适'],
    });
    await configureDependencies();

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: HealthAssistantApp()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(1024, 1366);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.getSize(find.byKey(AppContentWidth.contentKey)).width,
      lessThanOrEqualTo(840),
    );
  });
}
