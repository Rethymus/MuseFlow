import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
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

      expect((await service.detectDeviations('', [activeSkill()])).warnings, isEmpty);
      expect((await service.detectDeviations('文本', const [])).warnings, isEmpty);
    });
  });
}

class _FakeOpenAIAdapter extends OpenAIAdapter {
  _FakeOpenAIAdapter(this.chunks);

  final List<String> chunks;
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
  }) {
    this.messages = messages;
    return Stream.fromIterable(chunks);
  }
}
