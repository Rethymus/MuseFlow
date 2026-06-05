import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:openai_dart/openai_dart.dart';

import '../../../helpers/hive_test_helper.dart';

void main() {
  group('SkillEnforcementMiddleware', () {
    late Box<dynamic> box;
    late SkillRepository repository;
    late SkillEnforcementMiddleware middleware;
    final now = DateTime(2026, 1, 1);

    setUp(() async {
      await setUpHiveTest();
      box = await Hive.openBox<dynamic>('skill_documents_test');
      repository = SkillRepository(box);
      middleware = SkillEnforcementMiddleware(
        skillRepository: repository,
        tokenBudgetCalculator: TokenBudgetCalculator(),
      );
    });

    tearDown(() async {
      await tearDownHiveTest();
    });

    test('should leave context unchanged when no active skills exist', () {
      final context = PromptContext(fragments: const []);

      final result = middleware.apply(context);

      expect(result.messages, isEmpty);
    });

    test('should inject active skill rules, taboos, and terminology', () async {
      await repository.add(
        SkillDocument(
          id: 'skill-1',
          name: '修仙体系',
          description: '',
          content: '',
          sections: SkillSections(
            rules: '灵气守恒',
            taboos: '不可复活亡者',
            terminology: '灵根',
            powerHierarchy: '炼气',
          ),
          isActive: true,
          createdAt: now,
        ),
      );

      final result = middleware.apply(PromptContext(fragments: const []));

      expect(result.messages.length, equals(1));
      final content = result.messages.first.toJson()['content'] as String;
      expect(content, contains('当前激活的世界观设定约束'));
      expect(content, contains('修仙体系'));
      expect(content, contains('灵气守恒'));
      expect(content, contains('不可复活亡者'));
      expect(content, contains('灵根'));
      expect(content, isNot(contains('炼气')));
    });

    test('should append skill constraints to existing system message', () async {
      await repository.add(
        SkillDocument(
          id: 'skill-1',
          name: '修仙体系',
          description: '',
          content: '',
          sections: SkillSections(rules: '灵气守恒'),
          isActive: true,
          createdAt: now,
        ),
      );

      final result = middleware.apply(
        PromptContext(
          fragments: const [],
          messages: [ChatMessage.system('原系统提示')],
        ),
      );

      final content = result.messages.first.toJson()['content'] as String;
      expect(content, startsWith('原系统提示'));
      expect(content, contains('灵气守恒'));
    });
  });
}
