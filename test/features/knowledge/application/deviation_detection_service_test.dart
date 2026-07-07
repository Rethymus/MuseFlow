import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';
import 'package:museflow/features/stats/domain/token_audit_record.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('DeviationDetectionService', () {
    final now = DateTime(2026, 1, 1);

    SkillDocument activeSkill() => SkillDocument(
      id: 'skill-1',
      name: '修仙体系',
      description: '',
      content: '',
      sections: SkillSections(rules: '灵气守恒', taboos: '不可复活亡者'),
      isActive: true,
      createdAt: now,
    );

    test('should build prompt and parse medium plus clear warnings', () async {
      final adapter = _FakeOpenAIAdapter([
        '[{"description":"轻微问题","severity":"low","skillName":"修仙体系"},',
        '{"description":"违反禁忌","severity":"medium","skillName":"修仙体系","suggestedFix":"改成昏迷"},',
        '{"description":"规则冲突","severity":"clear","skillName":"修仙体系"}]',
      ]);
      final service = DeviationDetectionService(
        openAIAdapter: adapter,
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'test-model',
      );

      final result = await service.detectDeviations('亡者复活了', [activeSkill()]);

      expect(result.warnings.length, equals(2));
      expect(result.warnings.first.severity, equals(DeviationSeverity.medium));
      expect(result.warnings.first.suggestedFix, equals('改成昏迷'));
      expect(result.warnings.last.severity, equals(DeviationSeverity.clear));
      final userPrompt = adapter.messages.last.toJson()['content'] as String;
      expect(userPrompt, contains('亡者复活了'));
      expect(userPrompt, contains('灵气守恒'));
      expect(userPrompt, contains('只报告 medium 或 clear'));
    });

    test(
      'should record token audit after successful stream completion',
      () async {
        final adapter = _FakeOpenAIAdapter(['[]'])
          ..usage = const Usage(
            promptTokens: 21,
            completionTokens: 5,
            totalTokens: 26,
          );
        final auditService = _RecordingTokenAuditService();
        final service = DeviationDetectionService(
          openAIAdapter: adapter,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com/v1',
          model: 'test-model',
          auditService: auditService,
        );

        await service.detectDeviations(
          '亡者复活了',
          [activeSkill()],
          manuscriptId: 'manuscript-1',
          chapterId: 'chapter-1',
        );

        expect(auditService.calls, hasLength(1));
        final call = auditService.calls.single;
        expect(call.usage, same(adapter.usage));
        expect(call.modelName, 'test-model');
        expect(call.operationType, AuditOperationType.deviationDetect);
        expect(call.manuscriptId, 'manuscript-1');
        expect(call.chapterId, 'chapter-1');
        expect(call.inputText, contains('亡者复活了'));
        expect(call.outputText, '[]');
      },
    );

    test('should return empty result for invalid JSON', () async {
      final service = DeviationDetectionService(
        openAIAdapter: _FakeOpenAIAdapter(['not json']),
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'test-model',
      );

      final result = await service.detectDeviations('文本', [activeSkill()]);

      expect(result.warnings, isEmpty);
    });

    test('should skip empty text or empty skills', () async {
      final service = DeviationDetectionService(
        openAIAdapter: _FakeOpenAIAdapter(['[]']),
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'test-model',
      );

      expect(
        (await service.detectDeviations('', [activeSkill()])).warnings,
        isEmpty,
      );
      expect(
        (await service.detectDeviations('文本', const [])).warnings,
        isEmpty,
      );
    });

    test('should NOT report compliance confirmations as deviations '
        '(real GLM false-positive)', () async {
      // Captured from the real BigModel key journey (quick-260618-0ae):
      // GLM returned "clear" entries that were all compliance statements
      // (符合/未违反), zero real violations — flooding the user with false
      // alarms. Real deviations use 违背/违反; compliance uses 符合/未违反.
      final adapter = _FakeOpenAIAdapter([
        '[{"description":"林风没有学习其他峰的功法，符合未经允许不可学习其他峰的功法的设定。","severity":"clear","skillName":""},',
        '{"description":"文本中未提及火器、枪械、现代电子设备，符合不存在火器的设定。","severity":"clear","skillName":""},',
        '{"description":"林风并未违反外门弟子不得擅入内门禁地的设定。","severity":"clear","skillName":""}]',
      ]);
      final service = DeviationDetectionService(
        openAIAdapter: adapter,
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'test-model',
      );

      final result = await service.detectDeviations('林风入门修仙', [activeSkill()]);

      expect(
        result.warnings,
        isEmpty,
        reason: 'compliance confirmations (符合/未违反) are not deviations',
      );
    });

    test(
      'should keep real violations but drop compliance noise in a mixed response',
      () async {
        final adapter = _FakeOpenAIAdapter([
          '[{"description":"林风在练气期使用火系法术的描述违背了能力限制中的禁忌。","severity":"medium","skillName":"火系法术","suggestedFix":"改用基础法术"},',
          '{"description":"文本中未提及火器，符合不存在火器的设定。","severity":"clear","skillName":""}]',
        ]);
        final service = DeviationDetectionService(
          openAIAdapter: adapter,
          apiKey: 'test-key',
          baseUrl: 'https://api.example.com/v1',
          model: 'test-model',
        );

        final result = await service.detectDeviations('林风使用火系法术', [
          activeSkill(),
        ]);

        expect(result.warnings, hasLength(1));
        expect(
          result.warnings.single.severity,
          equals(DeviationSeverity.medium),
        );
        expect(result.warnings.single.description, contains('违背'));
      },
    );
  });
}

class _FakeOpenAIAdapter extends OpenAIAdapter {
  _FakeOpenAIAdapter(this.chunks);

  final List<String> chunks;
  List<ChatMessage> messages = const [];

  Usage? usage;

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
    for (final chunk in chunks) {
      yield chunk;
    }
    onUsage?.call(usage);
  }
}

class _RecordingTokenAuditService extends TokenAuditService {
  _RecordingTokenAuditService()
    : super(_NoopTokenAuditRepository(), TokenBudgetCalculator());

  final List<_AuditCall> calls = [];

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
    calls.add(
      _AuditCall(
        usage: usage,
        modelName: modelName,
        operationType: operationType,
        manuscriptId: manuscriptId,
        chapterId: chapterId,
        inputText: inputText,
        outputText: outputText,
      ),
    );
  }
}

class _AuditCall {
  const _AuditCall({
    required this.usage,
    required this.modelName,
    required this.operationType,
    required this.manuscriptId,
    required this.chapterId,
    required this.inputText,
    required this.outputText,
  });

  final Usage? usage;
  final String modelName;
  final AuditOperationType operationType;
  final String manuscriptId;
  final String? chapterId;
  final String inputText;
  final String outputText;
}

class _NoopTokenAuditRepository implements TokenAuditRepository {
  @override
  Future<void> clearAll() async {}

  @override
  int get count => 0;

  @override
  Future<void> enforceLimit(int maxRecords) async {}

  @override
  Future<List<TokenAuditRecord>> loadAll() async => const [];

  @override
  Future<void> saveAll(List<TokenAuditRecord> records) async {}

  @override
  Future<TokenAuditSnapshot> buildSnapshot() async =>
      const TokenAuditSnapshot();
}
