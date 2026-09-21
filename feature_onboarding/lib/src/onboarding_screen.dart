import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'onboarding_intent.dart';
import 'onboarding_state.dart';

/// 首启引导页：按步骤渲染设计稿 01–03 的三个差异化版式。
///
/// - 纯 UI 实现，不依赖 ViewModel，经 [onIntent] 上抛事件；
/// - 颜色/字号/圆角/间距一律引用设计 token，禁止散写魔法值。
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final OnboardingState state;
  final ValueChanged<OnboardingIntent> onIntent;

  /// 02 页健康标签静态选项（label + 辅助说明）。
  static const tagOptions = [
    (label: '颈椎不适', hint: '工作中提醒'),
    (label: '肩颈僵硬', hint: '工作中提醒'),
    (label: '腰部劳损', hint: '工作中提醒'),
    (label: '眼疲劳', hint: '工作中提醒'),
    (label: '只是久坐，没特殊不适', hint: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (state.step) {
        OnboardingStep.value => _ValueStep(
          key: const ValueKey('value'),
          onIntent: onIntent,
        ),
        OnboardingStep.tags => _TagsStep(
          key: const ValueKey('tags'),
          state: state,
          onIntent: onIntent,
        ),
        OnboardingStep.permissions => _PermissionsStep(
          key: const ValueKey('permissions'),
          state: state,
          onIntent: onIntent,
        ),
      },
    );
  }
}

/// 设计稿 01 首启-价值：手环通知卡模拟 + 主张 + 三卖点。
class _ValueStep extends StatelessWidget {
  const _ValueStep({super.key, required this.onIntent});

  final ValueChanged<OnboardingIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onIntent(const SkipPressed()),
                  child: const Text(
                    '跳过',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _WatchNotificationCard(),
              const SizedBox(height: AppSpacing.xl),
              const Text('最懂你工作节奏的', style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              const _SellingPoint(
                icon: Icons.schedule,
                title: '时机准',
                description: '手环判断你真的久坐了，不是定时闹钟',
              ),
              const _SellingPoint(
                icon: Icons.favorite_border,
                title: '懂你',
                description: '结合你的状况，说你听得进去的话',
              ),
              const _SellingPoint(
                icon: Icons.bolt_outlined,
                title: '零负担',
                description: '1 分钟拉伸，不用换衣服不用打卡',
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () => onIntent(const NextPressed()),
                child: const Text('开始使用', style: AppTypography.subtitle),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设计稿 01 顶部：模拟一条手环提醒通知。
class _WatchNotificationCard extends StatelessWidget {
  const _WatchNotificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.watch_later_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('坐了 55 分钟啦', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text('起来活动一下吧', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '健康提醒 · 现在',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellingPoint extends StatelessWidget {
  const _SellingPoint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(title, style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设计稿 02 首启-健康标签：身体状况标签多选 + 文案预览。
class _TagsStep extends StatelessWidget {
  const _TagsStep({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final OnboardingState state;
  final ValueChanged<OnboardingIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.textPrimary,
                  onPressed: () => onIntent(const BackPressed()),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                children: [
                  const Text('你的身体状况', style: AppTypography.display),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '让我们更懂你 · 可随时修改',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in OnboardingScreen.tagOptions)
                        _TagChip(
                          label: option.label,
                          hint: option.hint,
                          selected: state.selectedTags.contains(option.label),
                          onTap: () =>
                              onIntent(TagToggled(option.label)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    state.selectedTags.isEmpty
                        ? '选择标签后，提醒会像这样：'
                        : '已选「${state.selectedTags.first}」，提醒会像这样：',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Text(
                      '“低头一小时了，抬头看看远处吧——'
                      '顺便做个收下巴，30 秒”',
                      style: AppTypography.body.copyWith(height: 24 / 14),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: state.canProceedTags
                    ? () => onIntent(const NextPressed())
                    : null,
                child: const Text('下一步', style: AppTypography.subtitle),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: hint.isEmpty
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              )
            : const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.pill),
          ),
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
            hint.isEmpty
                ? Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodyMedium.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        hint,
                        style: AppTypography.micro.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

/// 设计稿 03 首启-权限引导：两步授权卡 + 免责说明。
class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final OnboardingState state;
  final ValueChanged<OnboardingIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: AppColors.textPrimary,
                  onPressed: () => onIntent(const BackPressed()),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                children: [
                  const Text('连接你的健康数据', style: AppTypography.display),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '两步授权，之后就不需要再管了',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _PermissionCard(
                    icon: Icons.favorite_outline,
                    title: '健康数据',
                    description: '读取活动与久坐记录，仅此而已。',
                    actionLabel: '去授权',
                    granted: state.healthGranted,
                    onTap: () => onIntent(const RequestHealthAccess()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PermissionCard(
                    icon: Icons.notifications_none,
                    title: '通知',
                    description: '提醒的唯一通道，可随时在系统中关闭。',
                    actionLabel: '去开启',
                    granted: state.notificationGranted,
                    onTap: () => onIntent(const RequestNotifications()),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '敏感数据；我们只读取活动与久坐记录，'
                              '不采集心率、睡眠等',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '数据仅用于为你生成提醒。',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMargin,
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () => onIntent(const NextPressed()),
                child: const Text('进入应用', style: AppTypography.subtitle),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.granted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          granted
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '已开启',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(actionLabel, style: AppTypography.captionMedium),
                ),
        ],
      ),
    );
  }
}
