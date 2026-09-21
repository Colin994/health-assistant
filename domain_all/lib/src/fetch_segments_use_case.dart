import 'package:core_health/core_health.dart';
import 'package:core_model/core_model.dart';
import 'package:core_network/core_network.dart';
import 'package:injectable/injectable.dart';

/// 拉取时间窗内的活动分段。
///
/// 冷启动补拉场景由调用方传入时间窗（如近 12h）；
/// 数据源异常时返回 [Failure]，不向上抛异常（Result 模式）。
@injectable
class FetchSegmentsUseCase {
  const FetchSegmentsUseCase(this._healthRepository);

  final HealthRepository _healthRepository;

  Future<Result<List<ActivitySegment>>> call({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final segments = await _healthRepository.fetchSegments(
        from: from,
        to: to,
      );
      return Success(segments);
    } catch (error) {
      return Failure(
        code: 'health.fetch_failed',
        message: '读取活动分段失败',
        error: error,
      );
    }
  }
}
