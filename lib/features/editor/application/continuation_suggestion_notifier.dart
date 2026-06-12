/// Notifier for generating guided continuation suggestions (LFIN-03).
///
/// Analyzes the current chapter text and context to produce 3 plot
/// direction suggestions. User selects one before AI generates content.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/editor/domain/continuation_suggestion.dart';
import 'package:openai_dart/openai_dart.dart';

/// State for the continuation suggestion flow.
class ContinuationSuggestionState {
  /// Whether suggestions are being generated.
  final bool isLoading;

  /// The 3 generated suggestions, or empty when idle/error.
  final List<ContinuationSuggestion> suggestions;

  /// The selected suggestion index, or null when none selected.
  final int? selectedIndex;

  /// Error message (Chinese), or null.
  final String? error;

  const ContinuationSuggestionState({
    this.isLoading = false,
    this.suggestions = const [],
    this.selectedIndex,
    this.error,
  });

  /// Creates a copy with the given fields replaced.
  ///
  /// The [error] parameter uses a nullable pattern: omitting it preserves the
  /// existing value, while passing null explicitly clears the error.
  ContinuationSuggestionState copyWith({
    bool? isLoading,
    List<ContinuationSuggestion>? suggestions,
    int? selectedIndex,
    bool clearError = false,
    String? error,
  }) {
    return ContinuationSuggestionState(
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      selectedIndex: selectedIndex,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier that generates 3 plot continuation suggestions via AI.
///
/// Per LFIN-03: Based on the current chapter text and optional context chain,
/// the AI proposes 3 distinct narrative directions. The user selects one,
/// and the selected direction becomes the instruction for content generation.
class ContinuationSuggestionNotifier
    extends Notifier<ContinuationSuggestionState> {
  bool _cancelled = false;

  @override
  ContinuationSuggestionState build() => const ContinuationSuggestionState();

  /// Generates 3 plot continuation suggestions based on current context.
  ///
  /// Parameters:
  /// - [chapterText]: The current chapter text (up to ~1000 chars).
  /// - [contextChain]: Optional multi-chapter context chain for narrative awareness.
  void generateSuggestions({
    required String chapterText,
    String? contextChain,
  }) {
    _cancelled = false;
    state = const ContinuationSuggestionState(isLoading: true);

    final provider = ref.read(activeProviderProvider);
    if (provider == null) {
      state = const ContinuationSuggestionState(
        error: '未配置 AI 模型，请在设置中添加',
      );
      return;
    }

    final apiKey = ref.read(activeApiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      state = const ContinuationSuggestionState(
        error: 'API Key 无效，请检查设置',
      );
      return;
    }

    _fetchKeyAndGenerate(provider, apiKey, chapterText, contextChain);
  }

  /// Selects a suggestion by index.
  void selectSuggestion(int index) {
    if (index < 0 || index >= state.suggestions.length) return;
    state = state.copyWith(selectedIndex: index);
  }

  /// Clears the current suggestions and resets to idle.
  void reset() {
    _cancelled = false;
    state = const ContinuationSuggestionState();
  }

  /// Cancels the current generation.
  void cancel() {
    _cancelled = true;
    state = state.copyWith(isLoading: false);
  }

  Future<void> _fetchKeyAndGenerate(
    AIProvider provider,
    String apiKey,
    String chapterText,
    String? contextChain,
  ) async {
    final adapter = ref.read(openaiAdapterProvider);

    final messages = _buildMessages(chapterText, contextChain);

    try {
      final stream = adapter.createStream(
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: provider.model,
        messages: messages,
        temperature: 0.8,
        maxTokens: 800,
      );

      final buffer = StringBuffer();
      await for (final token in stream) {
        if (_cancelled) return;
        buffer.write(token);
      }

      if (!_cancelled) {
        final suggestions = _parseSuggestions(buffer.toString());
        if (suggestions.length >= 3) {
          state = ContinuationSuggestionState(suggestions: suggestions);
        } else {
          state = ContinuationSuggestionState(
            suggestions: suggestions,
            error: suggestions.isEmpty
                ? 'AI 未能生成有效的续写建议，请重试'
                : '仅生成 ${suggestions.length} 条建议，请重试',
          );
        }
      }
    } on AIException catch (e) {
      if (!_cancelled) {
        state = ContinuationSuggestionState(error: _mapError(e));
      }
    } catch (e) {
      if (!_cancelled) {
        state = state.copyWith(error: '生成中断，请重试');
      }
    }
  }

  /// Builds the prompt messages for generating plot suggestions.
  List<ChatMessage> _buildMessages(String chapterText, String? contextChain) {
    final contextSection = contextChain != null && contextChain.isNotEmpty
        ? '\n\n前序章节脉络：\n$contextChain'
        : '';

    const systemPrompt = '你是一位资深小说编辑，擅长分析故事走向并提出多样化的'
        '剧情发展方向。你需要根据当前章节内容和前序脉络，提出恰好3个风格各异、'
        '都符合逻辑的续写方向。';

    final truncatedText = chapterText.length > 1000
        ? '${chapterText.substring(0, 1000)}...'
        : chapterText;

    final userPrompt = '以下是一段小说正文的结尾部分：\n'
        '```\n$truncatedText\n```$contextSection\n\n'
        '请基于以上内容，提出恰好3个风格各异的续写方向。'
        '每个方向应包含：\n'
        '1. 方向名称（2-4字，如"冲突升级""人物深入""转折铺垫"）\n'
        '2. 简述（1-2句话描述这个方向会探索什么）\n'
        '3. 关键情节（2-3个要点，用分号分隔）\n\n'
        '请严格按以下JSON格式输出（不要包含markdown代码块标记）：\n'
        '[{"direction":"方向名","summary":"简述","keyPoints":"要点1；要点2"}，'
        '{"direction":"方向名","summary":"简述","keyPoints":"要点1；要点2"}，'
        '{"direction":"方向名","summary":"简述","keyPoints":"要点1；要点2"}]';

    return [
      ChatMessage.system(systemPrompt),
      ChatMessage.user(userPrompt),
    ];
  }

  /// Parses AI response text into a list of suggestions.
  ///
  /// Handles JSON responses with or without markdown code block markers.
  List<ContinuationSuggestion> _parseSuggestions(String response) {
    try {
      // Strip markdown code block markers if present
      var cleaned = response.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        if (cleaned.endsWith('```')) {
          cleaned = cleaned.substring(0, cleaned.length - 3);
        }
      }
      cleaned = cleaned.trim();

      // Try to find JSON array in the response
      final arrayMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleaned);
      if (arrayMatch == null) return [];

      final jsonArray = jsonDecode(arrayMatch.group(0)!) as List<dynamic>;

      final suggestions = <ContinuationSuggestion>[];
      for (final item in jsonArray) {
        if (item is Map<String, dynamic>) {
          final direction = item['direction'] as String?;
          final summary = item['summary'] as String?;
          final keyPoints = item['keyPoints'] as String?;
          if (direction != null && summary != null && keyPoints != null) {
            suggestions.add(ContinuationSuggestion(
              direction: direction.trim(),
              summary: summary.trim(),
              keyPoints: keyPoints.trim(),
            ));
          }
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  String _mapError(AIException e) {
    if (e is AIAuthException) return 'API Key 无效，请检查设置';
    if (e is AIRateLimitException) return '请求太快，请稍后再试';
    if (e is AINetworkException) return '网络连接失败，请检查网络';
    return '生成中断，请重试';
  }
}

/// Provider for the continuation suggestion notifier.
final continuationSuggestionNotifierProvider =
    NotifierProvider<ContinuationSuggestionNotifier, ContinuationSuggestionState>(
  ContinuationSuggestionNotifier.new,
);
