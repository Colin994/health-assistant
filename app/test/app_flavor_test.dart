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
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
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
    expect(find.text('久坐 · 55 分'), findsOneWidget);
    expect(find.text('喝水 · 45 分'), findsOneWidget);
    expect(find.text('护眼 · 20 分'), findsOneWidget);
    // 数据源行文案依赖采集器异步状态（宿主环境不确定），不在此断言；
    // 其渠道差异已由真机 logcat 验证。
    // W2 里程碑字样（下次提醒占位）仅 dev 渠道。
    expect(
      find.textContaining('（W2）'),
      isDevBuild ? findsWidgets : findsNothing,
    );
    expect(
      find.text('提醒倒计时即将上线'),
      isDevBuild ? findsNothing : findsOneWidget,
    );
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
    expect(find.text('颈椎不适'), findsOneWidget);
    expect(
      find.textContaining('开发者'),
      isDevBuild ? findsWidgets : findsNothing,
      reason: '我的页「开发者选项」提示仅 dev 渠道',
    );
  });
}
