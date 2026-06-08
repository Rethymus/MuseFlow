import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/reports/application/pain_point_report_service.dart';

void main() {
  group('PainPointReportService', () {
    test('should return exactly 6 Phase 14 issues and no Phase 15 issues', () {
      final report = const PainPointReportService().generate();

      expect(report.issues, hasLength(6));
      expect(
        report.issues.map((i) => i.id),
        containsAll([
          'P14-04-GLM-01',
          'P14-04-AUTO-01',
          'P14-04-AI-01',
          'P14-07-UI-01',
          'P14-07-HUMAN-01',
          'P14-07-HUMAN-02',
        ]),
      );
    });

    test('should categorize issues correctly', () {
      final report = const PainPointReportService().generate();

      expect(report.issues.where((i) => i.category == '功能缺陷'), hasLength(2));
      expect(report.issues.where((i) => i.category == '体验摩擦'), hasLength(1));
      expect(report.issues.where((i) => i.category == '缺失需求'), hasLength(3));
    });

    test('should count severities correctly', () {
      final report = const PainPointReportService().generate();

      expect(report.totalHigh, 1);
      expect(report.totalMedium, 4);
      expect(report.totalLow, 1);
    });

    test('should preserve status from issue logs', () {
      final report = const PainPointReportService().generate();
      final statusById = {
        for (final issue in report.issues) issue.id: issue.status,
      };

      expect(statusById['P14-04-GLM-01'], 'closed');
      expect(statusById['P14-04-AUTO-01'], 'deferred');
      expect(statusById['P14-04-AI-01'], 'closed');
      expect(statusById['P14-07-UI-01'], 'closed');
      expect(statusById['P14-07-HUMAN-01'], 'deferred');
      expect(statusById['P14-07-HUMAN-02'], 'closed');
    });

    test('should sort issues by severity descending', () {
      final report = const PainPointReportService().generate();

      expect(report.issues.first.severity, '高');
      expect(report.issues.last.severity, '低');
    });
  });
}
