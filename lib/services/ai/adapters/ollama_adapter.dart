import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/ai_config.dart';
import '../../../models/ai_message.dart';
import '../../../models/ai_response.dart';
import 'base_ai_adapter.dart';

/// Ollama API适配器
/// Ollama是一个本地运行的开源LLM工具
class OllamaAdapter extends BaseAIAdapterImpl {
  static const String _adapterName = 'OllamaAdapter';

  OllamaAdapter({
    required super.config,
    super.client,
  });

  @override
  String get adapterName => _adapterName;

  @override
  Future<bool> validateApiKey() async {
    try {
      // Ollama不需要API Key，检查服务是否可用
      final response = await client
          .get(
        Uri.parse('${config.effectiveBaseUrl}/tags'),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Ollama service not responding',
          );
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is TimeoutException) {
        rethrow;
      }
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await client
          .get(
            Uri.parse('${config.effectiveBaseUrl}/tags'),
          )
          .timeout(
            Duration(seconds: config.effectiveTimeout),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        if (models != null) {
          return models
              .map((model) => model['name'] as String)
              .map((name) => name.split(':').first) // 移除tag部分
              .toList();
        }
      }

      // 返回默认推荐模型
      return _getDefaultModels();
    } catch (e) {
      // 返回默认推荐模型
      return _getDefaultModels();
    }
  }

  List<String> _getDefaultModels() {
    return [
      'llama3',
      'llama2',
      'mistral',
      'neural-chat',
      'starcoder',
      'codellama',
    ];
  }

  @override
  Future<AIResponse> sendMessage(
    List<AIMessage> messages, {
    AIConfig? config,
  }) async {
    final effectiveConfig = config ?? this.config;

    try {
      final response =
          await _makeRequest(messages, effectiveConfig, stream: false);
      return _parseResponse(response, effectiveConfig);
    } catch (e) {
      handleError(e);
    }
  }

  @override
  Stream<AIStreamChunk> sendMessageStream(
    List<AIMessage> messages, {
    AIConfig? config,
    void Function(AIStreamChunk)? onChunk,
  }) async* {
    final effectiveConfig = config ?? this.config;

    try {
      final response =
          await _makeRequest(messages, effectiveConfig, stream: true);
      await for (final chunk
          in _parseStreamResponse(response, effectiveConfig)) {
        onChunk?.call(chunk);
        yield chunk;
      }
    } catch (e) {
      handleError(e);
    }
  }

  Future<http.Response> _makeRequest(
    List<AIMessage> messages,
    AIConfig config, {
    bool stream = false,
  }) async {
    final url = Uri.parse('${config.effectiveBaseUrl}/chat');

    final body = <String, dynamic>{
      'model': config.model,
      'messages': messages.map((msg) => formatMessage(msg)).toList(),
      'stream': stream,
    };

    // 添加Ollama特定参数
    if (config.modelParameters != null) {
      body.addAll(config.modelParameters!);
    }

    // 如果没有提供num_ctx参数，使用合理的默认值
    if (!body.containsKey('options')) {
      body['options'] = {
        'num_ctx': config.maxTokens,
        'temperature': config.temperature,
      };
    }

    final response = await executeRequest(
      () => client
          .post(
        url,
        headers: _buildHeaders(),
        body: jsonEncode(body),
      )
          .timeout(
        Duration(seconds: config.effectiveTimeout),
        onTimeout: () {
          throw TimeoutException(
            'Request timeout after ${config.effectiveTimeout} seconds',
          );
        },
      ),
    );

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }

    return response;
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  void _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'Request failed with status $statusCode';

    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map && errorData.containsKey('error')) {
        message = errorData['error'].toString();
      }
    } catch (e) {
      // Ignore JSON parse errors
    }

    // Ollama常见错误处理
    if (message.contains('model') && message.contains('not found')) {
      handleError('Model not found. Please pull the model first.', statusCode);
    } else if (message.contains('connection')) {
      handleError('Ollama service not available. Make sure Ollama is running.',
          statusCode);
    } else {
      handleError(message, statusCode);
    }
  }

  AIResponse _parseResponse(http.Response response, AIConfig config) {
    final data = jsonDecode(response.body);

    try {
      final message = data['message'];
      final promptEvalCount = data['prompt_eval_count'] as int?;
      final evalCount = data['eval_count'] as int?;

      return AIResponse(
        id: data['id'] ?? createRequestId(),
        content: message['content'] ?? '',
        model: data['model'] ?? config.model,
        inputTokens: promptEvalCount,
        outputTokens: evalCount,
        totalTokens: (promptEvalCount ?? 0) + (evalCount ?? 0),
        finishReason: data['done'] == true ? 'stop' : null,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Invalid response format: ${e.toString()}');
    }
  }

  Stream<AIStreamChunk> _parseStreamResponse(
    http.Response response,
    AIConfig config,
  ) async* {
    final lines = response.body.split('\n');
    String fullContent = '';

    for (final line in lines) {
      if (line.isEmpty) continue;

      try {
        final data = jsonDecode(line);

        if (data['done'] == true) {
          final promptEvalCount = data['prompt_eval_count'] as int?;
          final evalCount = data['eval_count'] as int?;

          yield AIStreamChunk.complete(
            content: fullContent,
            finishReason: 'stop',
            inputTokens: promptEvalCount,
            outputTokens: evalCount,
          );
          break;
        }

        final message = data['message'];
        if (message != null) {
          final content = message['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            fullContent += content;
            yield AIStreamChunk.incomplete(content);
          }
        }
      } catch (e) {
        // Skip malformed JSON
        continue;
      }
    }
  }

  @override
  int estimateTokens(List<AIMessage> messages) {
    // Ollama通常使用更大的上下文窗口，所以估算可以更宽松一些
    final totalChars = messages.fold<int>(
      0,
      (sum, msg) => sum + msg.content.length,
    );
    return (totalChars / 3).ceil(); // 更乐观的估算
  }
}
