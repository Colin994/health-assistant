import 'dart:convert';

import 'package:app/app.dart';
import 'package:app/di/injector.dart';
import 'package:base_utils/base_utils.dart';
import 'package:core_health/core_health.dart';
import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/walkthrough_seed.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('跨平台真机 UI 走查（固定内存存档）', (t) async {
    SharedPreferences.setMockInitialValues(walkthroughSeed());
    await t.runAsync(configureDependencies);
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.runAsync(() async {
        await GetIt.I<ReminderEngine>().stop();
        await GetIt.I<StepSessionCollector>().stop();
        await GetIt.I.reset();
      });
    });

    // 不启动通知协调器：避免 UI 走查重排设备已有的系统通知。
    await t.pumpWidget(const ProviderScope(child: HealthAssistantApp()));
    await t.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    final navigation = find.byWidgetPredicate(
      (widget) => widget is NavigationBar || widget is NavigationRail,
    );
    final media = MediaQuery.of(t.element(navigation));
    debugPrint(
      'WALK_CONDITIONS:${jsonEncode({'logicalWidth': media.size.width, 'logicalHeight': media.size.height, 'textScaleAt16': media.textScaler.scale(16) / 16, 'brightness': media.platformBrightness.name, 'disableAnimations': media.disableAnimations, 'boldText': media.boldText})}',
    );

    Future<void> tap(Finder target) async {
      await t.ensureVisible(target);
      await t.tap(target);
      await t.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
      expect(t.takeException(), isNull);
    }

    void passed(String id) => debugPrint('WALK_PASS:$id');
    Finder nav(String label) =>
        find.descendant(of: navigation, matching: find.text(label));

    expect(find.textContaining('久坐'), findsWidgets);
    expect(find.textContaining('喝水'), findsWidgets);
    expect(find.textContaining('护眼'), findsWidgets);
    passed('W01');

    await tap(nav('设置'));
    expect(find.text('连接智能手表'), findsOneWidget);
    await tap(find.text('连接智能手表'));
    expect(find.text('Pro 功能 · 即将上线，敬请期待'), findsOneWidget);
    await tap(find.text('关于'));
    expect(find.textContaining('版本 '), findsOneWidget);
    expect(find.widgetWithText(AppBar, '设置'), findsOneWidget);
    final settingsList = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    final privacy = find.text('隐私与数据说明');
    await t.scrollUntilVisible(privacy, -100, scrollable: settingsList);
    await tap(privacy);
    expect(find.widgetWithText(AppBar, '隐私与数据说明'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tap(find.byType(BackButton));
    expect(find.widgetWithText(AppBar, '设置'), findsOneWidget);
    if (isDevBuild) {
      await t.scrollUntilVisible(
        find.text('开发者'),
        100,
        scrollable: settingsList,
      );
    }
    expect(find.text('开发者'), isDevBuild ? findsOneWidget : findsNothing);
    passed('W02');

    await tap(nav('我的'));
    expect(find.text('健康标签'), findsOneWidget);
    await tap(find.text('提醒设置'));
    expect(find.text('免打扰'), findsOneWidget);
    expect(find.text('久坐拉伸'), findsOneWidget);
    await tap(find.byType(BackButton));
    expect(find.text('免打扰'), findsNothing);
    expect(find.text('健康标签'), findsOneWidget);
    passed('W03');

    await tap(find.text('慢植物花园'));
    expect(find.byKey(const ValueKey('resource-sunshine')), findsOneWidget);
    expect(find.byKey(const ValueKey('resource-stardust')), findsOneWidget);
    await tap(find.byKey(const ValueKey('resource-sunshine')));
    expect(find.textContaining('当前余额'), findsOneWidget);
    await tap(find.text('知道了'));
    passed('W04');

    // 花畦由场景父级手势统一按世界坐标命中；Semantics 节点不接收指针。
    final plot = find.byKey(const ValueKey('plot-0'));
    await t.ensureVisible(plot);
    await t.tapAt(t.getCenter(plot));
    await t.pumpAndSettle();
    expect(find.text('全程累计 150 / 450 阳光'), findsOneWidget);
    await tap(find.byKey(const ValueKey('invest')));
    expect(find.text('全程累计 180 / 450 阳光'), findsOneWidget);
    expect(find.text('可用阳光 90'), findsOneWidget);
    await tap(find.byTooltip('关闭'));
    passed('W05');

    await tap(find.text('商店'));
    await tap(find.byKey(const ValueKey('buy-path')));
    expect(find.text('已拥有'), findsOneWidget);
    expect(find.text('当前余额 · 阳光 60 · 星屑 110'), findsOneWidget);
    await tap(find.byTooltip('关闭'));
    await tap(find.text('押花册'));
    await tap(find.byTooltip('关闭'));
    passed('W06');

    for (final label in ['接阳光', '看星星']) {
      await tap(find.text(label));
      expect(find.text('$label · 40 秒'), findsOneWidget);
      await tap(find.text('先不练'));
      expect(find.byType(AlertDialog), findsNothing);
    }
    passed('W07');

    await tap(find.byKey(const ValueKey('garden-exit')));
    expect(find.text('慢植物花园'), findsOneWidget);
    await tap(nav('今日'));
    expect(find.textContaining('喝水'), findsWidgets);
    passed('W08');

    await tap(nav('我的'));
    await tap(find.text('去添加'));
    expect(find.widgetWithText(AppBar, '编辑健康标签'), findsOneWidget);
    await tap(find.text('颈椎不适'));
    await tap(find.byType(BackButton));
    expect(await t.runAsync(GetIt.I<HealthTagStore>().load), isEmpty);
    await tap(find.text('去添加'));
    const savedTag = HealthTagCatalog.noConditionTag;
    await tap(find.text(savedTag));
    await tap(find.widgetWithText(FilledButton, '保存'));
    expect(find.widgetWithText(AppBar, '我的'), findsOneWidget);
    expect(find.text(savedTag), findsOneWidget);
    expect(await t.runAsync(GetIt.I<HealthTagStore>().load), {savedTag});
    passed('W09');

    await tap(find.text('提醒设置'));
    final waterSwitch = find.descendant(
      of: find.ancestor(
        of: find.text('喝水提醒'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Row && widget.children.any((child) => child is Switch),
        ),
      ),
      matching: find.byType(Switch),
    );
    final repository = GetIt.I<ReminderConfigRepository>();
    final before = (await t.runAsync(repository.load))!;
    expect(t.widget<Switch>(waterSwitch).value, before.waterEnabled);
    await tap(waterSwitch);
    final expected = before.copyWith(waterEnabled: !before.waterEnabled);
    expect(await t.runAsync(repository.load), expected);
    expect(t.widget<Switch>(waterSwitch).value, expected.waterEnabled);
    await tap(find.byType(BackButton));
    await tap(find.text('提醒设置'));
    expect(t.widget<Switch>(waterSwitch).value, expected.waterEnabled);
    await tap(find.byType(BackButton));
    passed('W10');
  });
}
