import 'package:base_utils/base_utils.dart';
import 'package:core_reminder/core_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 渠道自标识（logcat 过滤「渠道」）：dev=开发版 / master=正式版。
  debugPrint('[app] 启动 · 渠道=$appFlavor${isDevBuild ? '（开发版）' : '（正式版）'}');
  // 领域/数据层经 get_it 聚合注册（架构文档 3.1）；
  // 表现层状态由 ProviderScope 内的 Riverpod provider 管理。
  await configureDependencies();
  // 提醒协调器（引擎 tick + schedule-next 闹钟 + 生命周期落盘；W2 已落地）。
  try {
    await GetIt.I<ReminderCoordinator>().start();
  } catch (error) {
    // 通知/引擎启动失败不阻断 UI（引擎由首页 VM 兜底再启动）。
    debugPrint('[app] 提醒协调器启动失败：$error');
  }
  runApp(
    const ProviderScope(child: HealthAssistantApp()),
  );
}
