import 'package:base_utils/base_utils.dart';
import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'profile_intent.dart';
import 'profile_state.dart';

/// 我的页（设计稿 07）：健康标签档案。
///
/// 纯 UI 实现；底部 Tab 由 app 壳提供。
/// v3 信息架构调整：设置区块（提醒设置/隐私/关于）与开发者入口
/// 已移至「设置」Tab（feature_settings，设计稿 09）。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.state,
    required this.onIntent,
  });

  final ProfileState state;
  final ValueChanged<ProfileIntent> onIntent;

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
            Text(
              // dev 渠道提示开发者区块去向；master 不提开发者概念。
              isDevBuild ? '设置与开发者选项已移至「设置」页' : '提醒设置等功能请见「设置」页',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
