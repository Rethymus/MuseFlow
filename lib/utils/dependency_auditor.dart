import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// 依赖项信息模型
class DependencyInfo {
  final String name;
  final String currentVersion;
  final String? latestVersion;
  final DependencyType type;
  final List<String> licenses;
  final DateTime? lastUpdated;
  final List<DependencyConstraint> constraints;

  const DependencyInfo({
    required this.name,
    required this.currentVersion,
    this.latestVersion,
    required this.type,
    this.licenses = const [],
    this.lastUpdated,
    this.constraints = const [],
  });

  bool get isOutdated =>
      latestVersion != null && currentVersion != latestVersion;

  bool get hasLicenseCompliance => licenses.isNotEmpty;

  factory DependencyInfo.fromJson(Map<String, dynamic> json) {
    return DependencyInfo(
      name: json['name'] as String,
      currentVersion: json['currentVersion'] as String,
      latestVersion: json['latestVersion'] as String?,
      type: DependencyType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DependencyType.direct,
      ),
      licenses: (json['licenses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      constraints: (json['constraints'] as List<dynamic>?)
              ?.map((e) =>
                  DependencyConstraint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'type': type.name,
      'licenses': licenses,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'constraints': constraints.map((e) => e.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DependencyInfo &&
        other.name == name &&
        other.currentVersion == currentVersion;
  }

  @override
  int get hashCode => Object.hash(name, currentVersion);
}

/// 依赖约束信息
class DependencyConstraint {
  final String packageName;
  final String constraint;
  final String reason;
  final DateTime imposedAt;
  final String? source;

  const DependencyConstraint({
    required this.packageName,
    required this.constraint,
    required this.reason,
    required this.imposedAt,
    this.source,
  });

  factory DependencyConstraint.fromJson(Map<String, dynamic> json) {
    return DependencyConstraint(
      packageName: json['packageName'] as String,
      constraint: json['constraint'] as String,
      reason: json['reason'] as String,
      imposedAt: DateTime.parse(json['imposedAt'] as String),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'constraint': constraint,
      'reason': reason,
      'imposedAt': imposedAt.toIso8601String(),
      'source': source,
    };
  }
}

/// 依赖类型
enum DependencyType {
  direct,
  transitive,
  dev,
  overridden,
}

/// 版本冲突信息
class VersionConflict {
  final String packageName;
  final List<String> conflictingVersions;
  final List<String> dependents;
  final String resolution;
  final ConflictSeverity severity;

  const VersionConflict({
    required this.packageName,
    required this.conflictingVersions,
    required this.dependents,
    required this.resolution,
    required this.severity,
  });

  factory VersionConflict.fromJson(Map<String, dynamic> json) {
    return VersionConflict(
      packageName: json['packageName'] as String,
      conflictingVersions: (json['conflictingVersions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dependents: (json['dependents'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      resolution: json['resolution'] as String,
      severity: ConflictSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ConflictSeverity.warning,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'conflictingVersions': conflictingVersions,
      'dependents': dependents,
      'resolution': resolution,
      'severity': severity.name,
    };
  }
}

/// 冲突严重程度
enum ConflictSeverity {
  error,
  warning,
  info,
}

/// 依赖健康报告
class DependencyHealthReport {
  final DateTime generatedAt;
  final List<DependencyInfo> dependencies;
  final List<VersionConflict> conflicts;
  final List<String> warnings;
  final List<String> errors;
  final HealthScore score;
  final Map<String, dynamic> metrics;

  const DependencyHealthReport({
    required this.generatedAt,
    required this.dependencies,
    required this.conflicts,
    required this.warnings,
    required this.errors,
    required this.score,
    required this.metrics,
  });

  factory DependencyHealthReport.fromJson(Map<String, dynamic> json) {
    return DependencyHealthReport(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      dependencies: (json['dependencies'] as List<dynamic>)
          .map((e) => DependencyInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      conflicts: (json['conflicts'] as List<dynamic>)
          .map((e) => VersionConflict.fromJson(e as Map<String, dynamic>))
          .toList(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
      score: HealthScore.values.firstWhere(
        (e) => e.name == json['score'],
        orElse: () => HealthScore.good,
      ),
      metrics: json['metrics'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'dependencies': dependencies.map((e) => e.toJson()).toList(),
      'conflicts': conflicts.map((e) => e.toJson()).toList(),
      'warnings': warnings,
      'errors': errors,
      'score': score.name,
      'metrics': metrics,
    };
  }

  int get totalDependencies => dependencies.length;
  int get outdatedCount => dependencies.where((d) => d.isOutdated).length;
  int get conflictCount => conflicts.length;
  double get outdatedPercentage =>
      totalDependencies > 0 ? (outdatedCount / totalDependencies) * 100 : 0;
}

/// 健康评分
enum HealthScore {
  excellent,
  good,
  fair,
  poor,
  critical,
}

/// 依赖变更日志
class DependencyChangeLog {
  final DateTime timestamp;
  final String packageName;
  final String oldVersion;
  final String newVersion;
  final ChangeReason reason;
  final String? author;
  final String? notes;

  const DependencyChangeLog({
    required this.timestamp,
    required this.packageName,
    required this.oldVersion,
    required this.newVersion,
    required this.reason,
    this.author,
    this.notes,
  });

  factory DependencyChangeLog.fromJson(Map<String, dynamic> json) {
    return DependencyChangeLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      packageName: json['packageName'] as String,
      oldVersion: json['oldVersion'] as String,
      newVersion: json['newVersion'] as String,
      reason: ChangeReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => ChangeReason.manual,
      ),
      author: json['author'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'packageName': packageName,
      'oldVersion': oldVersion,
      'newVersion': newVersion,
      'reason': reason.name,
      'author': author,
      'notes': notes,
    };
  }
}

/// 变更原因
enum ChangeReason {
  manual,
  security,
  feature,
  bugfix,
  compatibility,
  dependencyUpdate,
}

/// 依赖审计器
class DependencyAuditor {
  final String projectPath;
  final File pubspecFile;
  final File auditLog;
  final File healthReportFile;
  final File constraintsFile;

  // ignore: unused_field
  List<DependencyInfo>? _cachedDependencies;
  // ignore: unused_field
  List<VersionConflict>? _cachedConflicts;
  List<DependencyChangeLog>? _cachedChangeLog;

  DependencyAuditor({required this.projectPath})
      : pubspecFile = File(path.join(projectPath, 'pubspec.yaml')),
        auditLog = File(path.join(projectPath, '.dependency_audit_log.json')),
        healthReportFile =
            File(path.join(projectPath, '.dependency_health_report.json')),
        constraintsFile =
            File(path.join(projectPath, '.dependency_constraints.json'));

  /// 解析 pubspec.yaml 获取依赖信息
  Future<List<DependencyInfo>> parseDependencies() async {
    if (!pubspecFile.existsSync()) {
      throw FileSystemException('pubspec.yaml not found', pubspecFile.path);
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    final dependencies = <DependencyInfo>[];
    DependencyType currentType = DependencyType.direct;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('dependencies:')) {
        currentType = DependencyType.direct;
      } else if (line.startsWith('dev_dependencies:')) {
        currentType = DependencyType.dev;
      } else if (line.startsWith('dependency_overrides:')) {
        currentType = DependencyType.overridden;
      } else if (line.startsWith('#') ||
          line.isEmpty ||
          line.startsWith('environment:') ||
          line.startsWith('flutter:')) {
        continue;
      } else {
        final match = RegExp(r'^([\w_-]+):\s*([\d.]+)').firstMatch(line);
        if (match != null) {
          final name = match.group(1)!;
          final version = match.group(2)!;

          dependencies.add(DependencyInfo(
            name: name,
            currentVersion: version,
            latestVersion: null, // 将由 updateWithLatestVersions 填充
            type: currentType,
            licenses: [],
            lastUpdated: DateTime.now(),
            constraints: [],
          ));
        }
      }
    }

    _cachedDependencies = dependencies;
    return dependencies;
  }

  /// 检测版本冲突
  Future<List<VersionConflict>> detectConflicts() async {
    final dependencies = await parseDependencies();
    final conflicts = <VersionConflict>[];

    // 检查重复依赖（不同版本）
    final depMap = <String, List<DependencyInfo>>{};
    for (final dep in dependencies) {
      depMap.putIfAbsent(dep.name, () => []).add(dep);
    }

    for (final entry in depMap.entries) {
      if (entry.value.length > 1) {
        final versions =
            entry.value.map((d) => d.currentVersion).toSet().toList();
        if (versions.length > 1) {
          conflicts.add(VersionConflict(
            packageName: entry.key,
            conflictingVersions: versions,
            dependents: entry.value.map((d) => d.type.name).toList(),
            resolution: '使用统一的版本号: ${versions.first}',
            severity: ConflictSeverity.error,
          ));
        }
      }
    }

    // 检查已知的兼容性问题
    final knownConflicts = _checkKnownCompatibilityIssues(dependencies);
    conflicts.addAll(knownConflicts);

    _cachedConflicts = conflicts;
    return conflicts;
  }

  /// 检查已知的兼容性问题
  List<VersionConflict> _checkKnownCompatibilityIssues(
      List<DependencyInfo> dependencies) {
    final conflicts = <VersionConflict>[];
    final depMap = {for (var d in dependencies) d.name: d.currentVersion};

    // 检查 Flutter SDK 兼容性
    final flutterVersion = depMap['flutter'];
    if (flutterVersion != null) {
      // window_manager 兼容性检查
      if (depMap.containsKey('window_manager')) {
        final wmVersion = depMap['window_manager']!;
        if (_versionCompare(wmVersion, '0.3.0') < 0) {
          conflicts.add(VersionConflict(
            packageName: 'window_manager',
            conflictingVersions: [wmVersion],
            dependents: ['flutter'],
            resolution: '升级 window_manager 到 0.3.0 或更高版本',
            severity: ConflictSeverity.warning,
          ));
        }
      }
    }

    // 检查 Hive 版本兼容性
    if (depMap.containsKey('hive') && depMap.containsKey('hive_flutter')) {
      final hiveVersion = depMap['hive']!;
      final hiveFlutterVersion = depMap['hive_flutter']!;
      // 确保主版本号一致
      if (hiveVersion.split('.')[0] != hiveFlutterVersion.split('.')[0]) {
        conflicts.add(VersionConflict(
          packageName: 'hive',
          conflictingVersions: [hiveVersion, hiveFlutterVersion],
          dependents: ['hive_flutter'],
          resolution: '确保 hive 和 hive_flutter 使用相同的主版本号',
          severity: ConflictSeverity.error,
        ));
      }
    }

    return conflicts;
  }

  /// 版本比较
  int _versionCompare(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1.compareTo(p2);
    }
    return 0;
  }

  /// 生成依赖健康报告
  Future<DependencyHealthReport> generateHealthReport() async {
    final dependencies = await parseDependencies();
    final conflicts = await detectConflicts();

    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};

    // 计算指标
    final totalDeps = dependencies.length;
    final directDeps =
        dependencies.where((d) => d.type == DependencyType.direct).length;
    final transitiveDeps =
        dependencies.where((d) => d.type == DependencyType.transitive).length;
    final devDeps =
        dependencies.where((d) => d.type == DependencyType.dev).length;
    final outdatedDeps = dependencies.where((d) => d.isOutdated).length;

    metrics['totalDependencies'] = totalDeps;
    metrics['directDependencies'] = directDeps;
    metrics['transitiveDependencies'] = transitiveDeps;
    metrics['devDependencies'] = devDeps;
    metrics['outdatedDependencies'] = outdatedDeps;

    // 检查过时的依赖
    for (final dep in dependencies) {
      if (dep.isOutdated) {
        warnings.add(
            '${dep.name}: 当前版本 ${dep.currentVersion}, 最新版本 ${dep.latestVersion}');
      }
    }

    // 检查冲突
    for (final conflict in conflicts) {
      if (conflict.severity == ConflictSeverity.error) {
        errors.add('版本冲突: ${conflict.packageName} - ${conflict.resolution}');
      } else {
        warnings.add('版本警告: ${conflict.packageName} - ${conflict.resolution}');
      }
    }

    // 检查许可证合规性
    for (final dep in dependencies) {
      if (!dep.hasLicenseCompliance && dep.type == DependencyType.direct) {
        warnings.add('${dep.name}: 缺少许可证信息');
      }
    }

    // 计算健康评分
    final score = _calculateHealthScore(
        totalDeps, conflicts.length, warnings.length, errors.length);

    final report = DependencyHealthReport(
      generatedAt: DateTime.now(),
      dependencies: dependencies,
      conflicts: conflicts,
      warnings: warnings,
      errors: errors,
      score: score,
      metrics: metrics,
    );

    await _saveHealthReport(report);
    return report;
  }

  /// 计算健康评分
  HealthScore _calculateHealthScore(
      int totalDeps, int conflicts, int warnings, int errors) {
    if (errors > 0) return HealthScore.critical;
    if (conflicts > 2) return HealthScore.poor;
    if (conflicts > 0 || warnings > 5) return HealthScore.fair;
    if (warnings > 0) return HealthScore.good;
    return HealthScore.excellent;
  }

  /// 添加依赖变更日志
  Future<void> logChange({
    required String packageName,
    required String oldVersion,
    required String newVersion,
    required ChangeReason reason,
    String? author,
    String? notes,
  }) async {
    final changeLog = DependencyChangeLog(
      timestamp: DateTime.now(),
      packageName: packageName,
      oldVersion: oldVersion,
      newVersion: newVersion,
      reason: reason,
      author: author,
      notes: notes,
    );

    final existingLogs = await loadChangeLogs();
    existingLogs.add(changeLog);

    await auditLog.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        existingLogs.map((e) => e.toJson()).toList(),
      ),
    );

    _cachedChangeLog = null; // 清除缓存
  }

  /// 加载变更日志
  Future<List<DependencyChangeLog>> loadChangeLogs() async {
    if (_cachedChangeLog != null) return _cachedChangeLog!;

    if (!auditLog.existsSync()) {
      return [];
    }

    final content = await auditLog.readAsString();
    if (content.trim().isEmpty) return [];

    try {
      final json = jsonDecode(content) as List<dynamic>;
      _cachedChangeLog = json
          .map((e) => DependencyChangeLog.fromJson(e as Map<String, dynamic>))
          .toList();
      return _cachedChangeLog!;
    } catch (e) {
      return [];
    }
  }

  /// 获取依赖更新建议
  Future<List<String>> getUpdateSuggestions() async {
    final dependencies = await parseDependencies();
    final conflicts = await detectConflicts();
    final suggestions = <String>[];

    // 基于冲突的建议
    for (final conflict in conflicts) {
      suggestions
          .add('修复 ${conflict.packageName} 的版本冲突: ${conflict.resolution}');
    }

    // 基于过时依赖的建议
    for (final dep in dependencies) {
      if (dep.isOutdated && dep.type == DependencyType.direct) {
        suggestions.add(
            '考虑升级 ${dep.name} 从 ${dep.currentVersion} 到 ${dep.latestVersion}');
      }
    }

    // 安全性建议
    final securityDeps = ['http', 'dio', 'flutter_secure_storage', 'encrypt'];
    for (final depName in securityDeps) {
      final dep = dependencies.firstWhereOrNull((d) => d.name == depName);
      if (dep != null && dep.isOutdated) {
        suggestions.add('安全建议: 优先升级 ${dep.name} 以获得最新的安全补丁');
      }
    }

    return suggestions;
  }

  /// 验证依赖约束
  Future<bool> validateConstraints() async {
    if (!constraintsFile.existsSync()) {
      return true;
    }

    final content = await constraintsFile.readAsString();
    if (content.trim().isEmpty) return true;

    try {
      final json = jsonDecode(content) as List<dynamic>;
      final constraints = json
          .map((e) => DependencyConstraint.fromJson(e as Map<String, dynamic>))
          .toList();

      final dependencies = await parseDependencies();
      final depMap = {for (var d in dependencies) d.name: d.currentVersion};

      for (final constraint in constraints) {
        if (depMap.containsKey(constraint.packageName)) {
          final currentVersion = depMap[constraint.packageName]!;
          if (!_satisfiesConstraint(currentVersion, constraint.constraint)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查版本是否满足约束
  bool _satisfiesConstraint(String version, String constraint) {
    // 简化实现：检查精确匹配
    if (constraint.startsWith('=')) {
      return version == constraint.substring(1);
    }
    if (constraint.startsWith('>=')) {
      return _versionCompare(version, constraint.substring(2)) >= 0;
    }
    if (constraint.startsWith('>')) {
      return _versionCompare(version, constraint.substring(1)) > 0;
    }
    if (constraint.startsWith('<=')) {
      return _versionCompare(version, constraint.substring(2)) <= 0;
    }
    if (constraint.startsWith('<')) {
      return _versionCompare(version, constraint.substring(1)) < 0;
    }
    // 默认精确匹配
    return version == constraint;
  }

  /// 保存健康报告
  Future<void> _saveHealthReport(DependencyHealthReport report) async {
    await healthReportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report.toJson()),
    );
  }

  /// 打印报告摘要
  String printReportSummary(DependencyHealthReport report) {
    final buffer = StringBuffer();

    buffer.writeln('=== MuseFlow 依赖健康报告 ===');
    buffer.writeln('生成时间: ${report.generatedAt.toIso8601String()}');
    buffer
        .writeln('健康评分: ${_getScoreEmoji(report.score)} ${report.score.name}');
    buffer.writeln();

    buffer.writeln('📊 指标摘要:');
    buffer.writeln('  总依赖数: ${report.totalDependencies}');
    buffer.writeln(
        '  过时依赖: ${report.outdatedCount} (${report.outdatedPercentage.toStringAsFixed(1)}%)');
    buffer.writeln('  版本冲突: ${report.conflictCount}');
    buffer.writeln('  警告数: ${report.warnings.length}');
    buffer.writeln('  错误数: ${report.errors.length}');
    buffer.writeln();

    if (report.errors.isNotEmpty) {
      buffer.writeln('❌ 错误:');
      for (final error in report.errors) {
        buffer.writeln('  - $error');
      }
      buffer.writeln();
    }

    if (report.conflicts.isNotEmpty) {
      buffer.writeln('⚠️  版本冲突:');
      for (final conflict in report.conflicts) {
        buffer.writeln('  - ${conflict.packageName}: ${conflict.resolution}');
      }
      buffer.writeln();
    }

    if (report.warnings.isNotEmpty) {
      buffer.writeln('⚡ 警告:');
      for (final warning in report.warnings.take(10)) {
        buffer.writeln('  - $warning');
      }
      if (report.warnings.length > 10) {
        buffer.writeln('  ... 还有 ${report.warnings.length - 10} 个警告');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _getScoreEmoji(HealthScore score) {
    switch (score) {
      case HealthScore.excellent:
        return '🟢';
      case HealthScore.good:
        return '🟡';
      case HealthScore.fair:
        return '🟠';
      case HealthScore.poor:
        return '🔴';
      case HealthScore.critical:
        return '🚨';
    }
  }

  /// 清除缓存
  void clearCache() {
    _cachedDependencies = null;
    _cachedConflicts = null;
    _cachedChangeLog = null;
  }
}

/// 依赖更新建议器
class DependencyUpdateAdvisor {
  final DependencyAuditor auditor;

  DependencyUpdateAdvisor({required this.auditor});

  /// 获取优先级更新的依赖
  Future<List<UpdatePriority>> getPriorityUpdates() async {
    final dependencies = await auditor.parseDependencies();
    final conflicts = await auditor.detectConflicts();
    final priorities = <UpdatePriority>[];

    // 安全更新（最高优先级）
    final securityDeps = [
      'http',
      'dio',
      'flutter_secure_storage',
      'encrypt',
      'retry'
    ];
    for (final depName in securityDeps) {
      final dep = dependencies.firstWhereOrNull((d) => d.name == depName);
      if (dep != null && dep.isOutdated) {
        priorities.add(UpdatePriority(
          packageName: dep.name,
          currentVersion: dep.currentVersion,
          suggestedVersion: dep.latestVersion ?? dep.currentVersion,
          priority: UpdatePriorityLevel.critical,
          reason: '安全更新: 修复已知安全漏洞',
        ));
      }
    }

    // 冲突解决（高优先级）
    for (final conflict in conflicts) {
      if (conflict.severity == ConflictSeverity.error) {
        final dep = dependencies
            .firstWhereOrNull((d) => d.name == conflict.packageName);
        if (dep != null) {
          priorities.add(UpdatePriority(
            packageName: dep.name,
            currentVersion: dep.currentVersion,
            suggestedVersion: conflict.conflictingVersions.first,
            priority: UpdatePriorityLevel.high,
            reason: '解决版本冲突: ${conflict.resolution}',
          ));
        }
      }
    }

    // 主要依赖更新（中等优先级）
    final coreDeps = ['provider', 'hive', 'sqflite', 'window_manager'];
    for (final depName in coreDeps) {
      final dep = dependencies.firstWhereOrNull((d) => d.name == depName);
      if (dep != null && dep.isOutdated) {
        priorities.add(UpdatePriority(
          packageName: dep.name,
          currentVersion: dep.currentVersion,
          suggestedVersion: dep.latestVersion ?? dep.currentVersion,
          priority: UpdatePriorityLevel.medium,
          reason: '主要依赖更新: 获得最新功能改进',
        ));
      }
    }

    // 其他依赖更新（低优先级）
    for (final dep in dependencies) {
      if (dep.isOutdated &&
          dep.type == DependencyType.direct &&
          !priorities.any((p) => p.packageName == dep.name)) {
        priorities.add(UpdatePriority(
          packageName: dep.name,
          currentVersion: dep.currentVersion,
          suggestedVersion: dep.latestVersion ?? dep.currentVersion,
          priority: UpdatePriorityLevel.low,
          reason: '常规更新: 小版本改进和bug修复',
        ));
      }
    }

    // 按优先级排序
    priorities.sort((a, b) => _comparePriority(a.priority, b.priority));

    return priorities;
  }

  int _comparePriority(UpdatePriorityLevel a, UpdatePriorityLevel b) {
    const order = [
      UpdatePriorityLevel.critical,
      UpdatePriorityLevel.high,
      UpdatePriorityLevel.medium,
      UpdatePriorityLevel.low,
    ];
    return order.indexOf(a).compareTo(order.indexOf(b));
  }
}

/// 更新优先级信息
class UpdatePriority {
  final String packageName;
  final String currentVersion;
  final String suggestedVersion;
  final UpdatePriorityLevel priority;
  final String reason;

  const UpdatePriority({
    required this.packageName,
    required this.currentVersion,
    required this.suggestedVersion,
    required this.priority,
    required this.reason,
  });
}

/// 更新优先级等级
enum UpdatePriorityLevel {
  critical,
  high,
  medium,
  low,
}
