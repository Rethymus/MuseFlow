import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/domain/ai_exception.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/manuscript/application/chapter_summarization_service.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/domain/chapter_summary.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  Chapter chapter({String content = '林风入门青云宗，初识苏雪晴，被安排到杂役房。'}) =>
      Chapter(
        id: 'ch-1',
        manuscriptId: 'ms-1',
        title: '第一章',
        sortOrder: 1,
        status: '初稿',
        documentContent: content,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

  group('ChapterSummarizationService', () {
    test('summarize accumulates stream into a bounded ChapterSummary', () async {
      final adapter = _FakeAdapter(['林风入门', '青云宗，', '与苏雪晴初识。']);
      final service = ChapterSummarizationService(
        openAIAdapter: adapter,
        apiKey: 'k',
        baseUrl: 'u',
        model: 'm',
      );

      final result = await service.summarize(
        chapter(),
        now: DateTime(2026, 6, 2),
      );

      expect(result.summary, '林风入门青云宗，与苏雪晴初识。');
      expect(result.chapterId, 'ch-1');
      expect(result.manuscriptId, 'ms-1');
      expect(result.id, 'summary-ch-1');
      expect(result.sourceWordCount, greaterThan(0));
      expect(result.createdAt, DateTime(2026, 6, 2));
      final userPrompt = adapter.messages.last.toJson()['content'] as String;
      expect(userPrompt, contains('概括'));
      expect(userPrompt, contains('林风入门青云宗'));
    });

    test('summarize rethrows AIException (no silent swallow)', () async {
      final adapter = _FakeAdapter.withError(const AIStreamException('boom'));
      final service = ChapterSummarizationService(
        openAIAdapter: adapter,
        apiKey: 'k',
        baseUrl: 'u',
        model: 'm',
      );

      await expectLater(
        service.summarize(chapter()),
        throwsA(isA<AIStreamException>()),
      );
    });

    test('ChapterSummary toJson/fromJson round-trip preserves fields', () {
      final original = ChapterSummary(
        id: 's1',
        chapterId: 'c1',
        manuscriptId: 'm1',
        summary: '概括内容',
        sourceWordCount: 42,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 2),
      );
      final restored = ChapterSummary.fromJson(original.toJson());
      expect(restored, original);
      expect(restored.summary, '概括内容');
      expect(restored.sourceWordCount, 42);
    });
  });
}

class _FakeAdapter extends OpenAIAdapter {
  _FakeAdapter(this.chunks) : error = null;
  _FakeAdapter.withError(this.error) : chunks = const [];

  final List<String> chunks;
  final Object? error;
  List<ChatMessage> messages = const [];

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
    this.messages = messages;
    final e = error;
    if (e != null) throw e;
    for (final c in chunks) {
      yield c;
    }
  }
}
