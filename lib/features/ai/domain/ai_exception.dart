/// Base exception class for AI-related errors.
///
/// Sealed hierarchy ensures exhaustive error handling at compile time.
/// Each subclass provides a user-friendly Chinese message for display.
sealed class AIException implements Exception {
  final String message;

  const AIException(this.message);

  /// User-friendly error message in Chinese per D-14.
  String get userMessage;

  /// Surfaces [message] so logs/diagnostics show the real classified detail
  /// (e.g. "AIStreamException: ApiException: ...") instead of the default
  /// opaque "Instance of 'AIStreamException'". Without this override the
  /// OpenAIAdapter._safeDiagnostic redaction work is invisible — every
  /// real-API failure logged as a typeless black box (root-caused via the
  /// real BigModel key, 2026-06-17).
  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when API key authentication fails (401/403).
class AIAuthException extends AIException {
  const AIAuthException([super.message = 'API Key 无效，请检查设置']);

  @override
  String get userMessage => 'API Key 无效，请检查设置';
}

/// Thrown when API rate limit is exceeded (429).
class AIRateLimitException extends AIException {
  const AIRateLimitException([super.message = '请求太快，请稍后再试']);

  @override
  String get userMessage => '请求太快，请稍后再试';
}

/// Thrown when network connectivity fails.
class AINetworkException extends AIException {
  const AINetworkException([super.message = '网络连接失败']);

  @override
  String get userMessage => '网络连接失败';
}

/// Thrown when AI stream generation is interrupted.
class AIStreamException extends AIException {
  const AIStreamException([super.message = '生成中断，可继续编辑或重试']);

  @override
  String get userMessage => '生成中断，可继续编辑或重试';
}
