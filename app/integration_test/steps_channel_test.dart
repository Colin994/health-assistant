import 'dart:io';

import 'package:core_health/core_health.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 计步通道走查：真实宿主 App + 原生平台通道，不依赖 widget 树。
///
/// iOS 模拟器没有 Core Motion 步数源，预期收到 NO_SENSOR；Android 模拟器
/// 可能收到 NO_SENSOR/PERMISSION_DENIED。关键断言是不能出现
/// MissingPluginException，且错误码必须是 UI 已处理的受控降级。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('计步通道走查：原生实现已注册并受控降级', (tester) async {
    final collector = StepSessionCollector();
    final errors = <Object>[];
    final subscription = collector.todaySteps.listen(
      (_) {},
      onError: errors.add,
    );

    try {
      await tester.runAsync(() async {
        await collector.start();
        // 给原生 EventChannel 足够时间返回 NO_SENSOR；有真实计步器时会
        // 正常保持订阅，不要求测试期间必须产生步数。
        await Future<void>.delayed(const Duration(seconds: 1));
      });

      expect(
        errors.whereType<MissingPluginException>(),
        isEmpty,
        reason: '${Platform.operatingSystem} 仍未注册 steps/session 原生实现',
      );
      for (final error in errors.whereType<PlatformException>()) {
        expect(
          error.code,
          anyOf('NO_SENSOR', 'PERMISSION_DENIED', 'REGISTER_FAILED'),
          reason: '计步通道应只暴露 UI 可识别的降级错误',
        );
      }
    } finally {
      await subscription.cancel();
      await collector.stop();
    }
  });
}
