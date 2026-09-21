import 'package:injectable/injectable.dart';

/// domain_all 包 DI 生成锚点。
///
/// 经 `@InjectableInit.microPackage` 生成 `DomainAllPackageModule`
/// （见 injector.module.dart，由 domain_all.dart 对外导出），
/// 由 app 壳模块经 `externalPackageModules` 聚合注册。
///
/// 依赖的 core_health 模块不在包内重复注册：类型引用由生成器
/// 直接解析到 core_health 的导入，运行时注册由 app 统一编排。
@microPackageInit
void configureDomainAllDependencies() {}
