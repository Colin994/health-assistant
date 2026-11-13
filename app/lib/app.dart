import 'dart:async';

import 'package:core_reminder/core_reminder.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_game/feature_game.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/main_shell.dart';

/// 全局导航键：供通知点击 / 冷启动跳转使用（无 context 场景）。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// 应用根组件。
///
/// 首启流程（设计稿 01–03）：MainShell 首帧回调 [MainShell.onFirstLaunch]，
/// 未看过引导则全屏弹出引导页，退出（跳过或完成）后持久化标记，
/// 下次启动直接进主壳；引导页可随时经「设置 → 开发者」重看。
///
/// 通知路由（2026-11 游戏上线）：久坐提醒到点后可选
/// 「拉伸 1 分钟」或「去花园接阳光」；含 App 被杀后点通知的冷启动场景。
class HealthAssistantApp extends StatefulWidget {
  const HealthAssistantApp({super.key});

  @override
  State<HealthAssistantApp> createState() => _HealthAssistantAppState();
}

class _HealthAssistantAppState extends State<HealthAssistantApp> {
  static const _onboardingDoneKey = 'onboarding_done';

  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    _bindNotificationRouting();
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  /// 订阅通知点击/动作 + 处理冷启动动作。
  Future<void> _bindNotificationRouting() async {
    final ReminderNotificationService notif;
    try {
      notif = GetIt.I<ReminderNotificationService>();
    } catch (_) {
      return; // 未注册（测试环境）。
    }
    _tapSub = notif.taps.listen(_handleNotificationAction);

    final launchAction = await notif.takeLaunchAction();
    if (launchAction != null) {
      // 冷启动：等首帧与首启引导完成后跳转。
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) {
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool(_onboardingDoneKey) ?? false)) {
          return; // 引导未完成：不打断首启流程。
        }
        _handleNotificationAction(launchAction);
      });
    }
  }

  /// 按通知动作导航：[ReminderActions.garden] 进花园，其余（含默认点击）
  /// 进拉伸页——拉伸页内再提供「或者去花园接阳光」的次级入口。
  void _handleNotificationAction(String actionId) {
    final context = appNavigatorKey.currentContext;
    if (context == null || !mounted) {
      return;
    }
    if (actionId == ReminderActions.garden) {
      GameScreenRoute.push(context);
      return;
    }
    StretchScreenRoute.push(
      context,
      onOpenGarden: () => GameScreenRoute.push(context),
    );
  }

  Future<void> _runFirstLaunchFlow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_onboardingDoneKey) ?? false) {
      return;
    }
    if (!context.mounted) {
      // 标记未写入：下次启动仍会进入首启流程。
      return;
    }
    await OnboardingScreenRoute.push(context);
    await prefs.setBool(_onboardingDoneKey, true);
    // 首启 first-tip（交互文档 §3.1）：完成引导即告知倒计时已就位。
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('倒计时已就位，接下来的事交给我')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康助手',
      navigatorKey: appNavigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 暗色随系统（2026-11-12 audit P2：此前系统夜间模式被无视）。
      themeMode: ThemeMode.system,
      home: MainShell(onFirstLaunch: _runFirstLaunchFlow),
    );
  }
}
