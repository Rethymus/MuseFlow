import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_adapter.dart';
import '../../../models/ai_config.dart';
import '../../../models/ai_message.dart';
import '../../../models/ai_response.dart';

/// 基础AI适配器抽象类
/// 提供共享的HTTP请求构建、响应解析和错误处理逻辑
abstract class BaseAIAdapterImpl implements AIAdapter {
  @override
  final AIConfig config;

  final http.Client _client;
  static const String _defaultAdapterVersion = '1.0.0';

  BaseAIAdapterImpl({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get adapterVersion => _defaultAdapterVersion;

  @override
  bool get isConfigured {
    if (!config.provider.requiresApiKey) return true;
    return config.apiKey.isNotEmpty;
  }

  @override
  int estimateTokens(List<AIMessage> messages) {
    // 简单估算：大约4个字符等于1个token
    final totalChars = messages.fold<int>(
      0,
      (sum, msg) => sum + msg.content.length,
    );
    return (totalChars / 4).ceil();
  }

  @override
  void dispose() {
    _client.close();
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
    if (statusCode == 401 || message.contains('api key') || message.contains('unauthorized')) {
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

    if (statusCode == 402 || message.contains('quota') || message.contains('billing')) {
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
      rethrow;
    }

    // 默认网络异常
    throw NetworkException(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }

  /// 构建标准HTTP请求头
  Map<String, String> buildStandardHeaders({bool requiresApiKey = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresApiKey && config.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    return headers;
  }

  /// 处理错误响应
  void handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'Request failed with status $statusCode';

    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData.containsKey('error')) {
        final error = errorData['error'];
        if (error is Map) {
          message = error['message']?.toString() ?? message;
        } else if (error is String) {
          message = error;
        }
      }
    } catch (e) {
      // Ignore JSON parse errors
    }

    handleError(message, statusCode);
  }

  /// 格式化消息为API标准格式
  Map<String, dynamic> formatMessage(AIMessage message) {
    return {
      'role': message.role.toApiString(),
      'content': message.content,
    };
  }

  /// 执行HTTP请求（带重试逻辑）
  Future<http.Response> executeRequest(
    Future<http.Response> Function() requestFn, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    dynamic lastError;

    while (attempt < maxRetries) {
      try {
        return await requestFn();
      } catch (e) {
        lastError = e;
        attempt++;

        // 如果是认证错误或内容过滤错误，不重试
        if (e is ApiKeyException || e is ContentFilterException) {
          rethrow;
        }

        // 如果是速率限制错误，等待更长时间
        if (e is RateLimitException) {
          await Future.delayed(retryDelay * attempt);
          continue;
        }

        // 最后一次尝试失败，抛出异常
        if (attempt >= maxRetries) {
          break;
        }

        await Future.delayed(retryDelay);
      }
    }

    throw lastError;
  }

  /// 解析OpenAI格式的响应
  AIResponse parseOpenAIResponse(http.Response response, AIConfig config) {
    final data = jsonDecode(response.body);

    try {
      final choice = data['choices'][0];
      final message = choice['message'];
      final usage = data['usage'];

      return AIResponse(
        id: data['id'] ?? createRequestId(),
        content: message['content'] ?? '',
        model: data['model'] ?? config.model,
        inputTokens: usage?['prompt_tokens'],
        outputTokens: usage?['completion_tokens'],
        totalTokens: usage?['total_tokens'],
        finishReason: choice['finish_reason'],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Invalid response format: ${e.toString()}');
    }
  }

  /// 解析OpenAI格式的流式响应
  Stream<AIStreamChunk> parseOpenAIStreamResponse(
    http.Response response,
    AIConfig config,
  ) async* {
    final lines = response.body.split('\n');
    String fullContent = '';

    for (final line in lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      if (line == 'data: [DONE]') break;

      if (line.startsWith('data: ')) {
        try {
          final jsonStr = line.substring(6);
          final data = jsonDecode(jsonStr);

          final choice = data['choices']?[0];
          if (choice == null) continue;

          final delta = choice['delta'];
          final content = delta?['content']?.toString() ?? '';

          if (content.isNotEmpty) {
            fullContent += content;
            yield AIStreamChunk.incomplete(content);
          }

          final finishReason = choice['finish_reason'];
          if (finishReason != null) {
            final usage = data['usage'];
            yield AIStreamChunk.complete(
              content: fullContent,
              finishReason: finishReason,
              inputTokens: usage?['prompt_tokens'],
              outputTokens: usage?['completion_tokens'],
            );
          }
        } catch (e) {
          // Skip malformed JSON
          continue;
        }
      }
    }
  }

  /// 获取HTTP客户端
  http.Client get client => _client;
}

/// 抽象请求构建器
abstract class AIRequestBuilder {
  /// 构建请求URL
  Uri buildUrl(AIConfig config, bool stream);

  /// 构建请求头
  Map<String, String> buildHeaders(AIConfig config);

  /// 构建请求体
  Map<String, dynamic> buildBody(
    List<AIMessage> messages,
    AIConfig config,
    bool stream,
  );
}

/// 抽象响应解析器
abstract class StreamResponseParser {
  /// 解析单个响应
  AIResponse parseResponse(http.Response response, AIConfig config);

  /// 解析流式响应
  Stream<AIStreamChunk> parseStream(
    http.Response response,
    AIConfig config,
  );
}

/// OpenAI兼容的请求构建器
class OpenAIRequestBuilder implements AIRequestBuilder {
  @override
  Uri buildUrl(AIConfig config, bool stream) {
    return Uri.parse('${config.effectiveBaseUrl}/chat/completions');
  }

  @override
  Map<String, String> buildHeaders(AIConfig config) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };
  }

  @override
  Map<String, dynamic> buildBody(
    List<AIMessage> messages,
    AIConfig config,
    bool stream,
  ) {
    final body = <String, dynamic>{
      'model': config.model,
      'messages': messages.map((msg) => _formatMessage(msg)).toList(),
      'stream': stream,
    };

    // 添加参数
    if (config.modelParameters != null) {
      body.addAll(config.modelParameters!);
    }

    // 只有在非流式请求时添加这些参数
    if (!stream) {
      body['max_tokens'] = config.maxTokens;
      body['temperature'] = config.temperature;
    }

    return body;
  }

  Map<String, dynamic> _formatMessage(AIMessage message) {
    return {
      'role': message.role.toApiString(),
      'content': message.content,
    };
  }
}

/// OpenAI兼容的响应解析器
class OpenAIResponseParser implements StreamResponseParser {
  final String Function() _requestIdGenerator;

  OpenAIResponseParser({required String Function() requestIdGenerator})
      : _requestIdGenerator = requestIdGenerator;

  @override
  AIResponse parseResponse(http.Response response, AIConfig config) {
    final data = jsonDecode(response.body);

    try {
      final choice = data['choices'][0];
      final message = choice['message'];
      final usage = data['usage'];

      return AIResponse(
        id: data['id'] ?? _requestIdGenerator(),
        content: message['content'] ?? '',
        model: data['model'] ?? config.model,
        inputTokens: usage?['prompt_tokens'],
        outputTokens: usage?['completion_tokens'],
        totalTokens: usage?['total_tokens'],
        finishReason: choice['finish_reason'],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Invalid response format: ${e.toString()}');
    }
  }

  @override
  Stream<AIStreamChunk> parseStream(
    http.Response response,
    AIConfig config,
  ) async* {
    final lines = response.body.split('\n');
    String fullContent = '';

    for (final line in lines) {
      if (line.isEmpty || line.startsWith(':')) continue;
      if (line == 'data: [DONE]') break;

      if (line.startsWith('data: ')) {
        try {
          final jsonStr = line.substring(6);
          final data = jsonDecode(jsonStr);

          final choice = data['choices']?[0];
          if (choice == null) continue;

          final delta = choice['delta'];
          final content = delta?['content']?.toString() ?? '';

          if (content.isNotEmpty) {
            fullContent += content;
            yield AIStreamChunk.incomplete(content);
          }

          final finishReason = choice['finish_reason'];
          if (finishReason != null) {
            final usage = data['usage'];
            yield AIStreamChunk.complete(
              content: fullContent,
              finishReason: finishReason,
              inputTokens: usage?['prompt_tokens'],
              outputTokens: usage?['completion_tokens'],
            );
          }
        } catch (e) {
          // Skip malformed JSON
          continue;
        }
      }
    }
  }
}