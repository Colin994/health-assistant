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
  /// 标签选项（静态 UI 数据，设计稿 02 v6）。
  ///
  /// 标签 → 提醒类型映射（W2 LLM Prompt 按提醒类型带对应子集）：
  /// 颈椎不适/肩颈僵硬/腰部劳损/只是久坐 → 久坐拉伸；
  /// 眼疲劳 → 护眼提醒；常忘喝水/咽干易上火 → 喝水提醒。
  static const tagOptions = [
    (label: '颈椎不适', hint: '工作中提醒'),
    (label: '肩颈僵硬', hint: '工作中提醒'),
    (label: '腰部劳损', hint: '工作中提醒'),
    (label: '眼疲劳', hint: '工作中提醒'),
    (label: '常忘喝水', hint: '到点提醒接水'),
    (label: '咽干易上火', hint: '文案更温和'),
    (label: noConditionTag, hint: ''),
  ];

  /// 「只是久坐，没特殊不适」兜底项（与身体状况类互斥）。
  static const noConditionTag = '只是久坐，没特殊不适';

  /// 身体状况类标签：与 [noConditionTag] 互斥；
  /// 习惯类（常忘喝水）独立，可与任一项共存。
  static const bodyConditionTags = {'颈椎不适', '肩颈僵硬', '腰部劳损', '眼疲劳', '咽干易上火'};

  /// 标签 → 预览示例文案（设计稿 02：选中后实时预览，让用户立刻感知个性化）。
  static const tagPreviewCopy = {
    '颈椎不适': '“低头一小时了，抬头看看远处吧——顺便做个收下巴，30 秒”',
    '肩颈僵硬': '“肩膀又硬成石头了吧？画个圈放松一下，60 秒就好”',
    '腰部劳损': '“腰有点僵了——站起来轻轻侧个身，40 秒”',
    '眼疲劳': '“盯屏 20 分钟了，看看 6 米外的远处，坚持 20 秒”',
    '常忘喝水': '“到点啦——起来接杯水，顺便走两步，一小口就好”',
    '咽干易上火': '“嗓子有点干吧？抿两口温水，别喝烫的”',
    noConditionTag: '“坐满 55 分钟啦——起来活动 1 分钟就好”',
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // 系统开启「移除动画」(Reduce Motion)时直接切换，不做渐变
      // （2026-11-12 audit P2：此前未读取 MediaQuery.disableAnimations）。
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
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

/// 设计稿 01 首启-价值：倒计时通知卡模拟 + 主张 + 三卖点。
class _ValueStep extends StatelessWidget {
  const _ValueStep({super.key, required this.onIntent});

  final ValueChanged<OnboardingIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: SafeArea(
        child: AppContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => onIntent(const SkipPressed()),
                    child: Text(
                      '跳过引导',
                      style: TextStyle(
                        color: context.tokens.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageMargin,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    const _CountdownNotificationCard(),
                    const SizedBox(height: AppSpacing.xl),
                    Text('工作间隙，记得休息', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '贴合你的办公节奏，轻声提醒、不打断心流',
                      style: AppTypography.body.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SellingPoint(
                      icon: Icons.schedule,
                      title: '时机准',
                      description: '倒计时到了才提醒，专注时不打扰',
                    ),
                    const _SellingPoint(
                      icon: Icons.favorite_border,
                      title: '懂你',
                      description: '结合你的身体状况，给做得到的微练习',
                    ),
                    const _SellingPoint(
                      icon: Icons.bolt_outlined,
                      title: '零负担',
                      description: '久坐、喝水、护眼，每次只需 1 分钟',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              const _StepDots(currentStep: 1, totalSteps: 3),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                child: FilledButton(
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
                  onPressed: () => onIntent(const NextPressed()),
                  child: Text('开始使用', style: AppTypography.subtitle),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设计稿 01 顶部：模拟一条倒计时提醒通知。
///
/// v5：手表连接暂未实现，卖点改为本地倒计时；手环场景
/// 由设置页「连接智能手表（Pro）」承接。
class _CountdownNotificationCard extends StatelessWidget {
  const _CountdownNotificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        boxShadow: AppShadows.cardSubtle,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.tokens.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 22,
              color: context.tokens.primaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('坐了 55 分钟', style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text('起来活动一下吧', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '健康提醒 · 现在',
                  style: AppTypography.micro.copyWith(
                    color: context.tokens.textSecondary,
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
          Icon(icon, size: 20, color: context.tokens.primary),
          const SizedBox(width: AppSpacing.md),
          Text(title, style: AppTypography.bodyMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: context.tokens.textSecondary,
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
  const _TagsStep({super.key, required this.state, required this.onIntent});

  final OnboardingState state;
  final ValueChanged<OnboardingIntent> onIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: SafeArea(
        child: AppContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    color: context.tokens.textPrimary,
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
                    Text('选择健康标签', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '选出符合你的情况，之后也可以在「我的」里修改',
                      style: AppTypography.body.copyWith(
                        color: context.tokens.textSecondary,
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
                            onTap: () => onIntent(TagToggled(option.label)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      state.selectedTags.isEmpty
                          ? '选择标签后，提醒会像这样：'
                          : '已选「${state.selectedTags.first}」，提醒会像这样：',
                      style: AppTypography.caption.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.tokens.surface,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.lg),
                        ),
                      ),
                      child: Text(
                        // 按首个选中标签实时预览（无选中时用兜底项示例）。
                        OnboardingScreen.tagPreviewCopy[state
                                .selectedTags
                                .isEmpty
                            ? OnboardingScreen.noConditionTag
                            : state.selectedTags.first]!,
                        style: AppTypography.body.copyWith(height: 24 / 14),
                      ),
                    ),
                  ],
                ),
              ),
              const _StepDots(currentStep: 2, totalSteps: 3),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                child: FilledButton(
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
                  onPressed: state.canProceedTags
                      ? () => onIntent(const NextPressed())
                      : null,
                  child: Text('下一步', style: AppTypography.subtitle),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
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
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? context.tokens.primarySurface
                : context.tokens.surface,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.pill),
            ),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected
                  ? context.tokens.primaryText
                  : context.tokens.textDisabled,
            ),
          ),
          child: hint.isEmpty
              ? Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: selected
                        ? context.tokens.primaryText
                        : context.tokens.textPrimary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected
                            ? context.tokens.primaryText
                            : context.tokens.textPrimary,
                      ),
                    ),
                    Text(
                      hint,
                      style: AppTypography.micro.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 设计稿 03 开启提醒：通知授权卡 + Pro 手表预告卡 + 免责说明。
///
/// v5：手表连接未实现，隐藏为设置页 Pro 付费功能；引导页仅预告。
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
      backgroundColor: context.tokens.background,
      body: SafeArea(
        child: AppContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    color: context.tokens.textPrimary,
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
                    Text('开启通知', style: AppTypography.display),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '开启通知，倒计时到了准时提醒你',
                      style: AppTypography.body.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _PermissionCard(
                      icon: Icons.notifications_none,
                      title: '通知',
                      description: '提醒的唯一通道，可随时在系统中关闭。',
                      actionLabel: '去开启',
                      granted: state.notificationGranted,
                      onTap: () => onIntent(const RequestNotifications()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _ProWatchCard(),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: context.tokens.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '本地倒计时触发，不采集任何个人健康数据',
                            style: AppTypography.caption.copyWith(
                              color: context.tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const _StepDots(currentStep: 3, totalSteps: 3),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                child: FilledButton(
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
                  onPressed: () => onIntent(const NextPressed()),
                  child: Text('进入应用', style: AppTypography.subtitle),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设计稿 03 卡片二：连接智能手表 Pro 预告（整卡点击，无冗余动词）。
class _ProWatchCard extends StatelessWidget {
  const _ProWatchCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pro 功能 · 即将上线，敬请期待')),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.tokens.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.watch_outlined,
                size: 22,
                color: context.tokens.primaryText,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('连接智能手表', style: AppTypography.subtitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '计划支持的 Pro 功能',
                    style: AppTypography.caption.copyWith(
                      color: context.tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.tokens.primaryText,
                borderRadius: BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                'PRO',
                style: AppTypography.micro.copyWith(
                  color: context.tokens.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.tokens.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 轻量进度指示点（替代「第 X 步，共 3 步」表单式文字，保留无障碍读屏语义）。
class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '第 $currentStep 步，共 $totalSteps 步',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= totalSteps; i++) ...[
            if (i > 1) const SizedBox(width: AppSpacing.sm),
            Container(
              width: i == currentStep ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == currentStep
                    ? context.tokens.primaryText
                    : context.tokens.textDisabled,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ],
        ],
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
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.tokens.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: context.tokens.primary),
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
                    color: context.tokens.textSecondary,
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
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: context.tokens.primaryText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '已开启',
                      style: AppTypography.captionMedium.copyWith(
                        color: context.tokens.primaryText,
                      ),
                    ),
                  ],
                )
              : OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.tokens.primaryText,
                    side: BorderSide(color: context.tokens.primary),
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
