/// core_reminder：提醒域（W2 落地）。
///
/// - [ReminderEngine]：三类本地倒计时引擎（静音=暂停、变更次轮生效、
///   活动打断重置、四态反馈、自动降频），纯 Dart 可测；
/// - [ReminderCoordinator]：schedule-next 通知编排（系统闹钟兜底）；
/// - store 接口 + drift 实现（经 core_database），宿主无库时降级内存态。
library;

export 'src/clock/reminder_clock.dart';
export 'src/copy/reminder_copy_provider.dart';
export 'src/coordinator/reminder_coordinator.dart';
export 'src/engine/reminder_engine.dart';
export 'src/injector.module.dart';
export 'src/store/local_stores.dart';
export 'src/notify/reminder_notification_service.dart';
export 'src/store/reminder_stores.dart';
