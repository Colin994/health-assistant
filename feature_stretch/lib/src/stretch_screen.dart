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
    this.onOpenGarden,
  });

  final StretchState state;
  final ValueChanged<StretchIntent> onIntent;
  final void Function(BuildContext context, StretchAction action)?
  onActionTapped;

  /// 慢植物花园入口(由 app 壳注入,feature_stretch 不依赖 feature_game)。
  final VoidCallback? onOpenGarden;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: SafeArea(
        child: AppContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageMargin,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            state.headline,
                            style: AppTypography.display,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: '关闭',
                          color: context.tokens.textPrimary,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          onPressed: () => onIntent(const ClosePressed()),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.subCopy,
                      style: AppTypography.body.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.sourceLabel,
                      style: AppTypography.caption.copyWith(
                        color: context.tokens.textTertiary,
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
                        backgroundColor: context.tokens.primaryText,
                        foregroundColor: context.tokens.onPrimary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.pill),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onPressed: () => onIntent(
                        const FeedbackSelected(StretchFeedback.done),
                      ),
                      child: Text('做完了', style: AppTypography.subtitle),
                    ),
                    // 慢植物花园入口(2026-11 上线:拉伸的趣味替代,同层选项)。
                    if (onOpenGarden != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      TextButton.icon(
                        onPressed: onOpenGarden,
                        icon: const Icon(Icons.eco_outlined),
                        label: const Text('或者去花园接阳光'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryFeedbackButton(
                            label: '稍后提醒',
                            onTap: () => onIntent(
                              const FeedbackSelected(StretchFeedback.later),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _SecondaryFeedbackButton(
                            label: '今天别提醒',
                            onTap: () => onIntent(
                              const FeedbackSelected(StretchFeedback.muteToday),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => onIntent(const SkipThisPressed()),
                      child: const Text('本次不做'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: context.tokens.textSecondary,
                      ),
                      onPressed: () => onIntent(
                        const FeedbackSelected(StretchFeedback.neverAgain),
                      ),
                      child: const Text('不再提醒此类'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
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
          decoration: BoxDecoration(
            color: action.recommended
                ? context.tokens.primarySurface
                : context.tokens.surface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.name, style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      action.durationLabel,
                      style: AppTypography.caption.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.tokens.textTertiary,
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
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: context.tokens.textPrimary,
        side: BorderSide(color: context.tokens.textDisabled),
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
