import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'settings_state.dart';

/// 设置页（设计稿 09）：通用设置 + 开发者入口。
///
/// 纯 UI 实现；底部 Tab 由 app 壳提供。
/// - [onReminderSettings]：提醒设置入口（跳 feature_profile 的提醒设置页，
///   由 app 壳注入避免跨 feature 依赖）；
/// - [devEntries]：开发者入口区条目（label + onTap，由 app 壳注入，
///   正式版构建传空数组即可隐藏整个区块）。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.state,
    required this.onReminderSettings,
    this.devEntries = const [],
  });

  final SettingsState state;
  final VoidCallback onReminderSettings;

  /// 开发者入口区条目（label + onTap），仅 debug 用途由壳注入。
  final List<(String, VoidCallback)> devEntries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Text('通用', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            _SettingsRow(
              title: '连接智能手表',
              subtitle: '久坐判定更准 · Pro 即将上线',
              badge: const _ProBadge(),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pro 功能 · 即将上线，敬请期待')),
                );
              },
            ),
            _SettingsRow(
              title: '提醒设置',
              subtitle: '久坐 · 喝水 · 护眼 · 静音时段',
              onTap: onReminderSettings,
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                '仅调试构建显示 · 正式版隐藏',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  /// 标题右侧徽标（如 PRO）。
  final Widget? badge;

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
                  Row(
                    children: [
                      // 窄屏下标题 + 徽标同行可能溢出，标题 Flexible 兜底。
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        badge!,
                      ],
                    ],
                  ),
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

/// Pro 付费功能徽标（设计稿 09 v5）。
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        'PRO',
        style: AppTypography.micro.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
