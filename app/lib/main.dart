import 'package:base_utils/base_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'di/injector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 渠道自标识（logcat 过滤「渠道」）：dev=开发版 / master=正式版。
  debugPrint('[app] 启动 · 渠道=$appFlavor${isDevBuild ? '（开发版）' : '（正式版）'}');
  // 领域/数据层经 get_it 聚合注册（架构文档 3.1）；
  // 表现层状态由 ProviderScope 内的 Riverpod provider 管理。
  await configureDependencies();
  runApp(
    const ProviderScope(child: HealthAssistantApp()),
  );
}
