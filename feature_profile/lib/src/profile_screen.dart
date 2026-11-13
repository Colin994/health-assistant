import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'profile_intent.dart';
import 'profile_state.dart';

/// 我的页（设计稿 07 v8）：个人画像 Tab——提醒在上、健康标签在下。
///
/// v8（2026-11-10 二轮评审）：
/// - 「提醒」区块置顶（入口行 + 三类概要副标题）；
/// - 「健康标签」下沉：空态给添加引导，非空给「编辑」入口（标签编辑页），
///   保存自动开启对应提醒；
/// - v7 的区块命名「提醒节奏」与入口「提醒设置」割裂，v8 统一为「提醒」。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onIntent,
    this.onReminderSettings,
    this.onEditTags,
    this.onOpenGarden,
  });

  final ProfileState state;
  final ValueChanged<ProfileIntent> onIntent;

  /// 提醒设置入口（由 app 壳注入，跳本模块提醒设置页）。
  final VoidCallback? onReminderSettings;

  /// 标签编辑入口（跳本模块标签编辑页）。
  final VoidCallback? onEditTags;

  /// 慢植物花园入口（由 app 壳注入；2026-11 上线的唯一游戏入口）。
  final VoidCallback? onOpenGarden;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(title: Text('我的')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ---- 提醒（置顶：行为个性化入口） ----
            Text('提醒', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: onReminderSettings,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.tokens.surface,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('提醒设置', style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '久坐 · 喝水 · 护眼 · 免打扰',
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
            const SizedBox(height: AppSpacing.lg),

            // ---- 活动（行为域：慢植物花园；与「提醒」配置域并列） ----
            if (onOpenGarden != null) ...[
              Text('活动', style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: onOpenGarden,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.tokens.surface,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('慢植物花园', style: AppTypography.bodyMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '照顾植物 · 接阳光练颈椎',
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
              const SizedBox(height: AppSpacing.lg),
            ],

            // ---- 健康标签（内容个性化；空态给添加引导） ----
            Row(
              children: [
                Expanded(
                  child: Text('健康标签', style: AppTypography.subtitle),
                ),
                TextButton(
                  onPressed: onEditTags,
                  child: Text(state.tags.isEmpty ? '去添加' : '编辑'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.tags.isEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: onEditTags,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.tokens.surface,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: context.tokens.primaryText,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '选择健康标签，提醒会更懂你',
                          style: AppTypography.caption.copyWith(
                            color: context.tokens.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
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
                      decoration: BoxDecoration(
                        color: context.tokens.primarySurface,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.tokens.primaryText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '修改后下次提醒生效',
                style: AppTypography.caption.copyWith(
                  color: context.tokens.textSecondary,
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
