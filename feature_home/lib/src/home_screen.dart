import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'home_intent.dart';
import 'home_state.dart';

/// 今日页（设计稿 04）：数据源状态、提醒计数、下次预估与记录列表。
///
/// 纯 UI 实现，业务经 [onIntent] 上抛；底部 Tab 由 app 壳提供。
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onIntent,
    this.onQuickStretch,
  });

  final HomeState state;
  final ValueChanged<HomeIntent> onIntent;

  /// 快捷开始拉伸（W1 临时开发入口，由 app 壳注入；W3 由通知深链替代）。
  final VoidCallback? onQuickStretch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('今日')),
      floatingActionButton: onQuickStretch == null
          ? null
          : FloatingActionButton(
              tooltip: '快速拉伸（开发入口）',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              onPressed: onQuickStretch,
              child: const Icon(Icons.accessibility_new),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          children: [
            const SizedBox(height: AppSpacing.sm),
            _SourceStatusRow(
              label: state.dataSourceLabel,
              onRefresh: () => onIntent(const RefreshPressed()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    countLabel: '今天已提醒',
                    count: state.reminderCount,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    countLabel: '和你一起完成了',
                    count: state.completedCount,
                    emoji: '💪',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionTitle('下次提醒预估'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
              ),
              child: Text(
                state.nextEstimateText,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.records.isNotEmpty) ...[
              const _SectionTitle('今日记录'),
              const SizedBox(height: AppSpacing.sm),
              for (final record in state.records)
                _RecordRow(record: record),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SourceStatusRow extends StatelessWidget {
  const _SourceStatusRow({required this.label, required this.onRefresh});

  final String label;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.watch_later_outlined, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          color: AppColors.textSecondary,
          tooltip: '刷新',
          onPressed: onRefresh,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.countLabel,
    required this.count,
    this.emoji,
  });

  final String countLabel;
  final int count;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$count', style: AppTypography.headline),
              if (emoji != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(emoji!, style: AppTypography.caption),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            countLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.subtitle);
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final HomeRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${record.actionName} · ${record.timeLabel}',
              style: AppTypography.body,
            ),
          ),
          Text(
            record.statusLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
