import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/stats/domain/audit_operation_type.dart';

void main() {
  group('AuditOperationType', () {
    test('should have exactly 8 operation types', () {
      expect(AuditOperationType.values.length, 8);
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

    test('should have templateComplete operation with template group', () {
      expect(AuditOperationType.templateComplete.label, '模板补全');
      expect(AuditOperationType.templateComplete.group, 'template');
    });

    test('should have exactly 4 unique groups', () {
      final groups = AuditOperationType.values.map((e) => e.group).toSet();
      expect(groups.length, 4);
      expect(groups, containsAll(['organize', 'edit', 'worldview', 'template']));
    });

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
