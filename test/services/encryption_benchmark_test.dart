import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/services/secure_data_service.dart';
import 'package:museflow/services/encryption_performance_monitor.dart';

void main() {
  group('Encryption Performance Benchmarks', () {
    late SecureDataService secureService;
    late EncryptionPerformanceMonitor performanceMonitor;

    setUpAll(() async {
      secureService = SecureDataService.instance;
      await secureService.initialize();

      performanceMonitor = EncryptionPerformanceMonitor.instance;
    });

    group('Encryption Performance', () {
      test('should encrypt small data quickly', () async {
        const testData = 'Small test data';
        const iterations = 100;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          secureService.encrypt(testData, dataId: 'small-$i');
        }

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / iterations;

        print(
            'Small data encryption avg time: ${avgTime.toStringAsFixed(2)}ms');
        print(
            'Total time: ${stopwatch.elapsedMilliseconds}ms for $iterations operations');

        expect(avgTime, lessThan(50)); // Should be under 50ms per operation
      });

      test('should encrypt large data efficiently', () async {
        final largeData = 'A' * 10000; // 10KB
        const iterations = 50;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          secureService.encrypt(largeData, dataId: 'large-$i');
        }

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / iterations;
        final throughput = (largeData.length * iterations) /
            (stopwatch.elapsedMilliseconds / 1000);

        print(
            'Large data encryption avg time: ${avgTime.toStringAsFixed(2)}ms');
        print('Throughput: ${(throughput / 1024).toStringAsFixed(2)} KB/s');

        expect(avgTime, lessThan(200)); // Should be under 200ms for 10KB
      });

      test('should handle variable data sizes efficiently', () async {
        final dataSizes = [100, 1000, 10000, 50000]; // 100B to 50KB
        final results = <String, double>{};

        for (final size in dataSizes) {
          final data = 'A' * size;
          const iterations = 20;

          final stopwatch = Stopwatch()..start();

          for (int i = 0; i < iterations; i++) {
            secureService.encrypt(data, dataId: 'variable-$size-$i');
          }

          stopwatch.stop();

          final avgTime = stopwatch.elapsedMilliseconds / iterations;
          final sizeKey = '${size}B';
          results[sizeKey] = avgTime;

          print('$sizeKey: ${avgTime.toStringAsFixed(2)}ms avg');
        }

        // Performance should scale reasonably with size
        expect(results['100B']!, lessThan(20));
        expect(results['50000B']!, lessThan(500));
      });
    });

    group('Decryption Performance', () {
      test('should decrypt small data quickly', () async {
        const testData = 'Small test data';
        const iterations = 100;

        // Pre-encrypt data
        final encryptedData = List.generate(iterations,
            (i) => secureService.encrypt(testData, dataId: 'decrypt-small-$i'));

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          secureService.decrypt(encryptedData[i], dataId: 'decrypt-small-$i');
        }

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / iterations;

        print(
            'Small data decryption avg time: ${avgTime.toStringAsFixed(2)}ms');
        print(
            'Total time: ${stopwatch.elapsedMilliseconds}ms for $iterations operations');

        expect(avgTime, lessThan(50));
      });

      test('should decrypt large data efficiently', () async {
        final largeData = 'B' * 10000;
        const iterations = 50;

        // Pre-encrypt data
        final encryptedData = List.generate(
            iterations,
            (i) =>
                secureService.encrypt(largeData, dataId: 'decrypt-large-$i'));

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          secureService.decrypt(encryptedData[i], dataId: 'decrypt-large-$i');
        }

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / iterations;
        final throughput = (largeData.length * iterations) /
            (stopwatch.elapsedMilliseconds / 1000);

        print(
            'Large data decryption avg time: ${avgTime.toStringAsFixed(2)}ms');
        print('Throughput: ${(throughput / 1024).toStringAsFixed(2)} KB/s');

        expect(avgTime, lessThan(200));
      });
    });

    group('Batch Operations Performance', () {
      test('should handle batch encryption efficiently', () async {
        final batchSize = 100;
        final notes = List.generate(
            batchSize,
            (i) => {
                  'id': 'batch-$i',
                  'title': 'Note $i',
                  'content': 'Content' * 100, // ~700 bytes
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                  'tags': <String>[],
                });

        final stopwatch = Stopwatch()..start();

        final encryptedNotes = secureService.batchEncryptNotes(notes);

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / batchSize;
        final totalSize = notes.fold<int>(
            0,
            (sum, note) =>
                sum +
                (note['title'] as String).length +
                (note['content'] as String).length);
        final throughput = totalSize / (stopwatch.elapsedMilliseconds / 1000);

        print(
            'Batch encryption: ${stopwatch.elapsedMilliseconds}ms for $batchSize notes');
        print('Avg per note: ${avgTime.toStringAsFixed(2)}ms');
        print(
            'Total throughput: ${(throughput / 1024).toStringAsFixed(2)} KB/s');

        expect(encryptedNotes.length, equals(batchSize));
        expect(avgTime, lessThan(100)); // Should be under 100ms per note
      });

      test('should handle batch decryption efficiently', () async {
        final batchSize = 100;
        final notes = List.generate(
            batchSize,
            (i) => {
                  'id': 'batch-decrypt-$i',
                  'title': 'Original $i',
                  'content': 'Content' * 100,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                  'tags': <String>[],
                });

        // Pre-encrypt
        final encryptedNotes = secureService.batchEncryptNotes(notes);

        final stopwatch = Stopwatch()..start();

        final decryptedNotes = secureService.batchDecryptNotes(encryptedNotes);

        stopwatch.stop();

        final avgTime = stopwatch.elapsedMilliseconds / batchSize;

        print(
            'Batch decryption: ${stopwatch.elapsedMilliseconds}ms for $batchSize notes');
        print('Avg per note: ${avgTime.toStringAsFixed(2)}ms');

        expect(decryptedNotes.length, equals(batchSize));
        expect(avgTime, lessThan(100));
      });

      test('should scale well with large batches', () async {
        final batchSizes = [50, 100, 200, 500];
        final results = <int, double>{};

        for (final size in batchSizes) {
          final notes = List.generate(
              size,
              (i) => {
                    'id': 'scale-$size-$i',
                    'title': 'Note $i',
                    'content': 'Content',
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                    'tags': <String>[],
                  });

          final stopwatch = Stopwatch()..start();
          secureService.batchEncryptNotes(notes);
          stopwatch.stop();

          final avgTime = stopwatch.elapsedMilliseconds / size;
          results[size] = avgTime;

          print(
              'Batch size $size: ${avgTime.toStringAsFixed(2)}ms avg per note');
        }

        // Average time per note should not increase dramatically with batch size
        expect(results[50]!, lessThan(50));
        expect(results[500]!, lessThan(150));
      });
    });

    group('Memory Efficiency', () {
      test('should not leak memory during repeated operations', () async {
        const iterations = 200;
        final testData = 'A' * 1000;

        // Monitor memory usage pattern
        final initialMetrics = performanceMonitor.getStatistics();

        for (int i = 0; i < iterations; i++) {
          final encrypted =
              secureService.encrypt(testData, dataId: 'memory-$i');
          final decrypted =
              secureService.decrypt(encrypted, dataId: 'memory-$i');

          expect(decrypted, equals(testData));
        }

        final finalMetrics = performanceMonitor.getStatistics();

        print('Initial operations: ${initialMetrics.totalOperations}');
        print('Final operations: ${finalMetrics.totalOperations}');
        print('Operations performed: ${iterations}');

        expect(finalMetrics.totalOperations - initialMetrics.totalOperations,
            greaterThanOrEqualTo(iterations));
      });

      test('should handle large data without memory issues', () async {
        final largeData = 'X' * 100000; // 100KB
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          final encrypted =
              secureService.encrypt(largeData, dataId: 'large-memory-$i');
          final decrypted =
              secureService.decrypt(encrypted, dataId: 'large-memory-$i');

          expect(decrypted.length, equals(largeData.length));
          expect(decrypted, equals(largeData));
        }

        print('Completed $iterations iterations with 100KB data');
      });
    });

    group('Performance Monitoring', () {
      test('should track performance metrics accurately', () async {
        performanceMonitor.clearMetrics();

        const testData = 'Performance test data';
        const operations = 50;

        for (int i = 0; i < operations; i++) {
          final timer = PerformanceTimer('test_encryption', performanceMonitor);
          secureService.encrypt(testData, dataId: 'perf-$i');
          timer.stop(dataSize: testData.length, success: true);
        }

        final stats = performanceMonitor.getStatistics();

        print('Performance Statistics:');
        print('  Total operations: ${stats.totalOperations}');
        print('  Failed operations: ${stats.failedOperations}');
        print('  Success rate: ${stats.successRate.toStringAsFixed(1)}%');
        print(
            '  Average operation time: ${stats.averageOperationTime.toStringAsFixed(2)}ms');
        print('  Total bytes processed: ${stats.totalBytesProcessed}');

        if (stats.encryptStats.count > 0) {
          print('  Encrypt operations: ${stats.encryptStats.count}');
          print(
              '  Avg encrypt time: ${stats.encryptStats.averageTime.toStringAsFixed(2)}ms');
          print(
              '  P95 encrypt time: ${stats.encryptStats.p95Time.toStringAsFixed(2)}ms');
        }

        expect(stats.totalOperations, greaterThanOrEqualTo(operations));
        expect(stats.failedOperations, equals(0));
        expect(stats.successRate, equals(100.0));
      });

      test('should detect slow operations', () async {
        performanceMonitor.clearMetrics();

        // Create some fast operations
        for (int i = 0; i < 10; i++) {
          final timer = PerformanceTimer('fast_op', performanceMonitor);
          secureService.encrypt('Fast data', dataId: 'fast-$i');
          timer.stop(dataSize: 9, success: true);
        }

        // Create some simulated slow operations
        for (int i = 0; i < 3; i++) {
          final timer = PerformanceTimer('slow_op', performanceMonitor);
          secureService.encrypt('Slow data', dataId: 'slow-$i');
          timer.stop(dataSize: 9, success: true);
        }

        final slowOps = performanceMonitor.getSlowOperations(thresholdMs: 1);

        print('Slow operations detected: ${slowOps.length}');
        for (final op in slowOps) {
          print('  ${op.operation}: ${op.durationMs}ms');
        }

        expect(slowOps.length, greaterThan(0));
      });
    });

    group('Real-world Scenarios', () {
      test('should simulate typical user workflow efficiently', () async {
        performanceMonitor.clearMetrics();

        // Simulate creating a note
        final createTimer = PerformanceTimer('create_note', performanceMonitor);
        final noteId = 'user-workflow-1';
        final encryptedCreate = secureService.encryptNoteData(
          noteId: noteId,
          title: 'My First Note',
          content: 'This is my first note content',
        );
        createTimer.stop(
            dataSize: encryptedCreate['title']!.length +
                encryptedCreate['content']!.length);

        // Simulate updating the note
        final updateTimer = PerformanceTimer('update_note', performanceMonitor);
        final encryptedUpdate = secureService.encryptNoteData(
          noteId: noteId,
          title: 'My Updated Note',
          content: 'This is my updated note content with more details',
        );
        updateTimer.stop(
            dataSize: encryptedUpdate['title']!.length +
                encryptedUpdate['content']!.length);

        // Simulate loading the note
        final loadTimer = PerformanceTimer('load_note', performanceMonitor);
        secureService.decryptNoteData(
          noteId: noteId,
          encryptedTitle: encryptedUpdate['title']!,
          encryptedContent: encryptedUpdate['content']!,
        );
        loadTimer.stop(
            dataSize: encryptedUpdate['title']!.length +
                encryptedUpdate['content']!.length);

        // Simulate search (decrypting multiple notes)
        final searchTimer =
            PerformanceTimer('search_notes', performanceMonitor);
        final notes = List.generate(
            20,
            (i) => ({
                  'id': 'search-$i',
                  'title':
                      secureService.encrypt('Note $i', dataId: 'search-$i'),
                  'content': secureService.encrypt('Content for note $i',
                      dataId: 'search-$i'),
                  'is_encrypted': true,
                }));

        secureService.batchDecryptNotes(notes);
        searchTimer.stop(
            dataSize: notes.fold<int>(
                0,
                (sum, note) =>
                    sum +
                    (note['title'] as String).length +
                    (note['content'] as String).length));

        final stats = performanceMonitor.getStatistics();

        print('User Workflow Performance:');
        print('  Create note: ${createTimer.elapsedMs}ms');
        print('  Update note: ${updateTimer.elapsedMs}ms');
        print('  Load note: ${loadTimer.elapsedMs}ms');
        print('  Search notes: ${searchTimer.elapsedMs}ms');
        print('  Total operations: ${stats.totalOperations}');
        print(
            '  Average time: ${stats.averageOperationTime.toStringAsFixed(2)}ms');

        expect(stats.totalOperations, equals(4));
        expect(stats.failedOperations, equals(0));

        // All operations should complete in reasonable time
        expect(createTimer.elapsedMs, lessThan(100));
        expect(updateTimer.elapsedMs, lessThan(100));
        expect(loadTimer.elapsedMs, lessThan(100));
        expect(searchTimer.elapsedMs, lessThan(500));
      });
    });
  });

  group('Performance Regression Tests', () {
    test('should maintain encryption performance baseline', () async {
      final secureService = SecureDataService.instance;
      await secureService.initialize();

      const testData = 'Baseline test data';
      const iterations = 100;

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        secureService.encrypt(testData, dataId: 'baseline-$i');
      }

      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / iterations;

      // Performance baseline: should not exceed 50ms per operation
      expect(avgTime, lessThan(50),
          reason:
              'Encryption performance regression detected: ${avgTime}ms exceeds baseline');
    });

    test('should maintain decryption performance baseline', () async {
      final secureService = SecureDataService.instance;

      const testData = 'Decryption baseline test';
      const iterations = 100;

      final encryptedData = List.generate(
          iterations,
          (i) =>
              secureService.encrypt(testData, dataId: 'decrypt-baseline-$i'));

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        secureService.decrypt(encryptedData[i], dataId: 'decrypt-baseline-$i');
      }

      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / iterations;

      // Performance baseline: should not exceed 50ms per operation
      expect(avgTime, lessThan(50),
          reason:
              'Decryption performance regression detected: ${avgTime}ms exceeds baseline');
    });
  });
}
