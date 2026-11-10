// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_profile/core_profile.dart' as _i1001;
import 'package:core_reminder/src/clock/reminder_clock.dart' as _i635;
import 'package:core_reminder/src/coordinator/reminder_coordinator.dart'
    as _i233;
import 'package:core_reminder/src/copy/reminder_copy_provider.dart' as _i58;
import 'package:core_reminder/src/engine/reminder_engine.dart' as _i131;
import 'package:core_reminder/src/notify/reminder_notification_service.dart'
    as _i207;
import 'package:core_reminder/src/store/local_stores.dart' as _i259;
import 'package:injectable/injectable.dart' as _i526;

class CoreReminderPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i58.ReminderCopyProvider>(
        () => _i58.ReminderCopyProvider());
    gh.lazySingleton<_i259.ReminderPersistence>(
        () => _i259.PrefsReminderPersistence());
    gh.lazySingleton<_i635.ReminderClock>(() => _i635.SystemReminderClock());
    gh.lazySingleton<_i207.ReminderNotificationService>(
        () => _i207.FlutterReminderNotificationService());
    gh.lazySingleton<_i131.ReminderEngine>(() => _i131.ReminderEngine(
          gh<_i635.ReminderClock>(),
          gh<_i1001.ReminderConfigRepository>(),
          gh<_i1001.HealthTagStore>(),
          gh<_i259.ReminderPersistence>(),
          gh<_i58.ReminderCopyProvider>(),
        ));
    gh.lazySingleton<_i233.ReminderCoordinator>(() => _i233.ReminderCoordinator(
          gh<_i131.ReminderEngine>(),
          gh<_i207.ReminderNotificationService>(),
          gh<_i58.ReminderCopyProvider>(),
        ));
  }
}
