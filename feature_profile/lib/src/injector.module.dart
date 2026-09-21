// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:feature_profile/src/profile_view_model.dart' as _i503;
import 'package:feature_profile/src/reminder_settings_view_model.dart' as _i405;
import 'package:injectable/injectable.dart' as _i526;

class FeatureProfilePackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i503.ProfileViewModel>(() => _i503.ProfileViewModel());
    gh.factory<_i405.ReminderSettingsViewModel>(
        () => _i405.ReminderSettingsViewModel());
  }
}
