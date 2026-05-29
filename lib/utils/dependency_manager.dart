import 'dependency_auditor.dart';
export 'dependency_auditor.dart'
    show ConflictSeverity, HealthScore, UpdatePriorityLevel;

/// 依赖管理器 - 主入口类
///
/// 提供统一的依赖管理API，整合依赖审计、健康检查、更新建议等功能
class DependencyManager {
  final DependencyAuditor auditor;
  late final DependencyUpdateAdvisor advisor;

  DependencyManager({required String projectPath})
      : auditor = DependencyAuditor(projectPath: projectPath) {
    advisor = DependencyUpdateAdvisor(auditor: auditor);
  }

  /// 执行完整的依赖审计
  Future<DependencyAuditResult> performFullAudit() async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 解析依赖
      final dependencies = await auditor.parseDependencies();

      // 2. 检测冲突
      final conflicts = await auditor.detectConflicts();

      // 3. 生成健康报告
      final healthReport = await auditor.generateHealthReport();

      // 4. 获取更新建议
      final suggestions = await auditor.getUpdateSuggestions();

      // 5. 获取优先级更新
      final priorityUpdates = await advisor.getPriorityUpdates();

      // 6. 验证约束
      final constraintsValid = await auditor.validateConstraints();

      stopwatch.stop();

      return DependencyAuditResult(
        success: true,
        duration: stopwatch.elapsed,
        dependencies: dependencies,
        conflicts: conflicts,
        healthReport: healthReport,
        suggestions: suggestions,
        priorityUpdates: priorityUpdates,
        constraintsValid: constraintsValid,
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      return DependencyAuditResult(
        success: false,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
        errorStack: stackTrace.toString(),
      );
    }
  }

  /// 快速健康检查
  Future<DependencyHealthStatus> quickHealthCheck() async {
    try {
      final report = await auditor.generateHealthReport();

      return DependencyHealthStatus(
        isHealthy: report.errors.isEmpty && report.conflicts.isEmpty,
        score: report.score,
        errorCount: report.errors.length,
        warningCount: report.warnings.length,
        conflictCount: report.conflicts.length,
        outdatedCount: report.outdatedCount,
        summary: _generateHealthSummary(report),
      );
    } catch (e) {
      return DependencyHealthStatus(
        isHealthy: false,
        score: HealthScore.critical,
        errorCount: 1,
        warningCount: 0,
        conflictCount: 0,
        outdatedCount: 0,
        summary: '健康检查失败: ${e.toString()}',
      );
    }
  }

  /// 记录依赖变更
  Future<void> recordDependencyChange({
    required String packageName,
    required String oldVersion,
    required String newVersion,
    required ChangeReason reason,
    String? author,
    String? notes,
  }) async {
    await auditor.logChange(
      packageName: packageName,
      oldVersion: oldVersion,
      newVersion: newVersion,
      reason: reason,
      author: author,
      notes: notes,
    );
  }

  /// 生成依赖报告（Markdown格式）
  Future<String> generateMarkdownReport() async {
    final result = await performFullAudit();

    if (!result.success) {
      return '# 依赖审计失败\n\n错误: ${result.errorMessage}';
    }

    final buffer = StringBuffer();

    // 标题
    buffer.writeln('# MuseFlow 依赖审计报告');
    buffer.writeln();
    buffer.writeln('**生成时间**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('**审计耗时**: ${result.duration.inMilliseconds}ms');
    buffer.writeln();

    // 健康状态
    buffer.writeln('## 健康状态');
    buffer.writeln();
    buffer.writeln('- **评分**: ${_getScoreBadge(result.healthReport.score)}');
    buffer.writeln('- **总依赖数**: ${result.dependencies.length}');
    buffer.writeln(
        '- **过时依赖**: ${result.healthReport.outdatedCount} (${result.healthReport.outdatedPercentage.toStringAsFixed(1)}%)');
    buffer.writeln('- **版本冲突**: ${result.conflicts.length}');
    buffer.writeln('- **警告**: ${result.healthReport.warnings.length}');
    buffer.writeln('- **错误**: ${result.healthReport.errors.length}');
    buffer.writeln();

    // 依赖列表
    buffer.writeln('## 依赖清单');
    buffer.writeln();

    final directDeps = result.dependencies
        .where((d) => d.type == DependencyType.direct)
        .toList();
    final devDeps =
        result.dependencies.where((d) => d.type == DependencyType.dev).toList();

    buffer.writeln('### 生产依赖');
    buffer.writeln();
    buffer.writeln('| 包名 | 当前版本 | 类型 | 状态 |');
    buffer.writeln('|------|---------|------|------|');
    for (final dep in directDeps) {
      final status = dep.isOutdated ? '⚠️ 过时' : '✅ 正常';
      buffer.writeln(
          '| ${dep.name} | ${dep.currentVersion} | ${dep.type.name} | $status |');
    }

    if (devDeps.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('### 开发依赖');
      buffer.writeln();
      buffer.writeln('| 包名 | 当前版本 | 状态 |');
      buffer.writeln('|------|---------|------|');
      for (final dep in devDeps) {
        final status = dep.isOutdated ? '⚠️ 过时' : '✅ 正常';
        buffer.writeln('| ${dep.name} | ${dep.currentVersion} | $status |');
      }
    }

    // 版本冲突
    if (result.conflicts.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## 版本冲突');
      buffer.writeln();
      for (final conflict in result.conflicts) {
        final severity =
            conflict.severity == ConflictSeverity.error ? '🔴' : '⚠️';
        buffer.writeln('### $severity ${conflict.packageName}');
        buffer.writeln();
        buffer
            .writeln('- **冲突版本**: ${conflict.conflictingVersions.join(', ')}');
        buffer.writeln('- **依赖项**: ${conflict.dependents.join(', ')}');
        buffer.writeln('- **解决方案**: ${conflict.resolution}');
        buffer.writeln();
      }
    }

    // 更新建议
    if (result.suggestions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## 更新建议');
      buffer.writeln();
      for (final suggestion in result.suggestions) {
        buffer.writeln('- $suggestion');
      }
      buffer.writeln();
    }

    // 优先级更新
    if (result.priorityUpdates.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('## 优先级更新');
      buffer.writeln();
      for (final update in result.priorityUpdates) {
        final priority = _getPriorityBadge(update.priority);
        buffer.writeln('### $priority ${update.packageName}');
        buffer.writeln();
        buffer.writeln('- **当前版本**: ${update.currentVersion}');
        buffer.writeln('- **建议版本**: ${update.suggestedVersion}');
        buffer.writeln('- **原因**: ${update.reason}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _getScoreBadge(HealthScore score) {
    switch (score) {
      case HealthScore.excellent:
        return '🟢 优秀';
      case HealthScore.good:
        return '🟢 良好';
      case HealthScore.fair:
        return '🟡 一般';
      case HealthScore.poor:
        return '🟠 较差';
      case HealthScore.critical:
        return '🔴 危急';
    }
  }

  String _getPriorityBadge(UpdatePriorityLevel priority) {
    switch (priority) {
      case UpdatePriorityLevel.critical:
        return '🚨 紧急';
      case UpdatePriorityLevel.high:
        return '🔴 高';
      case UpdatePriorityLevel.medium:
        return '🟡 中';
      case UpdatePriorityLevel.low:
        return '🟢 低';
    }
  }

  String _generateHealthSummary(DependencyHealthReport report) {
    if (report.errors.isNotEmpty) {
      return '发现 ${report.errors.length} 个错误需要立即处理';
    } else if (report.conflicts.isNotEmpty) {
      return '存在 ${report.conflicts.length} 个版本冲突需要解决';
    } else if (report.warnings.isNotEmpty) {
      return '有 ${report.warnings.length} 个警告需要注意';
    } else if (report.outdatedCount > 0) {
      return '${report.outdatedCount} 个依赖可以更新';
    } else {
      return '所有依赖都是最新的';
    }
  }

  /// 导出审计数据为JSON
  Future<Map<String, dynamic>> exportAuditData() async {
    final result = await performFullAudit();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'success': result.success,
      'duration_ms': result.duration.inMilliseconds,
      'health_score': result.healthReport.score.name,
      'metrics': result.healthReport.metrics,
      'dependencies': result.dependencies.map((d) => d.toJson()).toList(),
      'conflicts': result.conflicts.map((c) => c.toJson()).toList(),
      'suggestions': result.suggestions,
    };
  }

  /// 清除缓存
  void clearCache() {
    auditor.clearCache();
  }
}

/// 依赖审计结果
class DependencyAuditResult {
  final bool success;
  final Duration duration;
  final List<DependencyInfo> dependencies;
  final List<VersionConflict> conflicts;
  final DependencyHealthReport healthReport;
  final List<String> suggestions;
  final List<UpdatePriority> priorityUpdates;
  final bool constraintsValid;
  final String? errorMessage;
  final String? errorStack;

  const DependencyAuditResult({
    required this.success,
    required this.duration,
    required this.dependencies,
    required this.conflicts,
    required this.healthReport,
    required this.suggestions,
    required this.priorityUpdates,
    required this.constraintsValid,
    this.errorMessage,
    this.errorStack,
  });
}

/// 依赖健康状态
class DependencyHealthStatus {
  final bool isHealthy;
  final HealthScore score;
  final int errorCount;
  final int warningCount;
  final int conflictCount;
  final int outdatedCount;
  final String summary;

  const DependencyHealthStatus({
    required this.isHealthy,
    required this.score,
    required this.errorCount,
    required this.warningCount,
    required this.conflictCount,
    required this.outdatedCount,
    required this.summary,
  });
}
