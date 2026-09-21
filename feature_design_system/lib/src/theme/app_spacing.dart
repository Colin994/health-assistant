/// 间距 token（《设计规范.md §4》）。
///
/// 4 的倍数，8 为主节奏，16 为分区；页面左右边距 32。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;

  /// 分区间距（标题与内容块之间等）。
  static const double lg = 24;

  /// 页面级大分区（内容与底部按钮区之间）。
  static const double xl = 32;

  /// 页面左右边距（390 宽画板，内容区 326）。
  static const double pageMargin = 32;
}
