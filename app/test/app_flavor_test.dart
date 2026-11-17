import 'package:app/app.dart';
import 'package:app/di/injector.dart';
import 'package:base_utils/base_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 渠道内容走查（宿主 widget 测试，无需真机）。
///
/// 运行：
/// ```
/// flutter test test/app_flavor_test.dart --dart-define=BUILD_ENV=master
/// flutter test test/app_flavor_test.dart --dart-define=BUILD_ENV=dev
/// ```
/// 断言：W1/L4/W2 等开发内容仅 dev 渠道渲染，master 渠道隐藏。
void main() {
  testWidgets('渠道内容走查：开发者内容仅 dev 可见', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      // v7：我的页标签来自 HealthTagStore（引导落库）。
      'health_tags_v1': ['颈椎不适'],
    });
    // 与 main() 一致：先聚合 DI（懒注册），再渲染 App。
    await configureDependencies();

    // 拉大测试视口：设置页开发者区块/我的页提示在默认 800×600 下
    // 处于 ListView 折叠区（懒构建不进树），会被 finder 误判不存在。
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: HealthAssistantApp()),
    );
    await tester.pumpAndSettle();

    // ---- 今日页 ----
    // W2：chips 由引擎驱动（活倒计时/状态），断言三类均在且非静态间隔文案。
    expect(find.textContaining('久坐'), findsWidgets);
    expect(find.textContaining('喝水'), findsWidgets);
    expect(find.textContaining('护眼'), findsWidgets);
    expect(find.text('久坐 · 55 分'), findsNothing, reason: 'W2 起不再展示静态间隔');
    // 下次提醒区（引擎投影；测试环境 DB 降级仍应有状态输出）。
    expect(find.text('下次提醒'), findsOneWidget);
    expect(
      find.byTooltip('快速拉伸（开发入口）'),
      isDevBuild ? findsOneWidget : findsNothing,
    );

    // ---- 设置页 ----
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('连接智能手表'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
    expect(
      find.text('开发者'),
      isDevBuild ? findsOneWidget : findsNothing,
      reason: '开发者区块仅 dev 渠道显示',
    );
    expect(
      find.text('重看首启引导（设计稿 01–03）'),
      isDevBuild ? findsOneWidget : findsNothing,
    );
    expect(
      find.text('仅调试构建显示 · 正式版隐藏'),
      isDevBuild ? findsOneWidget : findsNothing,
    );

    // ---- 我的页 ----
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('颈椎不适'), findsOneWidget, reason: '标签来自 HealthTagStore');
    // v7：提醒设置入口移入「我的」（提醒节奏区块），两渠道一致。
    expect(find.text('提醒设置'), findsOneWidget);
    expect(find.text('提醒'), findsOneWidget);
    expect(find.text('健康标签'), findsOneWidget);
    expect(
      find.textContaining('已移至'),
      findsNothing,
      reason: 'v7 删除「请见设置页」指路页脚',
    );
  });
}
