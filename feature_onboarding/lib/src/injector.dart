import 'package:injectable/injectable.dart';

/// feature_onboarding 包 DI 生成锚点。
///
/// 经 `@microPackageInit` 生成 `FeatureOnboardingPackageModule`
/// （见 injector.config.dart，由 feature_onboarding.dart 对外导出），
/// 由 app 壳模块经 `externalPackageModules` 聚合注册。
@microPackageInit
void configureFeatureOnboardingDependencies() {}
