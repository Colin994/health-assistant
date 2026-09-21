import 'package:injectable/injectable.dart';

/// core_health 包 DI 生成锚点。
///
/// 经 `@microPackageInit` 生成 `CoreHealthPackageModule`
/// （见 injector.config.dart，由 core_health.dart 对外导出），
/// 由 app 壳模块经 `externalPackageModules` 聚合注册。
@microPackageInit
void configureCoreHealthDependencies() {}
