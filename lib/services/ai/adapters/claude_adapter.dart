import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_adapter.dart';
import '../../../models/ai_config.dart';
import '../../../models/ai_message.dart';
import '../../../models/ai_response.dart';
import 'base_ai_adapter.dart';

/// Anthropic Claude API适配器
class ClaudeAdapter extends BaseAIAdapterImpl {
  static const String _adapterName = 'ClaudeAdapter';

  ClaudeAdapter({
    required super.config,
    super.client,
  });

  @override
  String get adapterName => _adapterName;

  @override
  Future<bool> validateApiKey() async {
    try {
      final testMessage = AIMessage.user(
        id: 'test',
        content: 'Hello',
      );

      await sendMessage([testMessage]);
      return true;
    } catch (e) {
      if (e is ApiKeyException) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<List<String>> getAvailableModels() async {
    return [
      'claude-3-5-sonnet-20241022',
      'claude-3-5-haiku-20241022',
      'claude-3-opus-20240229',
      'claude-3-sonnet-20240229',
      'claude-3-haiku-20240307',
    ];
  }

  @override
  Future<AIResponse> sendMessage(
    List<AIMessage> messages, {
    AIConfig? config,
  }) async {
    final effectiveConfig = config ?? this.config;

    try {
      final response = await _makeRequest(messages, effectiveConfig, stream: false);
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
      final stream = await _makeRequest(messages, effectiveConfig, stream: true);
      await for (final chunk in _parseStreamResponse(stream, effectiveConfig)) {
        onChunk?.call(chunk);
        yield chunk;
      }
    } catch (e) {
      handleError(e);
    }
  }

  Future<http.StreamedResponse> _makeRequest(
    List<AIMessage> messages,
    AIConfig config, {
    bool stream = false,
  }) async {
    final url = Uri.parse('${config.effectiveBaseUrl}/messages');

    final requestBody = _buildRequestBody(messages, config, stream);

    final request = http.Request('POST', url);
    request.headers.addAll(_buildHeaders(config));
    request.body = jsonEncode(requestBody);

    final response = await executeRequest(
      () => client.send(request).timeout(
        Duration(seconds: config.effectiveTimeout),
        onTimeout: () {
          throw TimeoutException(
            message: 'Request timeout after ${config.effectiveTimeout} seconds',
          );
        },
      ),
    );

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      _handleErrorResponse(response.statusCode, responseBody);
    }

    return response;
  }

  Map<String, dynamic> _buildRequestBody(
    List<AIMessage> messages,
    AIConfig config,
    bool stream,
  ) {
    // 分离系统消息和用户/助手消息
    final systemMessages = messages.where((m) => m.role == MessageRole.system).toList();
    final conversationMessages = messages.where((m) => m.role != MessageRole.system).toList();

    final body = <String, dynamic>{
      'model': config.model,
      'max_tokens': config.maxTokens,
      'messages': conversationMessages.map((msg) => _formatMessage(msg)).toList(),
      'stream': stream,
    };

    // 添加系统消息
    if (systemMessages.isNotEmpty) {
      body['system'] = systemMessages.map((m) => m.content).join('\n\n');
    }

    // 添加温度参数
    if (config.temperature > 0) {
      body['temperature'] = config.temperature;
    }

    // 添加自定义参数
    if (config.modelParameters != null) {
      body.addAll(config.modelParameters!);
    }

    return body;
  }

  Map<String, String> _buildHeaders(AIConfig config) {
    return {
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  Map<String, dynamic> _formatMessage(AIMessage message) {
    return {
      'role': message.role == MessageRole.assistant ? 'assistant' : 'user',
      'content': message.content,
    };
  }

  void _handleErrorResponse(int statusCode, String responseBody) {
    String message = 'Request failed with status $statusCode';

    try {
      final errorData = jsonDecode(responseBody);
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

  Future<AIResponse> _parseResponse(
    http.StreamedResponse response,
    AIConfig config,
  ) async {
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    try {
      return AIResponse(
        id: data['id'] ?? createRequestId(),
        content: data['content'][0]['text'] ?? '',
        model: data['model'] ?? config.model,
        inputTokens: data['usage']?['input_tokens'],
        outputTokens: data['usage']?['output_tokens'],
        totalTokens: data['usage']?['input_tokens'] + data['usage']?['output_tokens'],
        stopReason: data['stop_reason'],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Invalid response format: ${e.toString()}');
    }
  }

  Stream<AIStreamChunk> _parseStreamResponse(
    http.StreamedResponse response,
    AIConfig config,
  ) async* {
    final stream = response.stream.transform(utf8.decoder);
    String fullContent = '';

    await for (final line in stream) {
      final lines = line.split('\n');

      for (final line in lines) {
        if (line.isEmpty || line.startsWith(':')) continue;

        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6);
            final data = jsonDecode(jsonStr);

            if (data['type'] == 'content_block_delta') {
              final delta = data['delta'];
              final content = delta?['text']?.toString() ?? '';

              if (content.isNotEmpty) {
                fullContent += content;
                yield AIStreamChunk.incomplete(content);
              }
            } else if (data['type'] == 'message_stop') {
              yield AIStreamChunk.complete(
                content: fullContent,
                finishReason: 'stop',
              );
            } else if (data['type'] == 'message_delta') {
              final usage = data['usage'];
              if (usage != null) {
                yield AIStreamChunk.complete(
                  content: fullContent,
                  finishReason: 'stop',
                  inputTokens: usage['input_tokens'],
                  outputTokens: usage['output_tokens'],
                );
              }
            }
          } catch (e) {
            // Skip malformed JSON
            continue;
          }
        }
      }
    }
  }
}