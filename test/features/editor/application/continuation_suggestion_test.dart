/// Tests for ContinuationSuggestion and ContinuationSuggestionNotifier.
///
/// Validates LFIN-03: System offers 3 directional plot continuation suggestions.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/editor/application/continuation_suggestion_notifier.dart';
import 'package:museflow/features/editor/domain/continuation_suggestion.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('ContinuationSuggestion', () {
    test('should create with all fields', () {
      final suggestion = ContinuationSuggestion(
        direction: '冲突升级',
        summary: '通过外部事件加剧当前矛盾',
        keyPoints: '引入新敌人；揭示隐藏秘密',
      );

      expect(suggestion.direction, '冲突升级');
      expect(suggestion.summary, '通过外部事件加剧当前矛盾');
      expect(suggestion.keyPoints, '引入新敌人；揭示隐藏秘密');
    });

    test('equality should compare all fields', () {
      final a = ContinuationSuggestion(
        direction: '人物深入',
        summary: '探索角色内心世界',
        keyPoints: '回忆往事；情感独白',
      );
      final b = ContinuationSuggestion(
        direction: '人物深入',
        summary: '探索角色内心世界',
        keyPoints: '回忆往事；情感独白',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality should detect field differences', () {
      final a = ContinuationSuggestion(
        direction: '冲突升级',
        summary: '加剧矛盾',
        keyPoints: '引入敌人',
      );
      final b = ContinuationSuggestion(
        direction: '转折铺垫',
        summary: '加剧矛盾',
        keyPoints: '引入敌人',
      );

      expect(a, isNot(equals(b)));
    });

    test('toString should contain direction and summary', () {
      final suggestion = ContinuationSuggestion(
        direction: '场景描写',
        summary: '深入环境细节',
        keyPoints: '天气变化；光影描写',
      );

      expect(suggestion.toString(), contains('场景描写'));
      expect(suggestion.toString(), contains('深入环境细节'));
    });
  });

  group('ContinuationSuggestionState', () {
    test('should default to idle state', () {
      const state = ContinuationSuggestionState();

      expect(state.isLoading, false);
      expect(state.suggestions, isEmpty);
      expect(state.selectedIndex, isNull);
      expect(state.error, isNull);
    });

    test('should support copyWith for loading', () {
      final state = const ContinuationSuggestionState().copyWith(
        isLoading: true,
      );

      expect(state.isLoading, true);
      expect(state.suggestions, isEmpty);
    });

    test('should support copyWith for suggestions', () {
      final suggestions = [
        ContinuationSuggestion(
          direction: 'A',
          summary: '方向A',
          keyPoints: '要点1',
        ),
        ContinuationSuggestion(
          direction: 'B',
          summary: '方向B',
          keyPoints: '要点2',
        ),
        ContinuationSuggestion(
          direction: 'C',
          summary: '方向C',
          keyPoints: '要点3',
        ),
      ];
      final state = const ContinuationSuggestionState().copyWith(
        suggestions: suggestions,
        selectedIndex: 1,
      );

      expect(state.suggestions.length, 3);
      expect(state.selectedIndex, 1);
      expect(state.suggestions[1].direction, 'B');
    });

    test('should support error state', () {
      final state = const ContinuationSuggestionState().copyWith(
        error: 'API Key 无效',
      );

      expect(state.error, 'API Key 无效');
      expect(state.isLoading, false);
    });
  });

  group('ContinuationSuggestionNotifier', () {
    late ProviderContainer container;

    ProviderContainer createContainer({
      AIProvider? activeProvider,
      String? apiKey,
      bool hasProvider = true,
      bool hasApiKey = true,
      String aiResponse = '',
      AIException? errorToThrow,
    }) {
      final testProvider = hasProvider
          ? (activeProvider ??
                AIProvider(
                  id: 'test-provider',
                  name: 'test',
                  baseUrl: 'https://api.test.com',
                  type: AiProviderType.openai,
                  model: 'test-model',
                  createdAt: DateTime(2026, 1, 1),
                ))
          : null;

      container = ProviderContainer(
        overrides: [
          activeProviderProvider.overrideWithValue(testProvider),
          if (hasApiKey)
            activeApiKeyProvider.overrideWithValue(apiKey ?? 'test-api-key')
          else
            activeApiKeyProvider.overrideWithValue(null),
          openaiAdapterProvider.overrideWithValue(
            _FakeOpenAIAdapter(
              response: aiResponse,
              errorToThrow: errorToThrow,
            ),
          ),
        ],
      );
      return container;
    }

    tearDown(() {
      container.dispose();
    });

    test('should return error when no provider configured', () {
      createContainer(hasProvider: false, hasApiKey: false);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试章节文本');

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('未配置 AI 模型'));
      expect(state.isLoading, false);
    });

    test('should return error when API key is null', () {
      createContainer(hasProvider: true, hasApiKey: false);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试章节文本');

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('API Key'));
      expect(state.isLoading, false);
    });

    test('should return error when API key is empty', () {
      createContainer(hasProvider: true, apiKey: '');
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试章节文本');

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('API Key'));
    });

    test('should parse valid 3-suggestion JSON response', () async {
      const aiResponse = '[{"direction":"冲突升级","summary":"通过外部事件加剧当前矛盾","keyPoints":"引入新敌人；揭示隐藏秘密"},'
          '{"direction":"人物深入","summary":"探索角色内心世界和情感变化","keyPoints":"回忆往事；情感独白"},'
          '{"direction":"转折铺垫","summary":"为后续剧情埋下伏笔","keyPoints":"发现线索；角色态度转变"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(
        chapterText: '林风站在山门前，望着远方乌云密布的天空。',
      );

      // Wait for async processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.isLoading, false);
      expect(state.suggestions.length, 3);
      expect(state.error, isNull);
      expect(state.suggestions[0].direction, '冲突升级');
      expect(state.suggestions[1].direction, '人物深入');
      expect(state.suggestions[2].direction, '转折铺垫');
    });

    test('should handle JSON wrapped in markdown code blocks', () async {
      const aiResponse = '```json\n[{"direction":"A","summary":"方向A","keyPoints":"要点1"},'
          '{"direction":"B","summary":"方向B","keyPoints":"要点2"},'
          '{"direction":"C","summary":"方向C","keyPoints":"要点3"}]\n```';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.suggestions.length, 3);
      expect(state.suggestions[0].direction, 'A');
    });

    test('should return error for empty response', () async {
      createContainer(aiResponse: '');
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.suggestions, isEmpty);
      expect(state.error, contains('未能生成'));
    });

    test('should return error for fewer than 3 suggestions', () async {
      const aiResponse = '[{"direction":"A","summary":"方向A","keyPoints":"要点1"},'
          '{"direction":"B","summary":"方向B","keyPoints":"要点2"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.suggestions.length, 2);
      expect(state.error, contains('仅生成 2 条'));
    });

    test('should return error for malformed JSON', () async {
      createContainer(aiResponse: '这不是JSON');
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.suggestions, isEmpty);
      expect(state.error, isNotNull);
    });

    test('should return error for AI exception', () async {
      createContainer(
        errorToThrow: AIAuthException('invalid key'),
      );
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('API Key'));
    });

    test('should map rate limit exception to Chinese message', () async {
      createContainer(
        errorToThrow: AIRateLimitException('rate limited'),
      );
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('请求太快'));
    });

    test('should map network exception to Chinese message', () async {
      createContainer(
        errorToThrow: AINetworkException('connection failed'),
      );
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.error, contains('网络连接'));
    });

    test('selectSuggestion should set selectedIndex', () async {
      const aiResponse = '[{"direction":"A","summary":"S1","keyPoints":"K1"},'
          '{"direction":"B","summary":"S2","keyPoints":"K2"},'
          '{"direction":"C","summary":"S3","keyPoints":"K3"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      notifier.selectSuggestion(1);
      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.selectedIndex, 1);
    });

    test('selectSuggestion should ignore out-of-range index', () async {
      const aiResponse = '[{"direction":"A","summary":"S1","keyPoints":"K1"},'
          '{"direction":"B","summary":"S2","keyPoints":"K2"},'
          '{"direction":"C","summary":"S3","keyPoints":"K3"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Select valid index
      notifier.selectSuggestion(0);
      expect(
        container.read(continuationSuggestionNotifierProvider).selectedIndex,
        0,
      );

      // Try invalid index — should be ignored
      notifier.selectSuggestion(5);
      expect(
        container.read(continuationSuggestionNotifierProvider).selectedIndex,
        0,
      );

      // Try negative index — should be ignored
      notifier.selectSuggestion(-1);
      expect(
        container.read(continuationSuggestionNotifierProvider).selectedIndex,
        0,
      );
    });

    test('reset should clear all state', () async {
      const aiResponse = '[{"direction":"A","summary":"S1","keyPoints":"K1"},'
          '{"direction":"B","summary":"S2","keyPoints":"K2"},'
          '{"direction":"C","summary":"S3","keyPoints":"K3"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(chapterText: '测试文本');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      notifier.selectSuggestion(1);

      notifier.reset();
      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.isLoading, false);
      expect(state.suggestions, isEmpty);
      expect(state.selectedIndex, isNull);
      expect(state.error, isNull);
    });

    test('should include context chain in prompt when provided', () async {
      const aiResponse = '[{"direction":"A","summary":"S1","keyPoints":"K1"},'
          '{"direction":"B","summary":"S2","keyPoints":"K2"},'
          '{"direction":"C","summary":"S3","keyPoints":"K3"}]';

      createContainer(aiResponse: aiResponse);
      final notifier =
          container.read(continuationSuggestionNotifierProvider.notifier);

      notifier.generateSuggestions(
        chapterText: '当前章节结尾文本。',
        contextChain: '紧邻前章摘要：林风进入宗门。',
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = container.read(continuationSuggestionNotifierProvider);
      expect(state.suggestions.length, 3);
      // Verify the adapter received the context chain in the prompt
      final adapter =
          container.read(openaiAdapterProvider) as _FakeOpenAIAdapter;
      expect(adapter.lastMessages, isNotNull);
      final userContent = adapter.lastMessages![1].toJson()['content'] as String;
      expect(userContent, contains('前序章节脉络'));
      expect(userContent, contains('林风进入宗门'));
    });
  });
}

/// Fake OpenAI adapter that returns a canned response for testing.
class _FakeOpenAIAdapter extends OpenAIAdapter {
  final String response;
  final AIException? errorToThrow;
  List<ChatMessage>? lastMessages;

  _FakeOpenAIAdapter({this.response = '', this.errorToThrow});

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
  }) {
    lastMessages = messages;

    if (errorToThrow != null) {
      return Stream.error(errorToThrow!);
    }

    return Stream.value(response);
  }
}
