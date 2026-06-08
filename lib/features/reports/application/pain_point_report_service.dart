import 'package:museflow/features/reports/domain/pain_point_report.dart';

class PainPointReportService {
  const PainPointReportService();

  PainPointReport generate() {
    final issues = <PainPointIssue>[
      const PainPointIssue(
        id: 'P14-04-GLM-01',
        category: '功能缺陷',
        severity: '高',
        requirement: 'REPORT-02',
        title: 'Serial GLM generation exceeded D11 bounds',
        description: '连续章节生成时未严格限制 D11 字数边界，已通过 enforceD11Bounds 修复。',
        status: 'closed',
      ),
      const PainPointIssue(
        id: 'P14-04-AUTO-01',
        category: '缺失需求',
        severity: '中',
        requirement: 'REPORT-02',
        title: 'IME/pixel-level toolbar validation requires native device',
        description: '浮窗工具栏像素级验证已部分自动化，中文 IME 组合输入需 Windows/Android 真机继续验证。',
        status: 'deferred',
      ),
      const PainPointIssue(
        id: 'P14-04-AI-01',
        category: '功能缺陷',
        severity: '中',
        requirement: 'REPORT-02',
        title: 'Anti-AI-scent phrases needed stronger filtering',
        description: '创作输出仍出现部分 AI 味连接词，已在 P14-05 强化反 AI 味规则。',
        status: 'closed',
      ),
      const PainPointIssue(
        id: 'P14-07-UI-01',
        category: '体验摩擦',
        severity: '低',
        requirement: 'REPORT-02',
        title: 'Dark theme text contrast was insufficient',
        description: '深色主题下部分文本对比度偏低，影响长时间阅读舒适度，已修复。',
        status: 'closed',
      ),
      const PainPointIssue(
        id: 'P14-07-HUMAN-01',
        category: '缺失需求',
        severity: '中',
        requirement: 'REPORT-02',
        title: 'Chinese IME composition needs physical device validation',
        description: '系统级中文输入法兼容性无法在当前自动化环境完整验证，延期至原生设备 UAT。',
        status: 'deferred',
      ),
      const PainPointIssue(
        id: 'P14-07-HUMAN-02',
        category: '缺失需求',
        severity: '中',
        requirement: 'REPORT-02',
        title: 'DeviationWarningWidget was missing from validation flow',
        description: '偏离设定提醒组件未接入验证路径，已由 P14-09 补齐并验证。',
        status: 'closed',
      ),
    ];

    issues.sort(
      (a, b) => _severityRank(a.severity).compareTo(_severityRank(b.severity)),
    );
    return PainPointReport(issues: List.unmodifiable(issues));
  }

  int _severityRank(String severity) {
    return switch (severity) {
      '高' => 0,
      '中' => 1,
      '低' => 2,
      _ => 3,
    };
  }
}
