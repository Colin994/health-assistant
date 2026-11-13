import 'package:base_utils/base_utils.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dev_tools_view_model.dart';

/// 主导航壳：底部 Tab（今日 / 我的 / 设置，设计稿 04/07/09）。
///
/// [onFirstLaunch] 由 app 壳注入：首帧回调一次，用于弹首启引导
/// （设计稿 01–03）；引导完成与否持久化在 app 壳。
/// W2 路由表就绪后：Tab 改命名路由 +
/// 通知深链分发（healthassistant://stretch?advice_id=）。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.onFirstLaunch});

  /// 首启流程回调（null 则跳过；app 壳内判断是否已看过引导）。
  final Future<void> Function(BuildContext context)? onFirstLaunch;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  /// 花园刷新信号(递增):游戏返回后触发今日页重读剩余次数。
  int _gardenTick = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFirstLaunch?.call(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 快捷拉伸 FAB 为开发入口（W3 由通知深链替代），master 渠道隐藏。
          HomeScreenRoute(
            onQuickStretch: isDevBuild ? () => _pushStretch(context) : null,
            onOpenReminderSettings: () => _pushReminderSettings(context),
            gardenRefreshTick: _gardenTick,
          ),
          ProfileScreenRoute(
            onReminderSettings: () => _pushReminderSettings(context),
            onOpenGarden: () => _pushGame(context),
          ),
          SettingsScreenRoute(
            // 开发者区块（设计稿等字样）仅 dev 渠道注入，master 不显示
            devEntries: isDevBuild
                ? [
                    ('重看首启引导（设计稿 01–03）', () => _pushOnboarding(context)),
                    ('拉伸页（设计稿 05–06）', () => _pushStretch(context)),
                    ('演示节奏（1 分钟间隔）开关', () => _toggleDemoRhythm(context)),
                    ('发送测试提醒（通知链路自验）', _sendTestReminder),
                    ('花园立体风格 Demo', () => _pushGardenStyleDemo(context)),
                    ('花畦锚点校准', () => _pushBedCalibration(context)),
                    ('接阳光 2.5D 预览', () => _pushCatchPreview(context)),
                    ('结算面板预览', () => _pushResultPreview(context)),
                  ]
                : const [],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }

  void _pushOnboarding(BuildContext context) {
    OnboardingScreenRoute.push(context);
  }

  void _pushReminderSettings(BuildContext context) {
    ReminderSettingsScreenRoute.push(context);
  }

  void _pushStretch(BuildContext context) {
    // 拉伸页内提供「去花园」入口(壳注入,feature_stretch 不依赖 feature_game)。
    StretchScreenRoute.push(
      context,
      onOpenGarden: () => _pushGame(context),
    );
  }

  /// 慢植物花园(正式功能:拉伸页旁入口 + 设置页入口)。
  void _pushGame(BuildContext context) {
    GameScreenRoute.push(context).then((_) {
      if (mounted) {
        setState(() => _gardenTick++);
      }
    });
  }

  /// 花园立体画风 Demo(实验:黏土立体 / 等距 2.5D 对比,仅 dev 渠道)。
  void _pushGardenStyleDemo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GardenStyleDemoScreen(),
      ),
    );
  }

  /// 花畦锚点手动校准(dev:拖框对齐白框,导出常量回贴代码)。
  void _pushBedCalibration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const GardenBedCalibrationScreen(),
      ),
    );
  }

  /// 接阳光 2.5D 预览(dev:合成 snapshot 驱动 Board,不接玩法逻辑)。
  void _pushCatchPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CatchDropPreviewScreen(),
      ),
    );
  }

  /// 结算面板预览(dev:真实 GameScreen 结算态,验证游戏化结算卡)。
  ///
  /// 预览页不接 VM:「回到花园/退出」直接返回上一页。
  void _pushResultPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => GameScreen(
          state: const GameState(
            phase: GamePhase.result,
            resultScore: 95,
            resultCaughtNormal: 14,
            resultCaughtGolden: 1,
            resultElapsedSeconds: 31,
            resultFinishedEarly: true,
            resultSunshine: 19,
            todaySunshineTotal: 120,
          ),
          onIntent: (intent) {
            if (intent is BackToGardenPressed || intent is ExitPressed) {
              Navigator.of(routeContext).pop();
            }
          },
        ),
      ),
    );
  }

  /// dev 渠道「发送测试提醒」：经 DevToolsViewModel 发一条本地通知
  /// （v8 自用户页面移入；View 不直调 Service——架构审计 F1 修复）。
  Future<void> _sendTestReminder() async {
    await ref.read(devToolsViewModelProvider).sendTestReminder();
  }

  /// dev 渠道「演示节奏」：经 DevToolsViewModel 切换，SnackBar 呈现结果。
  Future<void> _toggleDemoRhythm(BuildContext context) async {
    final message =
        await ref.read(devToolsViewModelProvider).toggleDemoRhythm();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
