import '../../models/ai_config.dart';
import '../../models/ai_message.dart';
import '../../models/ai_response.dart';

/// AI异常基类
abstract class AIException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AIException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AIException: $message';
}

/// API密钥异常
class ApiKeyException extends AIException {
  ApiKeyException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'Invalid or missing API key',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// 速率限制异常
class RateLimitException extends AIException {
  RateLimitException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'Rate limit exceeded',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// 网络连接异常
class NetworkException extends AIException {
  NetworkException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'Network connection failed',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// 超时异常
class TimeoutException extends AIException {
  TimeoutException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'Request timeout',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// 内容过滤异常
class ContentFilterException extends AIException {
  ContentFilterException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'Content filtered by policy',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// 配额异常
class QuotaException extends AIException {
  QuotaException({
    String? message,
    int? statusCode,
    dynamic originalError,
  }) : super(
          message: message ?? 'API quota exceeded',
          statusCode: statusCode,
          originalError: originalError,
        );
}

/// AI适配器基础接口
/// 所有AI供应商适配器必须实现此接口
abstract class AIAdapter {
  /// 配置信息
  AIConfig get config;

  /// 发送单个消息并获取响应
  /// [messages] 消息列表
  /// [config] 可选的配置覆盖
  Future<AIResponse> sendMessage(
    List<AIMessage> messages, {
    AIConfig? config,
  });

  /// 流式发送消息
  /// [messages] 消息列表
  /// [config] 可选的配置覆盖
  /// [onChunk] 接收每个数据块的回调
  Stream<AIStreamChunk> sendMessageStream(
    List<AIMessage> messages, {
    AIConfig? config,
    void Function(AIStreamChunk)? onChunk,
  });

  /// 验证API密钥是否有效
  Future<bool> validateApiKey();

  /// 获取可用模型列表
  Future<List<String>> getAvailableModels();

  /// 计算消息的token数（估算）
  int estimateTokens(List<AIMessage> messages);

  /// 获取适配器名称
  String get adapterName;

  /// 获取适配器版本
  String get adapterVersion;

  /// 检查配置是否完整
  bool get isConfigured;

  /// 释放资源
  void dispose();
}

/// AI适配器基类
/// 提供通用的实现，子类只需实现特定方法
abstract class BaseAIAdapter implements AIAdapter {
  @override
  AIConfig get config;

  @override
  bool get isConfigured {
    if (!config.provider.requiresApiKey) return true;
    return config.apiKey.isNotEmpty;
  }

  @override
  int estimateTokens(List<AIMessage> messages) {
    // 简单估算：大约4个字符等于1个token
    // 这是粗略估计，实际实现应该使用tokenizer
    final totalChars = messages.fold<int>(
      0,
      (sum, msg) => sum + msg.content.length,
    );
    return (totalChars / 4).ceil();
  }

  @override
  void dispose() {
    // 默认不做任何操作
  }

  /// 创建请求ID
  String createRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${config.model}';
  }

  /// 处理HTTP错误
  Never handleError(dynamic error, [int? statusCode]) {
    if (error is AIException) {
      throw error;
    }

    final message = error.toString();

    // 根据状态码或消息内容判断错误类型
    if (statusCode == 401 ||
        message.contains('api key') ||
        message.contains('unauthorized')) {
      throw ApiKeyException(
        message: 'Invalid API key',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (statusCode == 429 || message.contains('rate limit')) {
      throw RateLimitException(
        message: 'Rate limit exceeded',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (statusCode == 402 ||
        message.contains('quota') ||
        message.contains('billing')) {
      throw QuotaException(
        message: 'API quota exceeded',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (statusCode == 400 && message.contains('content')) {
      throw ContentFilterException(
        message: 'Content filtered',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (error is NetworkException || error is TimeoutException) {
      throw error;
    }

    // 默认网络异常
    throw NetworkException(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }
}

/// 适配器工厂接口
abstract class AIAdapterFactory {
  /// 根据配置创建适配器
  AIAdapter createAdapter(AIConfig config);

  /// 获取支持的供应商列表
  List<AIProvider> get supportedProviders;
}
