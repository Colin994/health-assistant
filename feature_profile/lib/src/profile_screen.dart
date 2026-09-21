import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'profile_intent.dart';
import 'profile_state.dart';
import 'reminder_settings_screen_route.dart';

/// 我的页（设计稿 07）：健康标签 + 设置入口组。
///
/// 纯 UI 实现；底部 Tab 由 app 壳提供。
/// [devEntries] 为临时开发入口（由 app 壳注入，W2 路由表就绪后移除）。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onIntent,
    this.devEntries = const [],
  });

  final ProfileState state;
  final ValueChanged<ProfileIntent> onIntent;

  /// 开发者入口区条目（label + onTap），仅 debug 用途由壳注入。
  final List<(String, VoidCallback)> devEntries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('我的')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text('我的健康标签', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final tag in state.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '修改标签会即时影响下次提醒',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('设置', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            _SettingsRow(
              title: '提醒设置',
              subtitle: '密度 · 静音时段 · 测试提醒',
              onTap: () => ReminderSettingsScreenRoute.push(context),
            ),
            _SettingsRow(
              title: '隐私与数据说明',
              subtitle: '我们读取什么、存在哪',
              onTap: () => {},
            ),
            _SettingsRow(
              title: '关于',
              subtitle: '版本 ${state.version}',
              onTap: () => {},
            ),
            if (devEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text('开发者', style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.sm),
              for (final (label, onTap) in devEntries)
                _SettingsRow(title: label, subtitle: '', onTap: onTap),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
