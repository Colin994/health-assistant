import 'package:core_health/core_health.dart';
import 'package:domain_all/domain_all.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injector.config.dart';

/// 全局 DI 容器（架构文档 3.1）。
final GetIt getIt = GetIt.instance;

/// 壳模块 DI 聚合入口（仅领域/数据层）。
///
/// 双容器边界规则：get_it 只注册 UseCase / Repository / DataSource；
/// 表现层状态（ViewModel）由 Riverpod provider 管理，feature_* 包
/// 不再提供 PackageModule。provider 内可经 `GetIt.I` 取领域依赖，
/// 反向（get_it 取 provider）禁止。
/// 后台隔离入口（W5 health_bridge 唤醒）同样经 [getIt] 取依赖，
/// 不依赖 UI 上下文。
@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(CoreHealthPackageModule),
    ExternalModule(DomainAllPackageModule),
  ],
)
Future<void> configureDependencies() async => getIt.init();
