import 'package:core_model/core_model.dart';

/// 健康数据仓库：活动分段与久坐标记的读取入口。
///
/// 接口不携带任何平台插件类型，保证 DataSource 实现可替换
/// （社区 health 插件 → W5 自研 health_bridge 插件）。
abstract class HealthRepository {
  /// 请求健康数据读取权限（最小集：活动分段/久坐/步数）。
  ///
  /// 返回是否全部授权；iOS 弹苹果健康授权页，Android 引导
  /// 安装/授权 Health Connect，差异由 DataSource 吸收。
  Future<bool> requestPermissions();

  /// 检查权限是否已授予（不触发系统弹窗）。
  Future<bool> hasPermissions();

  /// 拉取 [from, to] 时间窗内的活动分段。
  Future<List<ActivitySegment>> fetchSegments({
    required DateTime from,
    required DateTime to,
  });

  /// 写入一条测试步数记录（W1 demo 专用造数入口，W2 移除）。
  Future<bool> writeTestSteps({
    required DateTime start,
    required DateTime end,
    required int count,
  });
}
