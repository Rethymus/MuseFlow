import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';

void main() {
  group('AuditOperationType', () {
    test('should have exactly 13 operation types', () {
      expect(AuditOperationType.values.length, 13);
    });

    test('should contain all expected operation types', () {
      expect(
        AuditOperationType.values.map((e) => e.name),
        containsAll([
          'synthesis',
          'rewrite',
          'polish',
          'freeInput',
          'expand',
          'compress',
          'dialogue',
          'scene',
          'skillGen',
          'opening',
          'deviationDetect',
          'editorialReview',
          'templateComplete',
        ]),
      );
    });

    test('should have synthesis operation with organize group', () {
      expect(AuditOperationType.synthesis.label, '碎片整理');
      expect(AuditOperationType.synthesis.group, 'organize');
    });

    test('should have rewrite operation with edit group', () {
      expect(AuditOperationType.rewrite.label, '语气改写');
      expect(AuditOperationType.rewrite.group, 'edit');
    });

    test('should have polish operation with edit group', () {
      expect(AuditOperationType.polish.label, '段落润色');
      expect(AuditOperationType.polish.group, 'edit');
    });

    test('should have freeInput operation with edit group', () {
      expect(AuditOperationType.freeInput.label, '自由输入');
      expect(AuditOperationType.freeInput.group, 'edit');
    });

    test('should have expand operation with edit group', () {
      expect(AuditOperationType.expand.label, '扩写');
      expect(AuditOperationType.expand.group, 'edit');
    });

    test('should have compress operation with edit group', () {
      expect(AuditOperationType.compress.label, '缩写');
      expect(AuditOperationType.compress.group, 'edit');
    });

    test('should have dialogue operation with edit group', () {
      expect(AuditOperationType.dialogue.label, '对话生成');
      expect(AuditOperationType.dialogue.group, 'edit');
    });

    test('should have scene operation with edit group', () {
      expect(AuditOperationType.scene.label, '场景描写');
      expect(AuditOperationType.scene.group, 'edit');
    });

    test('should have skillGen operation with worldview group', () {
      expect(AuditOperationType.skillGen.label, 'Skill生成');
      expect(AuditOperationType.skillGen.group, 'worldview');
    });

    test('should have opening operation with worldview group', () {
      expect(AuditOperationType.opening.label, '开篇生成');
      expect(AuditOperationType.opening.group, 'worldview');
    });

    test('should have deviationDetect operation with worldview group', () {
      expect(AuditOperationType.deviationDetect.label, '偏离检测');
      expect(AuditOperationType.deviationDetect.group, 'worldview');
    });

    test('should have editorialReview operation with worldview group', () {
      expect(AuditOperationType.editorialReview.label, '编辑评审');
      expect(AuditOperationType.editorialReview.group, 'worldview');
    });

    test('should have templateComplete operation with template group', () {
      expect(AuditOperationType.templateComplete.label, '模板补全');
      expect(AuditOperationType.templateComplete.group, 'template');
    });

    test('should have exactly 4 unique groups', () {
      final groups = AuditOperationType.values.map((e) => e.group).toSet();
      expect(groups.length, 4);
      expect(
        groups,
        containsAll(['organize', 'edit', 'worldview', 'template']),
      );
    });

    test('should map rewrite, polish, freeInput, expand, compress, dialogue, scene to edit group', () {
      expect(AuditOperationType.rewrite.group, 'edit');
      expect(AuditOperationType.polish.group, 'edit');
      expect(AuditOperationType.freeInput.group, 'edit');
      expect(AuditOperationType.expand.group, 'edit');
      expect(AuditOperationType.compress.group, 'edit');
      expect(AuditOperationType.dialogue.group, 'edit');
      expect(AuditOperationType.scene.group, 'edit');
    });

    test(
      'should map skillGen, opening, deviationDetect to worldview group',
      () {
        expect(AuditOperationType.skillGen.group, 'worldview');
        expect(AuditOperationType.opening.group, 'worldview');
        expect(AuditOperationType.deviationDetect.group, 'worldview');
      },
    );

    test('should have non-empty label for each operation type', () {
      for (final operationType in AuditOperationType.values) {
        expect(operationType.label, isNotEmpty);
      }
    });

    test('should have non-empty group for each operation type', () {
      for (final operationType in AuditOperationType.values) {
        expect(operationType.group, isNotEmpty);
      }
    });
  });
}
