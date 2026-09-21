import 'package:flutter/material.dart';

/// 字体排印 token（《设计规范.md §2》）。
///
/// 字号跨度小（10–24），层级靠字重（400/500/600）和颜色透明度区分。
/// 中文场景以系统字体渲染；数字/英文后续接 Poppins 双字体栈（W2 引入字体文件）。
abstract final class AppTypography {
  /// display：页面大标题。
  static const TextStyle display = TextStyle(
    fontSize: 24,
    height: 36 / 24,
    fontWeight: FontWeight.w600,
  );

  /// headline：数字、卡片标题。
  static const TextStyle headline = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
  );

  /// title：区块标题、用户名。
  static const TextStyle title = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  /// subtitle：卡片标题、Tab 文字。
  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w600,
  );

  /// body：正文、列表项。
  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );

  /// bodyMedium：需要强调的正文。
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
  );

  /// caption：辅助说明、标签文字。
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  /// captionMedium：需要强调的辅助说明。
  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
  );

  /// micro：时间戳、分类 chip。
  static const TextStyle micro = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w400,
  );

  /// microMedium：需要强调的 micro 文案。
  static const TextStyle microMedium = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w500,
  );

  /// Material TextTheme 映射：供 ThemeData 使用。
  static const TextTheme textTheme = TextTheme(
    displaySmall: display,
    headlineSmall: headline,
    titleLarge: title,
    titleMedium: subtitle,
    bodyMedium: body,
    bodySmall: caption,
    labelSmall: micro,
  );
}
