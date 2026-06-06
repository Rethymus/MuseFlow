import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/knowledge/application/skill_generation_service.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('SkillGenerationService', () {
    late _FakeOpenAIAdapter adapter;
    late SkillGenerationService service;

    setUp(() {
      adapter = _FakeOpenAIAdapter(['chunk-1', 'chunk-2']);
      service = SkillGenerationService(
        openAIAdapter: adapter,
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'test-model',
      );
    });

    test('should build structured Chinese world-building prompt', () async {
      final chunks = await service.generateSkillStream('修仙门派体系').toList();

      expect(chunks, equals(['chunk-1', 'chunk-2']));
      expect(adapter.messages.length, equals(2));
      final system = adapter.messages[0].toJson()['content'] as String;
      final user = adapter.messages[1].toJson()['content'] as String;
      expect(system, contains('小说世界观设定顾问'));
      expect(system, contains('## 力量等级体系'));
      expect(system, contains('## 禁忌/限制'));
      expect(user, contains('修仙门派体系'));
    });

    test('should parse markdown sections into SkillDocument', () {
      final document = service.parseSkillDocument(
        name: '修仙体系',
        description: '概念描述',
        rawContent: '''
## 力量等级体系
炼气、筑基、金丹
## 门派/势力关系
正道与魔道对立
## 世界规则
灵气守恒
## 禁忌/限制
不可逆天改命
## 专用术语
灵根
''',
      );

      expect(document.name, equals('修仙体系'));
      expect(document.sections.powerHierarchy, contains('炼气'));
      expect(document.sections.factionRelations, contains('正道'));
      expect(document.sections.rules, contains('灵气守恒'));
      expect(document.sections.taboos, contains('逆天'));
      expect(document.sections.terminology, contains('灵根'));
      expect(document.sections.rawContent, contains('力量等级体系'));
    });

    test('should parse JSON sections when JSON is returned', () {
      final document = service.parseSkillDocument(
        name: '修仙体系',
        description: '概念描述',
        rawContent: '{"powerHierarchy":"炼气","rules":"灵气守恒"}',
      );

      expect(document.sections.powerHierarchy, equals('炼气'));
      expect(document.sections.rules, equals('灵气守恒'));
      expect(document.sections.rawContent, contains('powerHierarchy'));
    });

    test('should fall back to rawContent when no structure is found', () {
      final document = service.parseSkillDocument(
        name: '无结构',
        description: '概念描述',
        rawContent: '只是普通文本',
      );

      expect(document.sections.rawContent, equals('只是普通文本'));
      expect(document.toContextString, equals('## 原始内容\n只是普通文本'));
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
    void Function(Usage?)? onUsage,
  }) {
    this.messages = messages;
    return Stream.fromIterable(chunks);
  }
}
