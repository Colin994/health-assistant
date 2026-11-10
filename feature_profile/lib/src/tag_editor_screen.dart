import 'package:core_profile/core_profile.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'tag_editor_intent.dart';
import 'tag_editor_state.dart';

/// 标签编辑页（v8，设计口径同引导 02：胶囊多选 + 互斥）。
///
/// 保存后自动开启对应提醒（加法式）并即时刷新引擎；
/// 由「我的 → 健康标签 → 编辑/去添加」进入。
class TagEditorScreen extends StatelessWidget {
  const TagEditorScreen({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final TagEditorState state;
  final ValueChanged<TagEditorIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('编辑健康标签')),
      body: SafeArea(
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
                  const Text('你的身体状况与习惯', style: AppTypography.display),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '勾选符合的项，提醒会更懂你 · 保存后自动开启对应提醒',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tag in HealthTagCatalog.options)
                        _TagChip(
                          label: tag,
                          selected: state.selectedTags.contains(tag),
                          onTap: () => onIntent(TagToggled(tag)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
                vertical: AppSpacing.md,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: state.saving ? null : () => onIntent(const SavePressed()),
                child: Text(
                  state.saving ? '保存中…' : '保存',
                  style: AppTypography.subtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
