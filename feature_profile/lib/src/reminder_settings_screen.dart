import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'reminder_settings_intent.dart';
import 'reminder_settings_state.dart';

/// 提醒设置页（设计稿 08 v8）：两级分组。
///
/// v8（2026-11-10 二轮评审）：
/// - 「提醒内容」：三类提醒同级——久坐拉伸（档位卡）/ 喝水提醒 / 护眼提醒；
/// - 「免打扰」：静音时段 / 午休静音（与提醒内容视觉分层）；
/// - 删除页底汇总卡与说明文字（信息密度；概要已在「我的」入口副标题）；
/// - 「发一条试试」移入 dev 开发者区块（v8），用户页不再展示。
class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final ReminderSettingsState state;
  final ValueChanged<ReminderSettingsIntent> onIntent;

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 静音时段选择器：起止两个时间选择（支持跨零点，如 22:00 → 07:00）。
  Future<void> _pickMuteWindow(BuildContext context) async {
    final start = await showTimePicker(
      context: context,
      helpText: '静音开始（如 22:00）',
      initialTime: TimeOfDay(
        hour: (state.nightMuteStart ~/ 60) % 24,
        minute: state.nightMuteStart % 60,
      ),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: '静音结束（如 07:00，可跨零点）',
      initialTime: TimeOfDay(
        hour: (state.nightMuteEnd ~/ 60) % 24,
        minute: state.nightMuteEnd % 60,
      ),
    );
    if (end == null || !context.mounted) return;
    if (start.hour * 60 + start.minute == end.hour * 60 + end.minute) {
      _toast(context, '起止时间相同，未修改');
      return;
    }
    onIntent(MuteWindowChanged(
      start.hour * 60 + start.minute,
      end.hour * 60 + end.minute,
    ));
    _toast(context, '已更新，下次提醒起生效');
  }

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

            // ---- 提醒内容（三类同级） ----
            const Text('提醒内容', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('久坐拉伸', style: AppTypography.bodyMedium),
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
                            onTap: () {
                              onIntent(DensitySelected(density));
                              _toast(
                                context,
                                state.sedentaryDisabled &&
                                        density != state.density
                                    ? '久坐提醒已恢复，下次提醒起生效'
                                    : '已更新，下次提醒起生效',
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _ToggleCard(
              title: '喝水提醒',
              subtitle: '每 45 分钟 · 一小杯就好',
              value: state.waterReminderEnabled,
              onChanged: (v) {
                onIntent(WaterReminderToggled(v));
                _toast(context, v ? '已开启喝水提醒' : '已关闭，进行中的倒计时不打断');
              },
            ),
            _ToggleCard(
              title: '护眼提醒',
              subtitle: '每 20 分钟 · 看 6 米外远处 20 秒',
              value: state.eyeReminderEnabled,
              onChanged: (v) {
                onIntent(EyeReminderToggled(v));
                _toast(context, v ? '已开启护眼提醒' : '已关闭，进行中的倒计时不打断');
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ---- 免打扰（与提醒内容分层） ----
            const Text('免打扰', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(
              title: '静音时段',
              subtitle: '${state.muteWindowLabel} · 静音时倒计时暂停',
              onTap: () => _pickMuteWindow(context),
            ),
            _ToggleCard(
              title: '午休静音',
              subtitle: '12:30 – 13:30 不提醒',
              value: state.lunchMuteEnabled,
              onChanged: (v) {
                onIntent(LunchMuteToggled(v));
                _toast(context, v ? '已开启午休静音' : '已关闭午休静音');
              },
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
          color: selected ? AppColors.primarySurface : AppColors.background,
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

/// 带开关的提醒卡片（喝水 / 护眼 / 午休静音）。
class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
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
