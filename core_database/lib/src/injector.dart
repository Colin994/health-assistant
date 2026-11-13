import 'package:injectable/injectable.dart';

/// core_database 包 DI 生成锚点。
///
/// 经 `@microPackageInit` 生成 `CoreDatabasePackageModule`,
/// 由 app 壳模块经 `externalPackageModules` 聚合注册。
@microPackageInit
void configureCoreDatabaseDependencies() {}
