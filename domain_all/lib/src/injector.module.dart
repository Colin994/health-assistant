// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_health/core_health.dart' as _i984;
import 'package:domain_all/src/fetch_segments_use_case.dart' as _i320;
import 'package:injectable/injectable.dart' as _i526;

class DomainAllPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i320.FetchSegmentsUseCase>(
        () => _i320.FetchSegmentsUseCase(gh<_i984.HealthRepository>()));
  }
}
