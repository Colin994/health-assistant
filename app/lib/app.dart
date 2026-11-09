import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/main_shell.dart';

/// 应用根组件。
///
/// 首启流程（设计稿 01–03）：MainShell 首帧回调 [MainShell.onFirstLaunch]，
/// 未看过引导则全屏弹出引导页，退出（跳过或完成）后持久化标记，
/// 下次启动直接进主壳；引导页可随时经「设置 → 开发者」重看。
class HealthAssistantApp extends StatefulWidget {
  const HealthAssistantApp({super.key});

  @override
  State<HealthAssistantApp> createState() => _HealthAssistantAppState();
}

class _HealthAssistantAppState extends State<HealthAssistantApp> {
  static const _onboardingDoneKey = 'onboarding_done';

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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康助手',
      theme: AppTheme.light(),
      home: MainShell(onFirstLaunch: _runFirstLaunchFlow),
    );
  }
}
