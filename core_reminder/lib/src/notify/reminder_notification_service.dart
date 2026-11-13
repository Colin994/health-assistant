import 'dart:async';
import 'dart:convert';

import 'package:base_utils/base_utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 通知服务（接口；测试/Fake 可替换）。
abstract class ReminderNotificationService {
  Future<void> init();

  /// Android 13+ / iOS 运行时通知权限请求（引导页第 3 步调用）。
  Future<bool> requestPermission();

  Future<bool> hasPermission();

  /// 通知点击/动作流(actionId)。
  Stream<String> get taps;

  /// 冷启动时取通知动作(App 被杀后点通知启动)。
  Future<String?> takeLaunchAction();

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

/// 通知交互动作（提醒到点后用户可选去拉伸或去花园）。
///
/// Android:通知上的 action 按钮;iOS:长按通知的 category action。
/// 未选择动作直接点通知体 = [defaultTap]（进拉伸页，保持旧行为）。
abstract final class ReminderActions {
  static const stretch = 'stretch';
  static const garden = 'garden';
  static const defaultTap = 'default';

  /// iOS category id（Darwin 通知需显式声明 category 才显示 action）。
  static const iOSCategory = 'reminder_action';
}

@LazySingleton(as: ReminderNotificationService)
class FlutterReminderNotificationService implements ReminderNotificationService {
  FlutterReminderNotificationService({Clock? clock})
      : _clock = clock ?? const SystemClock();

  /// 注入时钟：排期「已过时刻」判定可测（与引擎 ReminderClock 同纪律）。
  final Clock _clock;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _ready = false;
  var _exactAllowed = false;

  static final AndroidNotificationDetails _channel =
      AndroidNotificationDetails(
    'reminders',
    '健康提醒',
    channelDescription: '久坐拉伸 · 喝水 · 护眼 倒计时提醒',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
    // 到点可选两条路径:拉伸 / 去花园(慢植物)。
    actions: [
      const AndroidNotificationAction(
        ReminderActions.stretch,
        '拉伸 1 分钟',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        ReminderActions.garden,
        '去花园接阳光',
        showsUserInterface: true,
      ),
    ],
  );

  static final NotificationDetails _details = NotificationDetails(
    android: _channel,
    iOS: const DarwinNotificationDetails(
      categoryIdentifier: ReminderActions.iOSCategory,
    ),
  );

  /// 通知点击/动作流(值为 actionId;点通知体为 [ReminderActions.defaultTap])。
  final StreamController<String> _taps =
      StreamController<String>.broadcast();

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            // iOS 需声明 category 才能在长按通知时显示两个动作。
            notificationCategories: [
              DarwinNotificationCategory(
                ReminderActions.iOSCategory,
                actions: [
                  DarwinNotificationAction.plain(
                    ReminderActions.stretch,
                    '拉伸 1 分钟',
                  ),
                  DarwinNotificationAction.plain(
                    ReminderActions.garden,
                    '去花园接阳光',
                  ),
                ],
              ),
            ],
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (_taps.isClosed) {
            return;
          }
          _taps.add(response.actionId ?? ReminderActions.defaultTap);
        },
      );
      _ready = true;
    } catch (error) {
      AppLogger.error('通知初始化失败（测试环境预期）', tag: 'notify', error: error);
    }
  }

  /// 冷启动动作:App 被杀后点通知/动作启动时返回 actionId(否则 null)。
  @override
  Future<String?> takeLaunchAction() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details == null || details.didNotificationLaunchApp != true) {
        return null;
      }
      return details.notificationResponse?.actionId ??
          ReminderActions.defaultTap;
    } catch (_) {
      return null;
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
      // 只在首次启动申请一次;被拒后记住、永不再弹系统页(未授予时
      // 插件会直接跳"闹钟与提醒"设置页,每次冷启动调用 = 每次劫持)。
      // 用户之后仍可在系统设置里自行开启;拒批自动降级 inexact(±15 分)。
      final prefs = await SharedPreferences.getInstance();
      final deniedBefore =
          prefs.getBool(_exactAlarmDeniedKey) ?? false;
      if (deniedBefore) {
        _exactAllowed = false;
        return;
      }
      _exactAllowed = await android.requestExactAlarmsPermission() ?? false;
      if (!_exactAllowed) {
        await prefs.setBool(_exactAlarmDeniedKey, true);
      }
    } catch (error) {
      _exactAllowed = false;
      AppLogger.error('精确闹钟申请降级为 inexact（±15 分）', tag: 'notify', error: error);
    }
  }

  static const _exactAlarmDeniedKey = 'l4_exact_alarm_denied_once';

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
    if (!at.isAfter(_clock.now())) return; // 已过时刻不再排（开屏重算兜底）。
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
