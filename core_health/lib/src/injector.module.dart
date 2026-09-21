// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:core_health/src/data/health_data_source.dart' as _i395;
import 'package:core_health/src/data/health_data_source_impl.dart' as _i996;
import 'package:core_health/src/health_repository.dart' as _i384;
import 'package:core_health/src/health_repository_impl.dart' as _i773;
import 'package:injectable/injectable.dart' as _i526;

class CoreHealthPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.lazySingleton<_i395.HealthDataSource>(
        () => _i996.HealthDataSourceImpl());
    gh.lazySingleton<_i384.HealthRepository>(
        () => _i773.HealthRepositoryImpl(gh<_i395.HealthDataSource>()));
  }
}
