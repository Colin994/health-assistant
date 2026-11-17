import 'package:base_utils/base_utils.dart';
import 'package:core_model/core_model.dart';
import 'package:injectable/injectable.dart';

import 'data/health_data_source.dart';
import 'health_repository.dart';

/// [HealthRepository] 默认实现：组织 [HealthDataSource] 的数据访问。
@LazySingleton(as: HealthRepository)
class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl(this._dataSource);

  final HealthDataSource _dataSource;

  @override
  Future<bool> requestPermissions() => _dataSource.requestPermissions();

  @override
  Future<bool> hasPermissions() => _dataSource.hasPermissions();

  @override
  Future<List<ActivitySegment>> fetchSegments({
    required DateTime from,
    required DateTime to,
  }) async {
    final segments = await _dataSource.fetchSegments(from: from, to: to);
    AppLogger.debug(
      'fetchSegments: ${segments.length} 段 [$from → $to]',
      tag: 'core_health',
    );
    return segments;
  }

  @override
  Future<int> fetchStepsTotal({
    required DateTime from,
    required DateTime to,
  }) => _dataSource.fetchStepsTotal(from: from, to: to);

  @override
  Future<bool> writeSteps({
    required DateTime start,
    required DateTime end,
    required int count,
  }) =>
      _dataSource.writeSteps(start: start, end: end, count: count);

  @override
  Future<bool> deleteSteps({
    required DateTime from,
    required DateTime to,
  }) =>
      _dataSource.deleteSteps(from: from, to: to);
}
