import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'reminder_settings_intent.dart';
import 'reminder_settings_state.dart';

/// 提醒设置页（设计稿 08）：密度三档 + 静音时段 + 测试提醒。
class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final ReminderSettingsState state;
  final ValueChanged<ReminderSettingsIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('提醒设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text('提醒密度', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final density in RemindDensity.values) ...[
                  if (density != RemindDensity.values.first)
                    const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DensityOption(
                      density: density,
                      selected: state.density == density,
                      onTap: () => onIntent(DensitySelected(density)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SettingsCard(
              title: '静音时段',
              subtitle: state.muteWindowLabel,
              onTap: () => onIntent(const MuteWindowTapped()),
            ),
            _SettingsCard(
              title: '午休静音',
              subtitle: state.lunchMuteLabel,
              onTap: () => onIntent(const LunchMuteTapped()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.currentLabel, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '自动降频：负面反馈过多时会自动放宽提醒。',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: TextButton(
                onPressed: () => onIntent(const TestReminderPressed()),
                child: Text(
                  '发一条试试 ›',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _DensityOption extends StatelessWidget {
  const _DensityOption({
    required this.density,
    required this.selected,
    required this.onTap,
  });

  final RemindDensity density;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.lg),
          ),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
        child: Column(
          children: [
            Text(
              density.label,
              style: AppTypography.bodyMedium.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              density.thresholdLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  Text(title, style: AppTypography.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
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
    );
  }
}
