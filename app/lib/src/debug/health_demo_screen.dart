import 'package:base_utils/base_utils.dart';
import 'package:core_health/core_health.dart';
import 'package:core_model/core_model.dart';
import 'package:core_network/core_network.dart';
import 'package:domain_all/domain_all.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter/material.dart';

import '../../di/injector.dart';

/// W1 验收 demo 页：申请权限 → 读取近 24h 活动分段 → 列表展示 + 打印。
///
/// W2 接入正式路由后移除（或转入 debug 入口）。
class HealthDemoScreen extends StatefulWidget {
  const HealthDemoScreen({super.key});

  @override
  State<HealthDemoScreen> createState() => _HealthDemoScreenState();
}

enum _DemoPhase { initial, loading, ready, failure }

class _HealthDemoScreenState extends State<HealthDemoScreen> {
  _DemoPhase _phase = _DemoPhase.initial;
  List<ActivitySegment> _segments = const [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _DemoPhase.loading;
      _errorMessage = null;
    });
    try {
      final healthRepository = getIt<HealthRepository>();
      // 诊断：插件侧 hasPermissions 走 HC datastore 的 getGrantedPermissions，
      // 与 requestAuthorization 的系统层返回可能不同步。
      final hasPerms = await healthRepository.hasPermissions();
      debugPrint('[health_demo] hasPermissions=$hasPerms');
      final isAuthorized = await healthRepository.requestPermissions();
      if (!isAuthorized) {
        setState(() {
          _phase = _DemoPhase.failure;
          _errorMessage = '未获得健康数据读取权限';
        });
        return;
      }
      final now = DateTime.now();
      final result = await getIt<FetchSegmentsUseCase>()(
        from: now.subtract(const Duration(hours: 24)),
        to: now,
      );
      switch (result) {
        case Success(:final data):
          AppLogger.info('近 24h 活动分段 ${data.length} 条', tag: 'health_demo');
          for (final segment in data) {
            debugPrint(
              '[health_demo] ${segment.type.name} '
              '${segment.start} → ${segment.end} (${segment.durationMinutes}min)',
            );
          }
          setState(() {
            _segments = data;
            _phase = _DemoPhase.ready;
          });
        case Failure(:final message, :final error):
          setState(() {
            _phase = _DemoPhase.failure;
            _errorMessage = message ?? '读取失败';
          });
          AppLogger.error('读取活动分段失败', tag: 'health_demo', error: error);
      }
    } on UnsupportedError {
      // health 插件在 Health Connect 不可用的设备上抛出（Android 14 以下未安装）
      setState(() {
        _phase = _DemoPhase.failure;
        _errorMessage = '此设备 Health Connect 不可用：'
            'Android 14 以下需安装 Health Connect 应用（模拟器常见）';
      });
      AppLogger.error('Health Connect 不可用', tag: 'health_demo');
    } catch (error) {
      setState(() {
        _phase = _DemoPhase.failure;
        _errorMessage = '$error';
      });
      AppLogger.error('健康数据链路异常', tag: 'health_demo', error: error);
    }
  }

  /// Demo 造数：写入一条 30 分钟的测试步数（W2 移除）。
  Future<void> _insertTestData() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(minutes: 30));
    try {
      final ok = await getIt<HealthRepository>().writeTestSteps(
        start: start,
        end: end,
        count: 1000,
      );
      debugPrint('[health_demo] writeTestSteps=$ok');
      if (ok) {
        await _load();
      }
    } catch (error) {
      debugPrint('[health_demo] writeTestSteps error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('W1 链路验证'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '引导页模板',
            onPressed: () => OnboardingScreenRoute.push(context),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'insert',
            tooltip: '写入测试步数（demo 造数）',
            onPressed: _insertTestData,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: switch (_phase) {
        _DemoPhase.initial ||
        _DemoPhase.loading => const Center(child: CircularProgressIndicator()),
        _DemoPhase.failure => _FailureView(message: _errorMessage ?? '读取失败'),
        _DemoPhase.ready => _SegmentListView(segments: _segments),
      },
    );
  }
}

class _SegmentListView extends StatelessWidget {
  const _SegmentListView({required this.segments});

  final List<ActivitySegment> segments;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return Center(
        child: Text('近 24h 无活动分段数据', style: AppTypography.body),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: segments.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final segment = segments[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeBadge(type: segment.type),
                    const Spacer(),
                    Text(
                      '${segment.durationMinutes} 分钟',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_formatTime(segment.start)} → ${_formatTime(segment.end)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '来源 ${segment.source} · ${segment.id}',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(time.month)}-${twoDigits(time.day)} '
        '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      ActivityType.sedentary => '久坐',
      ActivityType.stationary => '静止',
      ActivityType.walking => '步行',
      ActivityType.running => '跑步',
      ActivityType.active => '活动',
      ActivityType.other => '其他',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTypography.captionMedium),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTypography.body),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: null,
            child: const Text('请授权后点击右下角刷新'),
          ),
        ],
      ),
    );
  }
}
