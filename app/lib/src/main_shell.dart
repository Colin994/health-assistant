import 'package:base_utils/base_utils.dart';
import 'package:core_profile/core_profile.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// 主导航壳：底部 Tab（今日 / 我的 / 设置，设计稿 04/07/09）。
///
/// [onFirstLaunch] 由 app 壳注入：首帧回调一次，用于弹首启引导
/// （设计稿 01–03）；引导完成与否持久化在 app 壳。
/// W2 路由表就绪后：Tab 改命名路由 +
/// 通知深链分发（healthassistant://stretch?advice_id=）。
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.onFirstLaunch});

  /// 首启流程回调（null 则跳过；app 壳内判断是否已看过引导）。
  final Future<void> Function(BuildContext context)? onFirstLaunch;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 快捷拉伸 FAB 为开发入口（W3 由通知深链替代），master 渠道隐藏。
          HomeScreenRoute(
            onQuickStretch: isDevBuild ? () => _pushStretch(context) : null,
            onOpenReminderSettings: () => _pushReminderSettings(context),
          ),
          ProfileScreenRoute(
            onReminderSettings: () => _pushReminderSettings(context),
          ),
          SettingsScreenRoute(
            // 开发者区块（设计稿等字样）仅 dev 渠道注入，master 不显示
            devEntries: isDevBuild
                ? [
                    ('重看首启引导（设计稿 01–03）', () => _pushOnboarding(context)),
                    ('拉伸页（设计稿 05–06）', () => _pushStretch(context)),
                    ('演示节奏（1 分钟间隔）开关', () => _toggleDemoRhythm(context)),
                    ('发送测试提醒（通知链路自验）', _sendTestReminder),
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
    StretchScreenRoute.push(context);
  }

  /// dev 渠道「发送测试提醒」：直接发一条本地通知（v8 自用户页面移入）。
  Future<void> _sendTestReminder() async {
    await GetIt.I<ReminderNotificationService>().showNow(
      id: ReminderNotificationIds.testId,
      title: '测试提醒',
      body: '这是一条测试提醒——倒计时到点后，会像这样提醒你',
    );
  }

  /// dev 渠道「演示节奏」：三类间隔一律 1 分钟（忽略静音），真机 E2E 用。
  Future<void> _toggleDemoRhythm(BuildContext context) async {
    final repo = GetIt.I<ReminderConfigRepository>();
    final engine = GetIt.I<ReminderEngine>();
    final config = await repo.load();
    final next = config.copyWith(demoRhythm: !config.demoRhythm);
    await repo.save(next);
    await engine.onSettingsChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next.demoRhythm ? '演示节奏已开启：1 分钟间隔（静音忽略）' : '演示节奏已关闭，恢复正常间隔',
          ),
        ),
      );
    }
  }
}
