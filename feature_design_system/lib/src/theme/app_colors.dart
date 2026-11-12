import 'package:flutter/material.dart';

/// 色彩 token（《设计规范.md §1》）。
///
/// 双色系（青绿主色 + 墨绿文字）+ 白底；强调背景走主色透明度阶梯，
/// 文字色为绿灰实色并满足对比度预算（正文/辅助文字 ≥4.5:1），
/// 严禁另起新色相。
abstract final class AppColors {
  /// 主品牌色：选中态边框、按钮/徽章底、大图形。不作小字文字色
  /// （对白底仅约 2.0:1），文字与功能性图标一律用 [primaryText]。
  static const Color primary = Color(0xFF27C3B0);

  /// 深青绿文字色（同色相加深）：小字文字与功能性图标专用。
  /// 白底约 5.2:1、青绿 10% 底约 4.8:1，过 WCAG AA（2026-11-12 对比度整改）。
  static const Color primaryText = Color(0xFF0B7A6D);

  /// 主色背景上的文字。
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 标题与正文主色（墨绿炭，非纯黑）。
  static const Color textPrimary = Color(0xFF28332F);

  /// 次要信息：日期、作者、辅助说明（绿灰实色，白底约 6.3:1）。
  static const Color textSecondary = Color(0xFF5A625F);

  /// 占位符（绿灰实色，白底约 4.9:1）。
  static const Color textTertiary = Color(0xFF6B7370);

  /// 不可用状态（10%，仅装饰：分隔线、无信息 chevron）。
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
