import 'package:flutter/material.dart';

/// 色彩 token（《设计规范.md §1》）。
///
/// 双色系（青绿主色 + 墨绿文字）+ 白底；层级全部用主色/文字色的
/// 透明度阶梯表达，严禁另起新色相。
abstract final class AppColors {
  /// 主品牌色：选中态、强调文字、按钮、链接、标签。
  static const Color primary = Color(0xFF27C3B0);

  /// 主色背景上的文字。
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 标题与正文主色（墨绿炭，非纯黑）。
  static const Color textPrimary = Color(0xFF28332F);

  /// 次要信息：日期、作者、辅助说明（50%）。
  static const Color textSecondary = Color(0x8028332F);

  /// 占位符（30%）。
  static const Color textTertiary = Color(0x4D28332F);

  /// 不可用状态（10%）。
  static const Color textDisabled = Color(0x1A28332F);

  /// 页面底色。
  static const Color background = Color(0xFFFFFFFF);

  /// 卡片与浅灰分区。
  static const Color surface = Color(0xFFFAFAFA);

  /// 选中标签底色等浅色强调背景（主色 10%）。
  static const Color primarySurface = Color(0x1A27C3B0);

  /// 更浅的强调背景（主色 5%）。
  static const Color primarySurfaceDim = Color(0x0D27C3B0);

  /// 点缀高亮（柠檬黄，极少使用）。
  static const Color accentWarm = Color(0xFFFCFF7D);

  /// 红色警示（仅破坏性操作等极少数场景）。
  static const Color danger = Color(0xFFFF4747);

  /// 阴影色调（带品牌绿的投影，非黑影）。
  static const Color shadowTint = Color(0x33062522);
}

/// 阴影 token：层级靠圆角与留白，阴影极少且必须带绿调。
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowTint,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardSubtle = [
    BoxShadow(
      color: AppColors.shadowTint,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
