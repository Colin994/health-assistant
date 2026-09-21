import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:flutter/material.dart';

/// 主导航壳：底部 Tab（今日 / 我的，设计稿 04/07）。
///
/// W2 路由表就绪后：开发者区块移除、Tab 改命名路由 +
/// 通知深链分发（healthassistant://stretch?advice_id=）。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreenRoute(onQuickStretch: () => _pushStretch(context)),
          ProfileScreenRoute(
            devEntries: [
              ('首启引导（设计稿 01–03）', () => _pushOnboarding(context)),
              ('拉伸页（设计稿 05–06）', () => _pushStretch(context)),
            ],
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
        ],
      ),
    );
  }

  void _pushOnboarding(BuildContext context) {
    OnboardingScreenRoute.push(context);
  }

  void _pushStretch(BuildContext context) {
    StretchScreenRoute.push(context);
  }
}
