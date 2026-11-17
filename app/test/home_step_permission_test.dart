import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_home/feature_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('步数权限提示和设置入口一起显示并在恢复后消失', (tester) async {
    HomeIntent? action;
    Future<void> show(HomeState state) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(
          state: state,
          onIntent: (intent) {
            action = intent;
          },
        ),
      ),
    );

    await show(const HomeState(dataSourceLabel: '步数权限未开启', todaySteps: 0));
    expect(find.text('步数权限未开启'), findsOneWidget);
    expect(find.text('0 步'), findsNothing);
    await tester.tap(find.text('去设置'));
    expect(action, isA<RefreshPressed>());

    await show(const HomeState(dataSourceLabel: '今日步数 · 实时更新中', todaySteps: 0));
    expect(find.text('步数权限未开启'), findsNothing);
    expect(find.text('去设置'), findsNothing);
    expect(find.text('0 步'), findsOneWidget);
  });
}
