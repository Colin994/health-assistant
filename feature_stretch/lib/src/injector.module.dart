// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i687;

import 'package:feature_stretch/src/stretch_view_model.dart' as _i409;
import 'package:injectable/injectable.dart' as _i526;

class FeatureStretchPackageModule extends _i526.MicroPackageModule {
// initializes the registration of main-scope dependencies inside of GetIt
  @override
  _i687.FutureOr<void> init(_i526.GetItHelper gh) {
    gh.factory<_i409.StretchViewModel>(() => _i409.StretchViewModel());
  }
}
