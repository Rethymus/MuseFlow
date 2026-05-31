import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Captured frame timing measurement.
class FrameMeasurement {
  const FrameMeasurement({
    required this.buildDuration,
    required this.rasterDuration,
    required this.totalDuration,
  });

  final Duration buildDuration;
  final Duration rasterDuration;
  final Duration totalDuration;

  double get totalMs => totalDuration.inMicroseconds / 1000.0;
  double get buildMs => buildDuration.inMicroseconds / 1000.0;
  double get rasterMs => rasterDuration.inMicroseconds / 1000.0;

  @override
  String toString() =>
      'Frame(${totalMs.toStringAsFixed(2)}ms: build=${buildMs.toStringAsFixed(2)}, '
      'raster=${rasterMs.toStringAsFixed(2)})';
}

/// Result of a benchmark run at a specific document size.
class BenchmarkResult {
  const BenchmarkResult({
    required this.documentSize,
    required this.frameMeasurements,
  });

  final int documentSize;
  final List<FrameMeasurement> frameMeasurements;

  double get averageFrameTime {
    if (frameMeasurements.isEmpty) return 0;
    final total = frameMeasurements.fold<double>(
      0,
      (sum, m) => sum + m.totalMs,
    );
    return total / frameMeasurements.length;
  }

  double get p95FrameTime {
    if (frameMeasurements.isEmpty) return 0;
    final sorted = frameMeasurements.map((m) => m.totalMs).toList()..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  double get maxFrameTime {
    if (frameMeasurements.isEmpty) return 0;
    return frameMeasurements
        .map((m) => m.totalMs)
        .reduce((a, b) => a > b ? a : b);
  }

  int get jankFrameCount =>
      frameMeasurements.where((m) => m.totalMs > 16.0).length;

  int get totalFrames => frameMeasurements.length;

  @override
  String toString() => '''
BenchmarkResult(size=$documentSize, frames=$totalFrames, avg=${averageFrameTime.toStringAsFixed(2)}ms, p95=${p95FrameTime.toStringAsFixed(2)}ms, max=${maxFrameTime.toStringAsFixed(2)}ms, jank=$jankFrameCount)
''';
}

/// Runs a scroll benchmark on an appflowy_editor document.
///
/// Uses [SchedulerBinding.addTimingsCallback] to capture frame timings
/// during a programmatic scroll from top to bottom of the document.
class AppFlowyEditorBenchmarkRunner {
  AppFlowyEditorBenchmarkRunner({
    required this.editorState,
    required this.scrollController,
  });

  final EditorState editorState;
  final ScrollController scrollController;

  BenchmarkResult? _lastResult;
  BenchmarkResult? get lastResult => _lastResult;

  /// Runs a benchmark: loads text into the editor, scrolls through it,
  /// and captures frame timings.
  ///
  /// Returns the benchmark result with frame time measurements.
  Future<BenchmarkResult> runBenchmark(
    int documentSize,
    String text,
  ) async {
    final timings = <FrameMeasurement>[];
    late final TimingsCallback callback;

    // Install frame timing callback
    callback = (List<FrameTiming> frameTimings) {
      for (final timing in frameTimings) {
        timings.add(
          FrameMeasurement(
            buildDuration: timing.buildDuration,
            rasterDuration: timing.rasterDuration,
            totalDuration: timing.totalSpan,
          ),
        );
      }
    };
    SchedulerBinding.instance.addTimingsCallback(callback);

    try {
      // Load text into the editor
      loadText(text);

      // Wait for the editor to settle
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _pumpFrames();

      // Scroll from top to bottom, capturing frame timings
      final maxScroll = scrollController.position.maxScrollExtent;
      final scrollDuration = Duration(
        milliseconds: (maxScroll / 2).ceil().clamp(2000, 10000),
      );

      await scrollController.animateTo(
        maxScroll,
        duration: scrollDuration,
        curve: Curves.linear,
      );

      // Wait for remaining frames to be reported
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _pumpFrames();
    } finally {
      SchedulerBinding.instance.removeTimingsCallback(callback);
    }

    _lastResult = BenchmarkResult(
      documentSize: documentSize,
      frameMeasurements: timings,
    );
    return _lastResult!;
  }

  /// Loads text into the editor document as paragraph nodes.
  void loadText(String text) {
    // Split text into paragraphs
    final paragraphs = text.split('\n\n');

    // Build new paragraph nodes
    final nodes = <Node>[];
    for (var i = 0; i < paragraphs.length; i++) {
      final delta = Delta()..insert(paragraphs[i]);
      nodes.add(
        Node(
          type: 'paragraph',
          attributes: {
            'delta': delta.toJson(),
          },
        ),
      );
    }

    // Apply the new document via a transaction
    final transaction = editorState.transaction;

    // Delete all existing children of root
    final root = editorState.document.root;
    final existingChildren = root.children.toList();
    for (final child in existingChildren) {
      transaction.deleteNode(child);
    }

    // Insert new nodes at path [0], [1], [2], etc.
    for (var i = 0; i < nodes.length; i++) {
      transaction.insertNode([i], nodes[i], deepCopy: false);
    }

    editorState.apply(transaction);
  }

  /// Pumps pending frames to ensure rendering is complete.
  Future<void> _pumpFrames() async {
    await Future<void>.delayed(Duration.zero);
  }
}
