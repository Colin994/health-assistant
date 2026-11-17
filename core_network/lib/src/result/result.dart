/// Result 模式：统一 API 错误响应的包装（架构文档 3.5）。
///
/// 调用侧通过 switch 对具体子类型做穷尽匹配，避免散落的 try/catch。
sealed class Result<T> {
  const Result();
}

/// 成功响应，携带业务数据。
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// 失败响应：错误码 + 可重试标记 + 兜底文案键。
final class Failure<T> extends Result<T> {
  const Failure({
    required this.code,
    this.message,
    this.isRetryable = false,
    this.fallbackTextKey,
    this.error,
  });

  /// 稳定错误码（如 `network.timeout` / `server.busy`）。
  final String code;

  /// 供日志使用的原始错误描述，不直接展示给用户。
  final String? message;

  /// 是否值得自动/手动重试。
  final bool isRetryable;

  /// 静态兜底文案的 l10n key（技术设计文档 §6.3 降级策略）。
  final String? fallbackTextKey;

  /// 原始异常，用于日志定位。
  final Object? error;
}
