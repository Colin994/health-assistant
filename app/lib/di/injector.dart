import 'package:core_health/core_health.dart';
import 'package:domain_all/domain_all.dart';
import 'package:feature_home/feature_home.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_stretch/feature_stretch.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

/// 全局 DI 容器（架构文档 3.1）。
final GetIt getIt = GetIt.instance;

/// 壳模块 DI 聚合入口。
///
/// 各库包（core_health / domain_all / feature_*）经
/// `externalPackageModules` 注入各自的 PackageModule；
/// 后台隔离入口（W5 health_bridge 唤醒）同样经 [getIt] 取依赖，
/// 不依赖 UI 上下文。
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(CoreHealthPackageModule),
    ExternalModule(DomainAllPackageModule),
    ExternalModule(FeatureHomePackageModule),
    ExternalModule(FeatureOnboardingPackageModule),
    ExternalModule(FeatureProfilePackageModule),
    ExternalModule(FeatureStretchPackageModule),
  ],
)
Future<void> configureDependencies() async => getIt.init();
