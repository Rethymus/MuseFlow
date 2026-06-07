import 'dart:async';
import 'dart:math';

import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:openai_dart/openai_dart.dart';

import '../fixtures/xianxia_content.dart';

class FakeAdapter implements AIAdapter {
  FakeAdapter({
    this.errorRate,
    this.errorText,
    this.emptyResponse = false,
    Random? random,
  }) : _random = random ?? Random(0);

  final double? errorRate;
  final String? errorText;
  final bool emptyResponse;
  final Random _random;

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) async* {
    final promptText = _messagesToText(messages);

    if (_shouldReturnError()) {
      final response = errorText ?? 'AI 测试异常';
      yield response;
      onUsage?.call(_usage(promptText, response));
      return;
    }

    if (emptyResponse) {
      return;
    }

    final operationType = _detectOperationType(promptText);
    final response = XianxiaContent.responses[operationType]!.first;
    for (final codePoint in response.runes) {
      yield String.fromCharCode(codePoint);
    }
    onUsage?.call(_usage(promptText, response));
  }

  bool _shouldReturnError() {
    final rate = errorRate ?? 0;
    if (rate <= 0) return false;
    if (rate >= 1) return true;
    return _random.nextDouble() < rate;
  }

  String _detectOperationType(String text) {
    if (text.contains('碎片') || text.contains('整理')) return 'synthesis';
    if (text.contains('改写') || text.contains('语气')) return 'rewrite';
    if (text.contains('润色')) return 'polish';
    return 'freeInput';
  }

  String _messagesToText(List<ChatMessage> messages) {
    return messages.map((message) => _messageToText(message)).join('\n');
  }

  String _messageToText(ChatMessage message) {
    final json = message.toJson();
    final content = json['content'];
    if (content is String) return content;
    if (content is List) {
      return content.map((part) => part.toString()).join('\n');
    }
    return content?.toString() ?? '';
  }

  Usage _usage(String prompt, String response) {
    final promptTokens = _estimateTokens(prompt);
    final completionTokens = _estimateTokens(response);
    return Usage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: promptTokens + completionTokens,
    );
  }

  int _estimateTokens(String text) {
    return text.replaceAll(RegExp(r'\s'), '').length * 2;
  }
}
