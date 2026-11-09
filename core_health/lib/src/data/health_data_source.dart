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

  /// 读取 [from, to] 时间窗内的步数总量（STEPS 点求和）。
  ///
  /// L4 采集器启动时用于恢复「今日步数」基线（自写自读聚合：L4 写入
  /// HC 的步数段经此读回），跨会话保持今日累计连续。
  Future<int> fetchStepsTotal({
    required DateTime from,
    required DateTime to,
  });

  /// 写入一段步数记录（L4 会话段落入 HC 聚合层；demo 造数复用同入口）。
  Future<bool> writeSteps({
    required DateTime start,
    required DateTime end,
    required int count,
  });

  /// 删除 [from, to] 时间窗内的步数记录（仅能删本应用写入的；
  /// demo 造数清理用）。
  Future<bool> deleteSteps({
    required DateTime from,
    required DateTime to,
  });
}
