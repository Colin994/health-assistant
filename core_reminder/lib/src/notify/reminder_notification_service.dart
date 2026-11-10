import 'dart:convert';

import 'package:base_utils/base_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 通知服务（接口；测试/Fake 可替换）。
abstract class ReminderNotificationService {
  Future<void> init();

  /// Android 13+ / iOS 运行时通知权限请求（引导页第 3 步调用）。
  Future<bool> requestPermission();

  Future<bool> hasPermission();

  /// 精确闹钟申请（Android 14+；拒批自动降级 inexact）。
  Future<void> requestExactAlarmsIfNeeded();

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// schedule-next：按绝对时刻排下一次（被杀期由系统闹钟兜底）。
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String? payload,
  });

  Future<void> cancel(int id);
}

/// 通知 id：三类提醒各自固定 + 测试提醒。
abstract final class ReminderNotificationIds {
  static const sedentaryId = 1;
  static const waterId = 2;
  static const eyeId = 3;
  static const testId = 99;
}

@LazySingleton(as: ReminderNotificationService)
class FlutterReminderNotificationService implements ReminderNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _ready = false;
  var _exactAllowed = false;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    '健康提醒',
    channelDescription: '久坐拉伸 · 喝水 · 护眼 倒计时提醒',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (error) {
      AppLogger.error('通知初始化失败（测试环境预期）', tag: 'notify', error: error);
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (error) {
      AppLogger.error('通知权限请求失败', tag: 'notify', error: error);
    }
    return false;
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    } catch (_) {
      // 测试环境：视为未授权。
    }
    return false;
  }

  @override
  Future<void> requestExactAlarmsIfNeeded() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      // v19 仅暴露请求入口（无 supported/granted 预查）：
      // 未授予时弹系统设置页申请；拒批/不支持返回 false → 降级 inexact。
      _exactAllowed = await android.requestExactAlarmsPermission() ?? false;
    } catch (error) {
      _exactAllowed = false;
      AppLogger.error('精确闹钟申请降级为 inexact（±15 分）', tag: 'notify', error: error);
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      await _plugin.show(id, title, body, _details, payload: payload);
    } catch (error) {
      AppLogger.error('即时通知发送失败', tag: 'notify', error: error);
    }
  }

  @override
  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    if (!at.isAfter(DateTime.now())) return; // 已过时刻不再排（开屏重算兜底）。
    final utc = tz.TZDateTime.from(at.toUtc(), tz.UTC);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        utc,
        _details,
        payload: payload,
        androidScheduleMode: _exactAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (error) {
      AppLogger.error('排程失败 id=$id', tag: 'notify', error: error);
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {
      // 未初始化/无该 id：忽略。
    }
  }
}

/// 通知 payload（W2 只带 kind/adviceId；W3 深链直接复用此结构）。
String buildReminderPayload(String kind, String adviceId) =>
    jsonEncode({'kind': kind, 'advice_id': adviceId});
