/// core_health：健康数据域（技术设计文档 §6.1）。
///
/// 对上只暴露 [HealthRepository] 抽象；健康中枢插件的差异
/// （iOS HealthKit / Android Health Connect 授权引导）全部封装在
/// DataSource 实现内。当前为社区 `health` 插件实现，W5 起可替换为
/// 自研 `health_bridge` 插件实现，Repository 接口不变。
library;

export 'src/health_repository.dart';
export 'src/health_repository_impl.dart';
export 'src/data/health_data_source.dart';
export 'src/data/health_data_source_impl.dart';
export 'src/injector.module.dart';
