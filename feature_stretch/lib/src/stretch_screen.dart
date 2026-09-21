import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'stretch_intent.dart';
import 'stretch_state.dart';

/// 拉伸页（设计稿 05）：提醒文案 + 动作列表 + 四态反馈。
///
/// 纯 UI 实现，业务经 [onIntent] 上抛；动作点击经 [onActionTapped]
/// 由 Route 直接导航到动作详情（06）。
class StretchScreen extends StatelessWidget {
  const StretchScreen({
    super.key,
    required this.state,
    required this.onIntent,
    this.onActionTapped,
  });

  final StretchState state;
  final ValueChanged<StretchIntent> onIntent;
  final void Function(BuildContext context, StretchAction action)?
      onActionTapped;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.textPrimary,
                onPressed: () => onIntent(const ClosePressed()),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                children: [
                  Text(state.headline, style: AppTypography.display),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.subCopy,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.sourceLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.sectionLabel,
                          style: AppTypography.subtitle,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onIntent(const SkipThisPressed()),
                        child: Text(
                          '跳过这个 ›',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final action in state.actions)
                    _ActionCard(
                      action: action,
                      onTap: () => onActionTapped?.call(context, action),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.pill),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: () =>
                        onIntent(const FeedbackSelected(StretchFeedback.done)),
                    child: const Text('✓ 做完了', style: AppTypography.subtitle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryFeedbackButton(
                          label: '⏱ 稍后提醒',
                          onTap: () => onIntent(
                            const FeedbackSelected(StretchFeedback.later),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _SecondaryFeedbackButton(
                          label: '☾ 今天别提醒',
                          onTap: () => onIntent(
                            const FeedbackSelected(StretchFeedback.muteToday),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SecondaryFeedbackButton(
                    label: '✕ 别再提醒这类',
                    onTap: () => onIntent(
                      const FeedbackSelected(StretchFeedback.neverAgain),
                    ),
                    full: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final StretchAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(action.name, style: AppTypography.subtitle),
                        if (action.recommended) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.all(
                                Radius.circular(AppRadius.pill),
                              ),
                            ),
                            child: Text(
                              '推荐',
                              style: AppTypography.microMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      action.durationLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryFeedbackButton extends StatelessWidget {
  const _SecondaryFeedbackButton({
    required this.label,
    required this.onTap,
    this.full = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool full;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.textDisabled),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      ),
      onPressed: onTap,
      child: Text(label, style: AppTypography.captionMedium),
    );
  }
}
