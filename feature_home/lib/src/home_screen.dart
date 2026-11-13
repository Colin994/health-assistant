import 'package:core_model/core_model.dart';
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
    this.onOpenReminderSettings,
    this.gardenRefreshTick = 0,
  });

  final HomeState state;
  final ValueChanged<HomeIntent> onIntent;

  /// 快捷开始拉伸（开发入口，由 app 壳注入；W3 由通知深链替代）。
  final VoidCallback? onQuickStretch;

  /// 点击提醒 chips 跳「提醒设置」（交互文档 §4.1）。
  final VoidCallback? onOpenReminderSettings;

  /// 花园刷新信号(递增):变化即请求重读剩余次数。
  /// 常驻 IndexedStack 页不会自动重建，由壳层在游戏返回后递增。
  final int gardenRefreshTick;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(title: Text('今日')),
      floatingActionButton: onQuickStretch == null
          ? null
          : FloatingActionButton(
              tooltip: '快速拉伸（开发入口）',
              backgroundColor: context.tokens.primaryText,
              foregroundColor: context.tokens.onPrimary,
              onPressed: onQuickStretch,
              child: Icon(Icons.accessibility_new),
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
            _CountdownChipsRow(
              chips: state.chips,
              onTap: onOpenReminderSettings,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StepsTodayCard(steps: state.todaySteps),
            const SizedBox(height: AppSpacing.lg),
            if (state.showDeEscalationBanner) ...[
              _DeEscalationBanner(
                onAcknowledge: () =>
                    onIntent(const DeEscalationAcknowledged()),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
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
            // 花园剩余次数(信息展示;入口在「我的」页)。
            if (state.gardenQuotaRemaining != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  state.gardenQuotaRemaining! > 0
                      ? '☀️ 慢植物花园 · 今日还可获取阳光 '
                          '${state.gardenQuotaRemaining} 次'
                      : '☀️ 慢植物花园 · 今日阳光已获取完，明天再来',
                  style: AppTypography.caption.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (state.nextReminders.isNotEmpty) ...[
              const _SectionTitle('下次提醒'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < state.nextReminders.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: context.tokens.background),
                      _NextReminderRow(item: state.nextReminders[i]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
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
      decoration: BoxDecoration(
        color: context.tokens.surface,
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
                  color: context.tokens.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '步 · 今日',
                style: AppTypography.caption.copyWith(
                  color: context.tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '今日累计 · 应用运行期间记录',
            style: AppTypography.micro.copyWith(color: context.tokens.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// 三类倒计时提醒 chips（引擎投影：活倒计时/静音/稍后/免打扰态）。
///
/// 点击跳「提醒设置」（交互文档 §4.1）；关闭/禁用的类别不渲染。
class _CountdownChipsRow extends StatelessWidget {
  const _CountdownChipsRow({required this.chips, this.onTap});

  final List<ReminderChipView> chips;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final chip in chips)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Opacity(
              opacity: chip.dimmed ? 0.55 : 1,
              child: Container(
                // 垂直 padding 16 + 16px 内容行 = 48dp 触摸目标（Material 底线）。
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: context.tokens.primarySurface,
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.pill)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconOf(chip.kind), size: 14, color: context.tokens.primaryText),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      chip.sub == null
                          ? chip.label
                          : '${chip.label} · ${chip.sub}',
                      style: AppTypography.caption.copyWith(
                        color: context.tokens.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  static IconData _iconOf(ReminderKind kind) => switch (kind) {
        ReminderKind.sedentary => Icons.chair,
        ReminderKind.water => Icons.water_drop,
        ReminderKind.eye => Icons.visibility,
      };
}

/// 自动降频告知（FR-6：负面 >50% 自动放宽，App 内告知一次）。
class _DeEscalationBanner extends StatelessWidget {
  const _DeEscalationBanner({required this.onAcknowledge});

  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 16, color: context.tokens.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '最近「别提醒」有点多，已自动放宽提醒节奏，少打扰你',
              style: AppTypography.caption,
            ),
          ),
          TextButton(onPressed: onAcknowledge, child: Text('知道了')),
        ],
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
        Icon(
          Icons.directions_walk,
          size: 16,
          color: context.tokens.primaryText,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.refresh, size: 18),
          color: context.tokens.textSecondary,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.tokens.surface,
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
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 下次提醒单行（逐类一行，右侧时刻/状态）：降低信息密度，替代早期
/// 「久坐 14:30 · 喝水 14:50 · 护眼 15:10」单行拼串（2026-11-09 反馈）。
class _NextReminderRow extends StatelessWidget {
  const _NextReminderRow({required this.item});

  final NextReminderView item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Icon(_iconOf(item.kind), size: 16, color: context.tokens.primaryText),
          const SizedBox(width: AppSpacing.sm),
          Text(item.label, style: AppTypography.bodyMedium),
          Spacer(),
          Text(
            item.timeText,
            style: AppTypography.caption.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconOf(ReminderKind kind) => switch (kind) {
        ReminderKind.sedentary => Icons.chair,
        ReminderKind.water => Icons.water_drop,
        ReminderKind.eye => Icons.visibility,
      };
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
          Icon(Icons.check_circle, size: 16, color: context.tokens.primaryText),
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
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
