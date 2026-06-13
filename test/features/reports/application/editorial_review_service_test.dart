/// Tests for EditorialReviewService — single audited LLM call producing a
/// 4-dimension review.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/reports/application/editorial_review_service.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('EditorialReviewService', () {
    EditorialReviewService serviceWith({
      required _FakeReviewAdapter adapter,
      _RecordingAudit? audit,
    }) {
      return EditorialReviewService(
        openAIAdapter: adapter,
        apiKey: 'key',
        baseUrl: 'https://api.example.com/v1',
        model: 'gpt-test',
        auditService: audit,
      );
    }

    test(
      'parses 4-dimension review from fenced JSON stream + records audit',
      () async {
        final adapter = _FakeReviewAdapter(
          output: '''```json
{"dimensions":[
  {"dimension":"情节","score":80,"strengths":"a","weaknesses":"b","suggestions":"c"},
  {"dimension":"人物","score":70,"strengths":"a","weaknesses":"b","suggestions":"c"},
  {"dimension":"文笔","score":75,"strengths":"a","weaknesses":"b","suggestions":"c"},
  {"dimension":"节奏","score":65,"strengths":"a","weaknesses":"b","suggestions":"c"}
]}
```''',
          usage: const Usage(
            promptTokens: 100,
            completionTokens: 50,
            totalTokens: 150,
          ),
        );
        final audit = _RecordingAudit();
        final service = serviceWith(adapter: adapter, audit: audit);

        final review = await service.reviewChapter(
          '林风站在山门前，袖中的断裂剑印忽然发烫。问心石阶只回应断裂剑印。',
          manuscriptId: 'm1',
          chapterId: 'c1',
        );

        expect(review.isDegraded, isFalse);
        expect(review.dimensions, hasLength(4));
        expect(adapter.createStreamCalls, 1);
        expect(audit.ops, [AuditOperationType.editorialReview]);
        expect(audit.inputs, hasLength(1));
        expect(audit.inputs.single, contains('待评审章节'));
        expect(audit.manuscriptIds, ['m1']);
      },
    );

    test(
      'too-short text returns degraded without an LLM call or audit',
      () async {
        final adapter = _FakeReviewAdapter(output: '{"dimensions":[]}');
        final audit = _RecordingAudit();
        final service = serviceWith(adapter: adapter, audit: audit);

        final review = await service.reviewChapter('短文本');

        expect(review.isDegraded, isTrue);
        expect(adapter.createStreamCalls, 0);
        expect(audit.ops, isEmpty);
      },
    );

    test('adapter error degrades gracefully (no throw)', () async {
      final adapter = _FakeReviewAdapter(
        throwOnStream: Exception('network down'),
      );
      final service = serviceWith(adapter: adapter);

      final review = await service.reviewChapter(
        '这是一段足够长的待评审章节正文，用于通过最小长度门槛触发实际调用。',
      );

      expect(review.isDegraded, isTrue);
      expect(adapter.createStreamCalls, 1);
    });
  });
}

/// Fake AIAdapter that yields a fixed output (optionally throws).
class _FakeReviewAdapter implements AIAdapter {
  _FakeReviewAdapter({this.output = '', this.usage, this.throwOnStream});

  final String output;
  final Usage? usage;
  final Object? throwOnStream;
  int createStreamCalls = 0;

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
    createStreamCalls++;
    if (throwOnStream != null) throw throwOnStream!;
    yield output;
    onUsage?.call(usage);
  }
}

/// Records every recordAudit invocation.
class _RecordingAudit extends TokenAuditService {
  _RecordingAudit() : super(_NoopRepo(), TokenBudgetCalculator());

  final List<AuditOperationType> ops = [];
  final List<String> inputs = [];
  final List<String> manuscriptIds = [];

  @override
  void recordAudit({
    required Usage? usage,
    required String modelName,
    required AuditOperationType operationType,
    required String manuscriptId,
    String? chapterId,
    required String inputText,
    required String outputText,
  }) {
    ops.add(operationType);
    inputs.add(inputText);
    manuscriptIds.add(manuscriptId);
  }
}

class _NoopRepo implements TokenAuditRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
