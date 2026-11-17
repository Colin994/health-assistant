import 'package:flutter/widgets.dart';

/// 将可读内容限制在 840dp 内，并在宽屏上居中。
///
/// 页面背景和 AppBar 仍占满窗口；列表、表单与底部操作区保持可读宽度，
/// 用于 iPad、横屏和多任务窗口。
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({super.key, required this.child});

  static const double maxWidth = 840;
  static const ValueKey<String> contentKey = ValueKey<String>(
    'app-content-width-content',
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, maxWidth).toDouble();
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: contentKey,
            width: width,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
