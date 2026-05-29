import 'dart:async';
import 'package:flutter/foundation.dart';
import 'secure_data_service.dart';

/// Performance monitoring service for encryption operations.
///
/// Tracks encryption/decryption performance metrics and provides
/// analytics for optimization and security monitoring.
class EncryptionPerformanceMonitor {
  static final EncryptionPerformanceMonitor instance =
      EncryptionPerformanceMonitor._internal();
  factory EncryptionPerformanceMonitor() => instance;
  EncryptionPerformanceMonitor._internal();

  // Performance metrics
  final List<OperationMetric> _metrics = [];
  final StreamController<OperationMetric> _metricsController =
      StreamController<OperationMetric>.broadcast();

  // Statistics
  int _totalOperations = 0;
  int _failedOperations = 0;
  int _totalBytesProcessed = 0;

  /// Stream of metrics for real-time monitoring
  Stream<OperationMetric> get metricsStream => _metricsController.stream;

  /// Get all collected metrics
  List<OperationMetric> get metrics => List.unmodifiable(_metrics);

  /// Record an encryption operation
  void recordOperation({
    required String operation,
    required int durationMs,
    required int dataSize,
    bool success = true,
    String? errorMessage,
  }) {
    final metric = OperationMetric(
      operation: operation,
      durationMs: durationMs,
      dataSize: dataSize,
      timestamp: DateTime.now(),
      success: success,
      errorMessage: errorMessage,
    );

    _metrics.add(metric);
    _metricsController.add(metric);

    if (success) {
      _totalOperations++;
      _totalBytesProcessed += dataSize;
    } else {
      _failedOperations++;
    }

    // Keep only last 1000 metrics to avoid memory issues
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// Measure and record an operation automatically
  Future<T> measureOperation<T>({
    required String operation,
    required Future<T> Function() operationFn,
    int? dataSize,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operationFn();
      stopwatch.stop();

      recordOperation(
        operation: operation,
        durationMs: stopwatch.elapsedMilliseconds,
        dataSize: dataSize ?? 0,
        success: true,
      );

      return result;
    } catch (e) {
      stopwatch.stop();

      recordOperation(
        operation: operation,
        durationMs: stopwatch.elapsedMilliseconds,
        dataSize: dataSize ?? 0,
        success: false,
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// Get performance statistics
  PerformanceStats getStatistics() {
    if (_metrics.isEmpty) {
      return PerformanceStats.empty();
    }

    final encryptMetrics =
        _metrics.where((m) => m.operation == 'encrypt').toList();
    final decryptMetrics =
        _metrics.where((m) => m.operation == 'decrypt').toList();

    final encryptStats = _calculateOperationStats('encrypt', encryptMetrics);
    final decryptStats = _calculateOperationStats('decrypt', decryptMetrics);

    return PerformanceStats(
      totalOperations: _totalOperations,
      failedOperations: _failedOperations,
      successRate: _totalOperations > 0
          ? ((_totalOperations - _failedOperations) / _totalOperations * 100)
          : 100.0,
      totalBytesProcessed: _totalBytesProcessed,
      encryptStats: encryptStats,
      decryptStats: decryptStats,
      averageOperationTime: _calculateAverageTime(),
    );
  }

  /// Calculate statistics for specific operation type
  OperationStats _calculateOperationStats(
      String operation, List<OperationMetric> metrics) {
    if (metrics.isEmpty) {
      return OperationStats(operation: operation);
    }

    final durations = metrics.map((m) => m.durationMs).toList();
    durations.sort();

    final avg = durations.reduce((a, b) => a + b) / durations.length;
    final median = durations[durations.length ~/ 2];
    final p95 = durations[(durations.length * 0.95).floor()];
    final p99 = durations[(durations.length * 0.99).floor()];
    final min = durations.first;
    final max = durations.last;

    final totalBytes = metrics.fold<int>(0, (sum, m) => sum + m.dataSize);
    final avgThroughput =
        totalBytes / durations.reduce((a, b) => a + b) * 1000; // bytes/second

    return OperationStats(
      operation: operation,
      count: metrics.length,
      averageTime: avg,
      medianTime: median,
      p95Time: p95,
      p99Time: p99,
      minTime: min,
      maxTime: max,
      totalBytesProcessed: totalBytes,
      averageThroughput: avgThroughput,
    );
  }

  /// Calculate average operation time across all operations
  double _calculateAverageTime() {
    if (_metrics.isEmpty) return 0.0;

    final total = _metrics.fold<int>(0, (sum, m) => sum + m.durationMs);
    return total / _metrics.length;
  }

  /// Get slow operations (above threshold)
  List<OperationMetric> getSlowOperations({int thresholdMs = 100}) {
    return _metrics.where((m) => m.durationMs > thresholdMs).toList()
      ..sort((a, b) => b.durationMs.compareTo(a.durationMs));
  }

  /// Get failed operations
  List<OperationMetric> getFailedOperations() {
    return _metrics.where((m) => !m.success).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _totalOperations = 0;
    _failedOperations = 0;
    _totalBytesProcessed = 0;
  }

  /// Export metrics as JSON
  Map<String, dynamic> exportToJson() {
    return {
      'statistics': getStatistics().toJson(),
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _metricsController.close();
  }
}

/// Individual operation metric
class OperationMetric {
  final String operation;
  final int durationMs;
  final int dataSize;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  OperationMetric({
    required this.operation,
    required this.durationMs,
    required this.dataSize,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });

  double get durationSeconds => durationMs / 1000.0;
  double get throughput => dataSize / durationSeconds; // bytes/second

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration_ms': durationMs,
      'data_size': dataSize,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
      'error_message': errorMessage,
      'throughput': throughput,
    };
  }

  @override
  String toString() {
    return 'OperationMetric(operation: $operation, duration: ${durationMs}ms, size: $dataSize bytes, success: $success)';
  }
}

/// Performance statistics summary
class PerformanceStats {
  final int totalOperations;
  final int failedOperations;
  final double successRate;
  final int totalBytesProcessed;
  final OperationStats encryptStats;
  final OperationStats decryptStats;
  final double averageOperationTime;

  PerformanceStats({
    required this.totalOperations,
    required this.failedOperations,
    required this.successRate,
    required this.totalBytesProcessed,
    required this.encryptStats,
    required this.decryptStats,
    required this.averageOperationTime,
  });

  factory PerformanceStats.empty() {
    return PerformanceStats(
      totalOperations: 0,
      failedOperations: 0,
      successRate: 100.0,
      totalBytesProcessed: 0,
      encryptStats: OperationStats.empty('encrypt'),
      decryptStats: OperationStats.empty('decrypt'),
      averageOperationTime: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_operations': totalOperations,
      'failed_operations': failedOperations,
      'success_rate': successRate,
      'total_bytes_processed': totalBytesProcessed,
      'encrypt_stats': encryptStats.toJson(),
      'decrypt_stats': decryptStats.toJson(),
      'average_operation_time': averageOperationTime,
    };
  }

  @override
  String toString() {
    return 'PerformanceStats(operations: $totalOperations, success_rate: ${successRate.toStringAsFixed(1)}%, avg_time: ${averageOperationTime.toStringAsFixed(2)}ms)';
  }
}

/// Statistics for a specific operation type
class OperationStats {
  final String operation;
  final int count;
  final double averageTime;
  final double medianTime;
  final double p95Time;
  final double p99Time;
  final double minTime;
  final double maxTime;
  final int totalBytesProcessed;
  final double averageThroughput;

  OperationStats({
    required this.operation,
    this.count = 0,
    this.averageTime = 0.0,
    this.medianTime = 0.0,
    this.p95Time = 0.0,
    this.p99Time = 0.0,
    this.minTime = 0.0,
    this.maxTime = 0.0,
    this.totalBytesProcessed = 0,
    this.averageThroughput = 0.0,
  });

  factory OperationStats.empty(String operation) {
    return OperationStats(operation: operation);
  }

  double get throughputMBps => averageThroughput / (1024 * 1024);
  double get avgTimeMs => averageTime;
  double get p95TimeMs => p95Time;
  double get p99TimeMs => p99Time;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'count': count,
      'average_time_ms': averageTime,
      'median_time_ms': medianTime,
      'p95_time_ms': p95Time,
      'p99_time_ms': p99Time,
      'min_time_ms': minTime,
      'max_time_ms': maxTime,
      'total_bytes_processed': totalBytesProcessed,
      'average_throughput_bps': averageThroughput,
    };
  }

  @override
  String toString() {
    return 'OperationStats(op: $operation, count: $count, avg: ${averageTime.toStringAsFixed(2)}ms, p95: ${p95Time.toStringAsFixed(2)}ms)';
  }
}

/// Performance utility for measuring operations
class PerformanceTimer {
  final Stopwatch _stopwatch = Stopwatch();
  final String _operation;
  final EncryptionPerformanceMonitor _monitor;

  PerformanceTimer(this._operation, this._monitor) {
    _stopwatch.start();
  }

  /// Stop the timer and record the metric
  void stop(
      {required int dataSize, bool success = true, String? errorMessage}) {
    _stopwatch.stop();
    _monitor.recordOperation(
      operation: _operation,
      durationMs: _stopwatch.elapsedMilliseconds,
      dataSize: dataSize,
      success: success,
      errorMessage: errorMessage,
    );
  }

  /// Get elapsed time without stopping
  int get elapsedMs => _stopwatch.elapsedMilliseconds;

  /// Stop and return elapsed time
  int stopAndGetTime() {
    _stopwatch.stop();
    return _stopwatch.elapsedMilliseconds;
  }
}
