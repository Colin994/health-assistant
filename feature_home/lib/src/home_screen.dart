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

  /// 点击提醒设置入口跳「提醒设置」（交互文档 §4.1）。
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageMargin,
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),
            _StepsTodayCard(
              steps: state.todaySteps,
              status: state.dataSourceLabel,
              onAction: () => onIntent(const RefreshPressed()),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.showDeEscalationBanner) ...[
              _DeEscalationBanner(
                onAcknowledge: () => onIntent(const DeEscalationAcknowledged()),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  '已提醒 ${state.reminderCount} 次',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  '已完成 ${state.completedCount} 次',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
            // 花园剩余次数(信息展示;入口在「我的」页)。
            if (state.gardenQuotaRemaining != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  state.gardenQuotaRemaining! > 0
                      ? '慢植物花园 · 今日还可获取阳光 '
                            '${state.gardenQuotaRemaining} 次'
                      : '慢植物花园 · 今日阳光已获取完，明天再来',
                  style: AppTypography.caption.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            if (state.nextReminders.isNotEmpty ||
                onOpenReminderSettings != null) ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const _SectionTitle('下次提醒'),
                  if (onOpenReminderSettings != null)
                    TextButton(
                      onPressed: onOpenReminderSettings,
                      child: const Text('提醒设置'),
                    ),
                ],
              ),
              if (state.nextReminders.isEmpty) const Text('暂无启用的提醒'),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
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
              for (final record in state.records) _RecordRow(record: record),
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
  const _StepsTodayCard({
    required this.steps,
    required this.status,
    required this.onAction,
  });

  final int? steps;
  final String status;
  final VoidCallback onAction;

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
          const _SectionTitle('今日步数'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            steps == null || status == '步数权限未开启' ? '—' : '$steps 步',
            style: AppTypography.display.copyWith(
              color: context.tokens.primaryText,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                status.replaceFirst('今日步数 · ', ''),
                style: AppTypography.caption,
              ),
              if (status != '当前设备不支持计步')
                TextButton(
                  onPressed: onAction,
                  child: Text(status == '步数权限未开启' ? '去设置' : '刷新'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '今日累计 · 应用运行期间记录',
            style: AppTypography.micro.copyWith(
              color: context.tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.timeText,
              textAlign: TextAlign.end,
              style: AppTypography.caption.copyWith(
                color: context.tokens.textSecondary,
              ),
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
