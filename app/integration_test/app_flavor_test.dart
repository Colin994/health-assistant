import 'package:app/app.dart';
import 'package:base_utils/base_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 真机渠道内容走查：以真实 App 启动，切 Tab 断言开发内容按渠道显隐。
///
/// 运行（需真机/模拟器在线，`<device>` 替换为 adb 设备名）：
/// ```
/// flutter test integration_test --flavor dev    -d <device>
/// flutter test integration_test --flavor master -d <device>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('渠道内容走查：开发者内容仅 dev 可见', (tester) async {
    // 预置「已看过引导」，确保直接进主壳（引导另有专门入口重看）。
    // 真机插件 I/O 需在 runAsync 中执行（flutter_test 绑定限制）。
    await tester.runAsync(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboarding_done', true);
      } catch (_) {
        // 预置失败不阻塞：设备上通常已有标记。
      }
    });

    await tester.pumpWidget(
      const ProviderScope(child: HealthAssistantApp()),
    );
    await tester.pumpAndSettle();

    // ---- 今日页 ----
    // W2：chips 由引擎驱动（活倒计时/状态），断言三类均在。
    expect(find.textContaining('久坐'), findsWidgets);
    expect(find.textContaining('喝水'), findsWidgets);
    expect(find.textContaining('护眼'), findsWidgets);
    // L4 探针口径仅 dev 渠道。
    expect(
      find.textContaining('L4'),
      isDevBuild ? findsWidgets : findsNothing,
      reason: 'L4 为开发口径字样，master 渠道不得出现',
    );
    // 快捷拉伸 FAB 为开发入口，master 不渲染。
    expect(
      find.byTooltip('快速拉伸（开发入口）'),
      isDevBuild ? findsOneWidget : findsNothing,
    );

    // ---- 设置页 ----
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('连接智能手表'), findsOneWidget); // PRO 行两渠道都在
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
    expect(find.text('健康标签'), findsOneWidget);
    // v7：提醒设置入口移入「我的」，两渠道一致；指路页脚已删。
    expect(find.text('提醒设置'), findsOneWidget);
    expect(find.textContaining('已移至'), findsNothing);
  });
}
