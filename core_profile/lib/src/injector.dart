import 'package:injectable/injectable.dart';

/// core_profile 包 DI 生成锚点。
///
/// 经 `@microPackageInit` 生成 `CoreProfilePackageModule`，
/// 由 app 壳模块聚合注册。
@microPackageInit
void configureCoreProfileDependencies() {}
