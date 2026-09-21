import 'package:feature_design_system/feature_design_system.dart';
import 'package:flutter/material.dart';

import 'stretch_state.dart';

/// 动作详情页（设计稿 06）：步骤说明 + 倒计时 + 开始/返回。
///
/// 纯展示页（无业务流转），倒计时由 ScreenRoute 持有并经
/// [remainingSeconds] / [running] 注入，actionStartedOn / backOn 上抛。
class ActionDetailScreen extends StatelessWidget {
  const ActionDetailScreen({
    super.key,
    required this.action,
    required this.remainingSeconds,
    required this.running,
    required this.onStartPressed,
    required this.onBackPressed,
  });

  final StretchAction action;

  /// 剩余秒数（倒计时由 Route 持有，同 PageController 的归属先例）。
  final int remainingSeconds;

  /// 是否计时中。
  final bool running;

  final VoidCallback onStartPressed;
  final VoidCallback onBackPressed;

  String get _timeLabel {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final finished = remainingSeconds == 0;
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
                  onPressed: onBackPressed,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMargin,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(action.name, style: AppTypography.display),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(
                          action.durationLabel.split(' · ').first,
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(
                        Radius.circular(AppRadius.lg),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('缓慢侧向右肩', style: AppTypography.subtitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '轻微拉伸即可，不要用力下压。',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '缓慢将头侧向右肩，感到左侧颈部被轻轻拉住，'
                          '在末端保持数秒后回正，再换另一侧。',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '× 每侧 2 次',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: finished || running
                                    ? null
                                    : 1,
                                strokeWidth: 6,
                                color: AppColors.primarySurface,
                              ),
                              Center(
                                child: Text(
                                  _timeLabel,
                                  style: AppTypography.display.copyWith(
                                    fontSize: 32,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '剩余时间',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadius.pill),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onPressed: finished ? null : onStartPressed,
                    child: Text(
                      finished ? '✓ 完成' : (running ? '⏸ 暂停' : '▶ 开始'),
                      style: AppTypography.subtitle,
                    ),
                  ),
                  TextButton(
                    onPressed: onBackPressed,
                    child: Text(
                      '不做了，返回 ›',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
