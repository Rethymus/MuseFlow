import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';

void main() {
  group('SkillSections', () {
    test('should roundtrip through JSON serialization', () {
      final sections = SkillSections(
        powerHierarchy: '炼气、筑基、金丹',
        factionRelations: '正道与魔道对立',
        rules: '灵气守恒',
        taboos: '不可逆天改命',
        terminology: '灵根、金丹',
        rawContent: '原始内容',
      );

      final restored = SkillSections.fromJson(sections.toJson());

      expect(restored, equals(sections));
    });

    test('should reject sections exceeding 10000 characters', () {
      expect(() => SkillSections(rules: 'a' * 10001), throwsArgumentError);
    });

    test('should accept sections at exactly 10000 characters', () {
      expect(() => SkillSections(rules: 'a' * 10000), returnsNormally);
    });
  });

  group('SkillDocument', () {
    final now = DateTime(2026, 1, 1);
    final baseDocument = SkillDocument(
      id: 'skill-id',
      name: '修仙体系',
      description: '修仙世界规则',
      content: '完整 Markdown 内容',
      sections: SkillSections(rules: '灵气守恒'),
      createdAt: now,
    );

    test('should implement KnowledgeEntity fields', () {
      expect(baseDocument.displayName, equals('修仙体系'));
      expect(baseDocument.entityType, equals(EntityType.skill));
      expect(baseDocument.allNames, equals(['修仙体系']));
      expect(baseDocument.toContextString, contains('灵气守恒'));
    });

    test('should copy with updated fields', () {
      final updated = baseDocument.copyWith(isActive: true);

      expect(updated.isActive, isTrue);
      expect(updated.name, equals(baseDocument.name));
      expect(identical(updated, baseDocument), isFalse);
    });

    test('should roundtrip through JSON serialization', () {
      final restored = SkillDocument.fromJson(baseDocument.toJson());

      expect(restored, equals(baseDocument));
    });

    test('should reject content exceeding 50000 characters', () {
      expect(
        () => SkillDocument(
          id: 'skill-id',
          name: '修仙体系',
          description: '',
          content: 'a' * 50001,
          sections: SkillSections(),
          createdAt: now,
        ),
        throwsArgumentError,
      );
    });

    test('should accept content at exactly 50000 characters', () {
      expect(
        () => SkillDocument(
          id: 'skill-id',
          name: '修仙体系',
          description: '',
          content: 'a' * 50000,
          sections: SkillSections(),
          createdAt: now,
        ),
        returnsNormally,
      );
    });
  });
}
