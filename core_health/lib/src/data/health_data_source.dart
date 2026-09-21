import 'package:core_model/core_model.dart';

/// 健康数据源：直接对接系统健康中枢插件的访问层。
///
/// W1 实现为社区 `health` 插件包装（[HealthDataSourceImpl]）；
/// W5 起增加自研 `health_bridge` 实现，经 injectable 配置切换。
abstract class HealthDataSource {
  /// 请求读取权限（含 iOS/Android 差异化授权引导）。
  Future<bool> requestPermissions();

  /// 检查权限是否已授予。
  Future<bool> hasPermissions();

  /// 拉取活动分段并转换为业务对象 [ActivitySegment]。
  Future<List<ActivitySegment>> fetchSegments({
    required DateTime from,
    required DateTime to,
  });

  /// 写入一条测试步数记录（W1 demo 专用：模拟器造数，W2 移除）。
  Future<bool> writeTestSteps({
    required DateTime start,
    required DateTime end,
    required int count,
  });
}
