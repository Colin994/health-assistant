// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_profile/src/health_tag_store.dart' as _i859;
import 'package:core_profile/src/reminder_config_repository.dart' as _i881;
import 'package:injectable/injectable.dart' as _i526;

class CoreProfilePackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i881.ReminderConfigRepository>(
        () => _i881.PrefsReminderConfigRepository());
    gh.lazySingleton<_i859.HealthTagStore>(() => _i859.PrefsHealthTagStore());
  }
}
