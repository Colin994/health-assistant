import 'dart:developer' as developer;

/// 全局日志工具。
///
/// 统一经 `dart:developer` 输出，release 构建下由平台侧过滤；
/// 禁止在业务代码中直接调用 `print`。
class AppLogger {
  const AppLogger._();

  /// 调试日志：开发期链路跟踪。
  static void debug(String message, {String tag = 'app'}) =>
      developer.log(message, name: tag, level: 0);

  /// 信息日志：关键业务节点（规则触发、文案降级等）。
  static void info(String message, {String tag = 'app'}) =>
      developer.log(message, name: tag, level: 500);

  /// 错误日志：异常与失败链路。
  static void error(String message, {String tag = 'app', Object? error}) =>
      developer.log(message, name: tag, level: 1000, error: error);
}
