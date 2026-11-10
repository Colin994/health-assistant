// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_reminder/core_reminder.dart' as _i762;
import 'package:domain_all/src/record_feedback_use_case.dart' as _i558;
import 'package:injectable/injectable.dart' as _i526;

class DomainAllPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i558.RecordFeedbackUseCase>(
        () => _i558.RecordFeedbackUseCase(gh<_i762.ReminderEngine>()));
  }
}
