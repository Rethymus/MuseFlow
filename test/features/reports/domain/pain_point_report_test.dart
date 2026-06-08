import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/domain/pain_point_report.dart';

void main() {
  group('PainPointReport', () {
    test('should hold issues and computed severity counts', () {
      final report = PainPointReport(
        issues: [
          const PainPointIssue(
            id: 'I-01',
            category: '功能缺陷',
            severity: '高',
            requirement: 'EDITOR-01',
            title: 'Crash on save',
            description: 'App crashes when saving empty fragment',
            status: 'closed',
          ),
          const PainPointIssue(
            id: 'I-02',
            category: '体验摩擦',
            severity: '中',
            requirement: 'KB-03',
            title: 'Slow character card load',
            description: 'Takes 3 seconds to open',
            status: 'open',
          ),
          const PainPointIssue(
            id: 'I-03',
            category: '缺失需求',
            severity: '低',
            requirement: 'NAV-02',
            title: 'No keyboard shortcut',
            description: 'Missing Ctrl+S shortcut',
            status: 'open',
          ),
        ],
      );

      expect(report.issues.length, 3);
      expect(report.totalHigh, 1);
      expect(report.totalMedium, 1);
      expect(report.totalLow, 1);
    });

    test('should return zero counts for empty issues', () {
      final report = PainPointReport(issues: const []);

      expect(report.totalHigh, 0);
      expect(report.totalMedium, 0);
      expect(report.totalLow, 0);
    });

    test('should support copyWith', () {
      final report = PainPointReport(issues: const []);
      final updated = report.copyWith(
        issues: [
          const PainPointIssue(
            id: 'I-10',
            category: '功能缺陷',
            severity: '高',
            requirement: 'TEST',
            title: 'Test issue',
            description: 'desc',
            status: 'open',
          ),
        ],
      );

      expect(updated.issues.length, 1);
      expect(updated.totalHigh, 1);
    });
  });

  group('PainPointIssue', () {
    test('should hold all fields', () {
      const issue = PainPointIssue(
        id: 'I-01',
        category: '功能缺陷',
        severity: '高',
        requirement: 'EDITOR-01',
        title: 'Crash on save',
        description: 'App crashes when saving empty fragment',
        status: 'closed',
      );

      expect(issue.id, 'I-01');
      expect(issue.category, '功能缺陷');
      expect(issue.severity, '高');
      expect(issue.requirement, 'EDITOR-01');
      expect(issue.title, 'Crash on save');
      expect(issue.description, 'App crashes when saving empty fragment');
      expect(issue.status, 'closed');
    });

    test('should support copyWith', () {
      const issue = PainPointIssue(
        id: 'I-01',
        category: '功能缺陷',
        severity: '高',
        requirement: 'EDITOR-01',
        title: 'Crash on save',
        description: 'desc',
        status: 'open',
      );

      final updated = issue.copyWith(status: 'closed');
      expect(updated.status, 'closed');
      expect(updated.id, 'I-01'); // unchanged
    });
  });
}
