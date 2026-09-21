import 'dart:io' show Platform;

import 'package:core_model/core_model.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';

import 'health_data_source.dart';

/// 社区 `health` 插件包装（P0 前四周，技术设计文档 §6.1）。
///
/// 双端差异在此吸收：iOS 直接弹「苹果健康」授权页；Android 由插件
/// 内部检查并引导安装/授权 Health Connect。W5 起由自研
/// `health_bridge` 实现替换，接口不变。
@LazySingleton(as: HealthDataSource)
class HealthDataSourceImpl implements HealthDataSource {
  HealthDataSourceImpl();

  final Health _health = Health();

  /// 最小采集集：活动相关数据，不碰心率/睡眠（PRD §7）。
  /// 注意：health 插件在 Android 不支持 EXERCISE_TIME（dataTypeKeysAndroid
  /// 未收录，读写均抛 HealthException），Android 仅请求 STEPS/WORKOUT。
  static final List<HealthDataType> readTypes = Platform.isAndroid
      ? [HealthDataType.STEPS, HealthDataType.WORKOUT]
      : [
          HealthDataType.STEPS,
          HealthDataType.EXERCISE_TIME,
          HealthDataType.WORKOUT,
        ];

  @override
  Future<bool> requestPermissions() async {
    return _health.requestAuthorization(
      readTypes,
      permissions: List.filled(readTypes.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<bool> hasPermissions() async {
    final granted = await _health.hasPermissions(
      readTypes,
      permissions: List.filled(readTypes.length, HealthDataAccess.READ),
    );
    return granted ?? false;
  }

  @override
  Future<List<ActivitySegment>> fetchSegments({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _health.getHealthDataFromTypes(
      types: readTypes,
      startTime: from,
      endTime: to,
    );
    final segments = points.map(_toSegment).toList()
      ..sort(
        (ActivitySegment a, ActivitySegment b) => a.start.compareTo(b.start),
      );
    return segments;
  }

  @override
  Future<bool> writeTestSteps({
    required DateTime start,
    required DateTime end,
    required int count,
  }) async {
    // 写入需先申请 WRITE 权限（会弹 HC 授权页，仅 demo 造数场景触发）
    final granted = await _health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ_WRITE],
    );
    if (!granted) return false;
    return _health.writeHealthData(
      value: count.toDouble(),
      type: HealthDataType.STEPS,
      startTime: start,
      endTime: end,
    );
  }

  ActivitySegment _toSegment(HealthDataPoint point) {
    return ActivitySegment(
      id: '${point.sourcePlatform.name}:${point.uuid}',
      type: switch (point.type) {
        HealthDataType.WORKOUT => ActivityType.active,
        HealthDataType.EXERCISE_TIME => ActivityType.active,
        HealthDataType.STEPS => ActivityType.walking,
        _ => ActivityType.other,
      },
      start: point.dateFrom,
      end: point.dateTo,
      source: switch (point.sourcePlatform) {
        HealthPlatformType.appleHealth => 'healthkit',
        HealthPlatformType.googleHealthConnect => 'health_connect',
      },
    );
  }
}
