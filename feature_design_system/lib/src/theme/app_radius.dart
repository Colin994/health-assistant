import 'package:flutter/material.dart';

/// 圆角 token（《设计规范.md §3》）。
///
/// 8–24 为主；胶囊形 chip 是这套设计的标志性形状。
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
  static const double xl = 24;

  /// 胶囊标签、分类 chip、按钮。
  static const double pill = 100;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);
}
