import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// 性能指标类型
enum MetricType {
  /// 启动时间
  startupTime,

  /// 内存使用
  memoryUsage,

  /// CPU使用
  cpuUsage,

  /// 网络请求
  networkRequest,

  /// UI渲染
  uiRender,

  /// 磁盘IO
  diskIO,

  /// 自定义指标
  custom,
}

/// 性能指标数据点
class PerformanceDataPoint {
  final String metricName;
  final MetricType metricType;
  final double value;
  final String? unit;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceDataPoint({
    required this.metricName,
    required this.metricType,
    required this.value,
    this.unit,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'metricName': metricName,
      'metricType': metricType.toString().split('.').last,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PerformanceDataPoint.fromJson(Map<String, dynamic> json) {
    return PerformanceDataPoint(
      metricName: json['metricName'] as String,
      metricType: MetricType.values.firstWhere(
        (type) => type.toString().split('.').last == json['metricType'],
        orElse: () => MetricType.custom,
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    final unitStr = unit != null ? ' $unit' : '';
    return '$metricName: ${value.toStringAsFixed(2)}$unitStr (${timestamp.toIso8601String()})';
  }
}

/// 性能指标统计
class PerformanceStatistics {
  final String metricName;
  final List<PerformanceDataPoint> dataPoints;
  DateTime? firstRecordTime;
  DateTime? lastRecordTime;

  PerformanceStatistics({
    required this.metricName,
    required this.dataPoints,
    this.firstRecordTime,
    this.lastRecordTime,
  }) {
    _updateTimeRange();
  }

  void _updateTimeRange() {
    if (dataPoints.isEmpty) return;

    final timestamps = dataPoints.map((dp) => dp.timestamp).toList();
    timestamps.sort();
    firstRecordTime = timestamps.first;
    lastRecordTime = timestamps.last;
  }

  /// 获取平均值
  double get average {
    if (dataPoints.isEmpty) return 0.0;
    final total = dataPoints.fold<double>(0.0, (sum, dp) => sum + dp.value);
    return total / dataPoints.length;
  }

  /// 获取最小值
  double get min {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints.map((dp) => dp.value).reduce((a, b) => a < b ? a : b);
  }

  /// 获取最大值
  double get max {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints.map((dp) => dp.value).reduce((a, b) => a > b ? a : b);
  }

  /// 获取中位数
  double get median {
    if (dataPoints.isEmpty) return 0.0;
    final sortedValues = dataPoints.map((dp) => dp.value).toList()..sort();
    final middle = sortedValues.length ~/ 2;
    if (sortedValues.length % 2 == 0) {
      return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
    } else {
      return sortedValues[middle];
    }
  }

  /// 获取标准差
  double get standardDeviation {
    if (dataPoints.isEmpty) return 0.0;
    final avg = average;
    final variance = dataPoints.fold<double>(
      0.0,
      (sum, dp) => sum + (dp.value - avg) * (dp.value - avg),
    ) / dataPoints.length;
    return variance > 0 ? variance : 0.0;
  }

  /// 获取百分位数
  double getPercentile(int percentile) {
    if (dataPoints.isEmpty) return 0.0;
    final sortedValues = dataPoints.map((dp) => dp.value).toList()..sort();
    final index = (sortedValues.length * percentile / 100).ceil() - 1;
    return sortedValues[index.clamp(0, sortedValues.length - 1)];
  }

  Map<String, dynamic> toJson() {
    return {
      'metricName': metricName,
      'dataPoints': dataPoints.map((dp) => dp.toJson()).toList(),
      'firstRecordTime': firstRecordTime?.toIso8601String(),
      'lastRecordTime': lastRecordTime?.toIso8601String(),
      'statistics': {
        'count': dataPoints.length,
        'average': average,
        'min': min,
        'max': max,
        'median': median,
        'standardDeviation': standardDeviation,
        'p95': getPercentile(95),
        'p99': getPercentile(99),
      },
    };
  }
}

/// 性能优化报告
class OptimizationReport {
  final String reportId;
  final DateTime generatedAt;
  final Map<String, PerformanceStatistics> statistics;
  final List<String> recommendations;
  final Map<String, dynamic> summary;

  OptimizationReport({
    required this.reportId,
    required this.generatedAt,
    required this.statistics,
    required this.recommendations,
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'generatedAt': generatedAt.toIso8601String(),
      'statistics': statistics.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'recommendations': recommendations,
      'summary': summary,
    };
  }

  factory OptimizationReport.fromJson(Map<String, dynamic> json) {
    return OptimizationReport(
      reportId: json['reportId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      statistics: Map<String, PerformanceStatistics>.from(
        (json['statistics'] as Map).map(
          (key, value) => MapEntry(
            key,
            PerformanceStatistics(
              metricName: key,
              dataPoints: (value['dataPoints'] as List)
                  .map((dp) => PerformanceDataPoint.fromJson(dp))
                  .toList(),
            ),
          ),
        ),
      ),
      recommendations: List<String>.from(json['recommendations'] as List),
      summary: Map<String, dynamic>.from(json['summary'] as Map),
    );
  }
}

/// 性能指标追踪器
///
/// 提供全面的性能监控和分析功能：
/// 1. 启动时间追踪
/// 2. 内存使用统计
/// 3. 性能趋势分析
/// 4. 优化建议生成
class PerformanceMetrics {
  static PerformanceMetrics? _instance;
  static const String _metricsFileName = 'performance_metrics.json';
  static const String _reportsFileName = 'optimization_reports.json';

  final Map<String, List<PerformanceDataPoint>> _metricsData = {};
  final Map<String, PerformanceStatistics> _statistics = {};
  final List<OptimizationReport> _reports = [];

  Timer? _saveTimer;
  bool _isEnabled = true;
  int _maxDataPointsPerMetric = 1000;

  PerformanceMetrics._internal() {
    _loadMetrics();
    _startAutoSave();
  }

  static PerformanceMetrics get instance {
    _instance ??= PerformanceMetrics._internal();
    return _instance!;
  }

  /// 启用性能追踪
  void enable() {
    _isEnabled = true;
    Logger.debug('性能指标追踪已启用');
  }

  /// 禁用性能追踪
  void disable() {
    _isEnabled = false;
    Logger.debug('性能指标追踪已禁用');
  }

  /// 记录性能指标
  void recordMetric({
    required String metricName,
    required MetricType metricType,
    required double value,
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    final dataPoint = PerformanceDataPoint(
      metricName: metricName,
      metricType: metricType,
      value: value,
      unit: unit,
      metadata: metadata,
    );

    _metricsData.putIfAbsent(metricName, () => []).add(dataPoint);

    // 限制数据点数量
    if (_metricsData[metricName]!.length > _maxDataPointsPerMetric) {
      _metricsData[metricName]!.removeAt(0);
    }

    // 更新统计信息
    _updateStatistics(metricName);

    // 在调试模式下输出详细信息
    if (kDebugMode) {
      Logger.debug('记录指标: $dataPoint');
    }
  }

  /// 开始计时操作
  Stopwatch startOperationTiming(String operationName) {
    final stopwatch = Stopwatch()..start();
    Logger.debug('开始计时操作: $operationName');
    return stopwatch;
  }

  /// 结束计时操作并记录
  void endOperationTiming({
    required String operationName,
    required Stopwatch stopwatch,
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    stopwatch.stop();
    recordMetric(
      metricName: operationName,
      metricType: MetricType.custom,
      value: stopwatch.elapsedMilliseconds.toDouble(),
      unit: unit ?? 'ms',
      metadata: {
        ...?metadata,
        'operationType': 'timing',
      },
    );
    Logger.debug('操作完成: $operationName (${stopwatch.elapsedMilliseconds}ms)');
  }

  /// 获取指定指标的统计信息
  PerformanceStatistics? getStatistics(String metricName) {
    return _statistics[metricName];
  }

  /// 获取所有统计信息
  Map<String, PerformanceStatistics> getAllStatistics() {
    return Map.unmodifiable(_statistics);
  }

  /// 生成优化报告
  OptimizationReport generateOptimizationReport() {
    final reportId = 'report_${DateTime.now().millisecondsSinceEpoch}';
    final generatedAt = DateTime.now();

    // 分析性能数据并生成建议
    final recommendations = _generateRecommendations();

    // 生成摘要
    final summary = _generateSummary();

    final report = OptimizationReport(
      reportId: reportId,
      generatedAt: generatedAt,
      statistics: Map.from(_statistics),
      recommendations: recommendations,
      summary: summary,
    );

    _reports.add(report);

    // 限制报告数量
    if (_reports.length > 50) {
      _reports.removeAt(0);
    }

    Logger.debug('生成优化报告: $reportId');
    return report;
  }

  /// 获取最近的报告
  List<OptimizationReport> getRecentReports({int limit = 10}) {
    return _reports.reversed.take(limit).toList();
  }

  /// 清除指定指标的数据
  void clearMetric(String metricName) {
    _metricsData.remove(metricName);
    _statistics.remove(metricName);
    Logger.debug('清除指标数据: $metricName');
  }

  /// 清除所有数据
  void clearAllMetrics() {
    _metricsData.clear();
    _statistics.clear();
    Logger.debug('清除所有指标数据');
  }

  /// 导出数据为JSON
  String exportToJson() {
    final data = {
      'metrics': _metricsData.map(
        (name, points) => MapEntry(
          name,
          points.map((dp) => dp.toJson()).toList(),
        ),
      ),
      'statistics': _statistics.map(
        (name, stats) => MapEntry(name, stats.toJson()),
      ),
      'reports': _reports.map((report) => report.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// 导入JSON数据
  bool importFromJson(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // 导入指标数据
      final metrics = data['metrics'] as Map<String, dynamic>;
      for (final entry in metrics.entries) {
        final points = (entry.value as List)
            .map((json) => PerformanceDataPoint.fromJson(json))
            .toList();
        _metricsData[entry.key] = points;
        _updateStatistics(entry.key);
      }

      // 导入报告
      final reports = data['reports'] as List?;
      if (reports != null) {
        _reports.clear();
        for (final reportJson in reports) {
          _reports.add(OptimizationReport.fromJson(reportJson));
        }
      }

      Logger.debug('成功导入性能指标数据');
      return true;
    } catch (e) {
      Logger.debug('导入性能指标数据失败: $e');
      return false;
    }
  }

  /// 设置最大数据点数量
  void setMaxDataPoints(int maxPoints) {
    _maxDataPointsPerMetric = maxPoints;
    Logger.debug('设置最大数据点数量: $maxPoints');
  }

  /// 获取数据点数量
  int getDataPointCount(String metricName) {
    return _metricsData[metricName]?.length ?? 0;
  }

  /// 获取总数据点数量
  int getTotalDataPointCount() {
    return _metricsData.values.fold(0, (sum, list) => sum + list.length);
  }

  /// 释放资源
  Future<void> dispose() async {
    _saveTimer?.cancel();
    await _saveMetrics();
    Logger.debug('性能指标追踪器已释放');
  }

  // 私有方法

  /// 更新统计信息
  void _updateStatistics(String metricName) {
    final dataPoints = _metricsData[metricName];
    if (dataPoints == null || dataPoints.isEmpty) return;

    _statistics[metricName] = PerformanceStatistics(
      metricName: metricName,
      dataPoints: List.from(dataPoints),
    );
  }

  /// 生成优化建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // 分析启动时间
    final startupStats = _statistics['startup_time'];
    if (startupStats != null && startupStats.average > 2000) {
      recommendations.add('平均启动时间较长 (${startupStats.average.toStringAsFixed(0)}ms)，建议优化初始化流程');
      if (startupStats.p95 > 3000) {
        recommendations.add('95%的启动时间超过3秒，存在严重的性能问题');
      }
    }

    // 分析内存使用
    final memoryStats = _statistics['memory_usage'];
    if (memoryStats != null && memoryStats.average > 500) {
      recommendations.add('平均内存使用较高 (${memoryStats.average.toStringAsFixed(0)}MB)，建议优化内存管理');
      if (memoryStats.max > 800) {
        recommendations.add('检测到内存峰值过高 (${memoryStats.max.toStringAsFixed(0)}MB)，可能存在内存泄漏');
      }
    }

    // 分析网络请求
    final networkStats = _statistics['network_request'];
    if (networkStats != null && networkStats.average > 1000) {
      recommendations.add('网络请求时间较长 (${networkStats.average.toStringAsFixed(0)}ms)，建议优化网络层');
    }

    // 分析UI渲染
    final uiStats = _statistics['ui_render'];
    if (uiStats != null && uiStats.p95 > 16) {
      recommendations.add('UI渲染性能不佳 (P95: ${uiStats.p95.toStringAsFixed(1)}ms)，建议优化UI构建');
    }

    // 通用建议
    if (recommendations.isEmpty) {
      recommendations.add('当前性能表现良好，无需特别优化');
    }

    return recommendations;
  }

  /// 生成摘要
  Map<String, dynamic> _generateSummary() {
    return {
      'totalMetrics': _statistics.length,
      'totalDataPoints': getTotalDataPointCount(),
      'recordingStartTime': () {
        final list = _statistics.values
            .map((s) => s.firstRecordTime)
            .whereType<DateTime>()
            .toList()
          ..sort();
        return list.isNotEmpty ? list.first : null;
      }(),
      'lastRecordingTime': () {
        final list = _statistics.values
            .map((s) => s.lastRecordTime)
            .whereType<DateTime>()
            .toList()
          ..sort();
        return list.isNotEmpty ? list.last : null;
      }(),
      'healthStatus': _assessOverallHealth(),
    };
  }

  /// 评估整体健康状态
  String _assessOverallHealth() {
    // 简化的健康评估
    int healthyCount = 0;
    int warningCount = 0;
    int criticalCount = 0;

    for (final stat in _statistics.values) {
      if (stat.metricName.contains('startup') && stat.average > 2000) {
        criticalCount++;
      } else if (stat.metricName.contains('memory') && stat.average > 500) {
        warningCount++;
      } else if (stat.metricName.contains('render') && stat.p95 > 16) {
        warningCount++;
      } else {
        healthyCount++;
      }
    }

    if (criticalCount > 0) return 'critical';
    if (warningCount > 2) return 'warning';
    if (healthyCount > _statistics.length / 2) return 'healthy';
    return 'acceptable';
  }

  /// 开始自动保存
  void _startAutoSave() {
    _saveTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _saveMetrics(),
    );
  }

  /// 保存指标数据
  Future<void> _saveMetrics() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metricsFileName');
      await file.writeAsString(exportToJson());
      Logger.debug('性能指标数据已保存');
    } catch (e) {
      Logger.debug('保存性能指标数据失败: $e');
    }
  }

  /// 加载指标数据
  Future<void> _loadMetrics() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_metricsFileName');

      if (await file.exists()) {
        final jsonData = await file.readAsString();
        importFromJson(jsonData);
        Logger.debug('性能指标数据已加载');
      }
    } catch (e) {
      Logger.debug('加载性能指标数据失败: $e');
    }
  }
}

/// 性能指标追踪器单例访问器
PerformanceMetrics get performanceMetrics => PerformanceMetrics.instance;

/// 便捷的性能计时助手
class PerformanceTimer {
  final String operationName;
  final Stopwatch _stopwatch;

  PerformanceTimer(this.operationName)
      : _stopwatch = Stopwatch()..start() {
    Logger.debug('开始性能计时: $operationName');
  }

  /// 结束计时并记录
  void end({Map<String, dynamic>? metadata}) {
    _stopwatch.stop();
    performanceMetrics.recordMetric(
      metricName: operationName,
      metricType: MetricType.custom,
      value: _stopwatch.elapsedMilliseconds.toDouble(),
      unit: 'ms',
      metadata: {
        ...?metadata,
        'operationType': 'timing',
      },
    );
    Logger.debug('性能计时结束: $operationName (${_stopwatch.elapsedMilliseconds}ms)');
  }

  /// 获取当前耗时
  Duration get elapsed => _stopwatch.elapsed;
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
  double get elapsedSeconds => _stopwatch.elapsedMilliseconds / 1000.0;

  /// 重新开始计时
  void restart() {
    _stopwatch
      ..reset()
      ..start();
  }

  /// 停止计时
  void stop() {
    _stopwatch.stop();
  }
}

/// 创建性能计时器的便捷函数
PerformanceTimer startPerformanceTimer(String operationName) {
  return PerformanceTimer(operationName);
}
