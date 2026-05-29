import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_adapter.dart';
import '../../../models/ai_config.dart';
import '../../../models/ai_message.dart';
import '../../../models/ai_response.dart';
import 'base_ai_adapter.dart';

/// OpenAI API适配器
class OpenAIAdapter extends BaseAIAdapterImpl {
  static const String _adapterName = 'OpenAIAdapter';

  OpenAIAdapter({
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
      'gpt-4o',
      'gpt-4o-mini',
      'gpt-4-turbo',
      'gpt-4',
      'gpt-3.5-turbo',
      'gpt-3.5-turbo-16k',
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
    final url = Uri.parse('${config.effectiveBaseUrl}/chat/completions');

    final body = {
      'model': config.model,
      'messages': messages.map((msg) => formatMessage(msg)).toList(),
      'stream': stream,
      ...config.modelParameters ?? {},
    };

    // 添加OpenAI特定参数
    if (!stream) {
      body['max_tokens'] = config.maxTokens;
      body['temperature'] = config.temperature;
    }

    final response = await executeRequest(
      () => client
          .post(
        url,
        headers: buildStandardHeaders(),
        body: jsonEncode(body),
      )
          .timeout(
        Duration(seconds: config.effectiveTimeout),
        onTimeout: () {
          throw TimeoutException(
            message: 'Request timeout after ${config.effectiveTimeout} seconds',
          );
        },
      ),
    );

    if (response.statusCode != 200) {
      handleErrorResponse(response);
    }

    return response;
  }

  AIResponse _parseResponse(http.Response response, AIConfig config) {
    return parseOpenAIResponse(response, config);
  }

  Stream<AIStreamChunk> _parseStreamResponse(
    http.Response response,
    AIConfig config,
  ) async* {
    yield* parseOpenAIStreamResponse(response, config);
  }
}
