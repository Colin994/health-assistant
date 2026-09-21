import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'src/main_shell.dart';

/// 应用根组件。
///
/// W2 路由表接入后：首启走引导页（设计稿 01–03）再进主壳；
/// 当前默认直接进主壳，引导页经「我的 → 开发者」入口进入。
class HealthAssistantApp extends StatelessWidget {
  const HealthAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康助手',
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
