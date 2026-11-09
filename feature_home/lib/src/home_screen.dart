import 'package:base_utils/base_utils.dart';
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
            const SizedBox(height: AppSpacing.sm),
            // v5：三类倒计时提醒入口态（W2 接倒计时引擎后变实时）。
            const _CountdownChipsRow(),
            const SizedBox(height: AppSpacing.sm),
            _StepsTodayCard(steps: state.todaySteps),
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
            const _SectionTitle('下次提醒（倒计时）'),
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

/// 今日步数主卡（L4 传感器直读，2026-11-04 接入）。
///
/// 覆盖边界诚实标注：Detector 仅在监听期间计数（本机 Counter 传感器为
/// 死实现，无硬件累计兜底）——进程未运行期间的步数不计入。
class _StepsTodayCard extends StatelessWidget {
  const _StepsTodayCard({required this.steps});

  final int? steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
              Text(
                steps == null ? '—' : '$steps',
                style: AppTypography.display.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '步 · 今日',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            // dev 渠道保留采集边界的技术说明；master 只留一句可感知信息。
            // 2026-11-09 起基线本地续计：当日步数跨启动累计（口径已更新）。
            isDevBuild
                ? '当日跨启动累计（基线本地续计；平台无硬件计步累计，'
                    '息屏/后台期间不计）'
                : '今日累计 · 应用运行期间记录',
            style: AppTypography.micro.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// 三类倒计时提醒 chips：久坐拉伸 / 喝水 / 护眼（设计稿 04 v5）。
///
/// 当前为入口间隔展示（W2 倒计时引擎接入后刷新为剩余时间）；
/// 手表连接隐藏为设置页 Pro 功能后，首页不再展示手表数据源。
class _CountdownChipsRow extends StatelessWidget {
  const _CountdownChipsRow();

  static const _chips = [('久坐 · 55 分', Icons.chair), ('喝水 · 45 分', Icons.water_drop), ('护眼 · 20 分', Icons.visibility)];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (label, icon) in _chips)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
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
        const Icon(
          Icons.directions_walk,
          size: 16,
          color: AppColors.primary,
        ),
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
