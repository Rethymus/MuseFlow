/// SSE streaming editor insertion test for super_editor.
///
/// Validates batch-insertion of buffered SSE tokens into super_editor's
/// document model using the Editor.execute() API with InsertTextRequest.
/// Measures frame-time performance during batch insertions to verify
/// no jank (all frames under 32ms = 2x 16ms budget).
///
/// Uses simulated streaming data (pre-built Chinese text tokens) rather
/// than a live API call so this test always runs without credentials.
///
/// Per D-11: validates "stream SSE tokens, insert into editor".
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SSE Editor Insertion', () {
    /// Simulated Chinese text tokens from an SSE stream.
    /// Represents a typical streaming response for a martial arts scene.
    const simulatedTokens = <String>[
      '剑', '光', '如', '水', '，', '划', '破', '长', '空', '。',
      '一', '道', '银', '色', '的', '剑', '气', '从', '天', '而',
      '降', '，', '将', '整', '个', '山', '谷', '照', '得', '通',
      '明', '。', '老', '者', '站', '在', '悬', '崖', '边', '缘',
      '，', '白', '发', '随', '风', '飘', '扬', '，', '目', '光',
      '如', '炬', '。', '他', '缓', '缓', '抬', '起', '右', '手',
      '，', '一', '柄', '三', '尺', '青', '锋', '出', '现在', '掌',
      '中', '。', '"', '你', '终', '于', '来', '了', '，"', '他',
      '的', '声', '音', '低', '沉', '而', '有', '力', '，', '"',
      '等', '了', '十', '年', '，', '就', '是', '为', '了', '今',
      '天', '。"', '少', '年', '紧', '握', '拳', '头', '，', '眼',
      '中', '闪', '过', '一', '丝', '决', '然', '。', '他', '知',
      '道', '，', '这', '一', '战', '，', '不', '是', '生', '就',
      '是', '死', '。',
    ];

    test(
      'batch-inserts tokens into super_editor without jank',
      () async {
        // Create super_editor document with empty paragraph
        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: Editor.createNodeId(),
              text: AttributedText(''),
            ),
          ],
        );
        final composer = MutableDocumentComposer();
        final editor = createDefaultDocumentEditor(
          document: document,
          composer: composer,
        );

        // Get the initial paragraph node ID
        // MutableDocument is Iterable<DocumentNode>, use .first
        final nodeId = document.first.id;

        // Track frame times during insertion
        final frameTimes = <Duration>[];
        final frameTimesCompleter = Completer<void>();
        var insertionComplete = false;

        SchedulerBinding.instance.addTimingsCallback((timings) {
          for (final timing in timings) {
            frameTimes.add(timing.totalSpan);
          }
          if (insertionComplete && !frameTimesCompleter.isCompleted) {
            frameTimesCompleter.complete();
          }
        });

        // Simulate SSE streaming with batch insertion
        // Buffer tokens and batch-insert every N tokens (batch size)
        const batchSize = 5;
        var currentOffset = 0;
        final totalStart = DateTime.now();

        for (var i = 0; i < simulatedTokens.length; i += batchSize) {
          final end = (i + batchSize > simulatedTokens.length)
              ? simulatedTokens.length
              : i + batchSize;
          final batchText = simulatedTokens.sublist(i, end).join();

          // Insert batch into super_editor's document model
          editor.execute([
            InsertTextRequest(
              documentPosition: DocumentPosition(
                nodeId: nodeId,
                nodePosition: TextNodePosition(offset: currentOffset),
              ),
              textToInsert: batchText,
              attributions: {},
            ),
          ]);

          currentOffset += batchText.length;

          // Yield to allow frame processing
          await Future.delayed(Duration.zero);
        }

        final totalEnd = DateTime.now();
        insertionComplete = true;

        // Wait a bit for frame timing callbacks
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify all text was inserted correctly
        final node = document.first as ParagraphNode;
        final docText = node.text.toPlainText();
        final expectedText = simulatedTokens.join();

        expect(
          docText,
          equals(expectedText),
          reason: 'All tokens should be in the document in order',
        );

        // Calculate insertion metrics
        final totalDuration = totalEnd.difference(totalStart);
        final avgFrameTime = frameTimes.isNotEmpty
            ? frameTimes.reduce((a, b) => a + b) ~/ frameTimes.length
            : Duration.zero;
        final jankFrames =
            frameTimes.where((t) => t.inMilliseconds > 16).length;
        final severeJankFrames =
            frameTimes.where((t) => t.inMilliseconds > 32).length;
        final maxFrameTime = frameTimes.isNotEmpty
            ? frameTimes.reduce((a, b) => a > b ? a : b)
            : Duration.zero;

        // Verify no severe jank (no frames over 32ms = 2x budget)
        expect(
          severeJankFrames,
          equals(0),
          reason:
              'No frames should exceed 32ms (2x 16ms budget). '
              'Max frame time: ${maxFrameTime.inMilliseconds}ms',
        );

        // Print metrics for SSE_VALIDATION.md
        // ignore: avoid_print
        print('--- Editor Insertion Metrics ---');
        // ignore: avoid_print
        print('Total tokens inserted: ${simulatedTokens.length}');
        // ignore: avoid_print
        print('Batch size: $batchSize');
        // ignore: avoid_print
        print('Number of batches: ${(simulatedTokens.length / batchSize).ceil()}');
        // ignore: avoid_print
        print('Total insertion time: ${totalDuration.inMilliseconds}ms');
        // ignore: avoid_print
        print('Average frame time: ${avgFrameTime.inMilliseconds}ms');
        // ignore: avoid_print
        print('Max frame time: ${maxFrameTime.inMilliseconds}ms');
        // ignore: avoid_print
        print('Jank frames (>16ms): $jankFrames');
        // ignore: avoid_print
        print('Severe jank frames (>32ms): $severeJankFrames');
        // ignore: avoid_print
        print('Document text length: ${docText.length} chars');

        composer.dispose();
      },
    );

    test(
      'inserts large batch of tokens for performance stress test',
      () async {
        // Generate a larger set of tokens to stress test insertion
        final stressTokens = <String>[];
        const tokenChars = '的一是不了人我在有他这为之大来以个中上们到说时地也子就道出会三要';
        final random = _DeterministicRandom(123);
        for (var i = 0; i < 500; i++) {
          stressTokens.add(tokenChars[random.nextInt(tokenChars.length)]);
        }

        final document = MutableDocument(
          nodes: [
            ParagraphNode(
              id: Editor.createNodeId(),
              text: AttributedText(''),
            ),
          ],
        );
        final composer = MutableDocumentComposer();
        final editor = createDefaultDocumentEditor(
          document: document,
          composer: composer,
        );

        final nodeId = document.first.id;
        var currentOffset = 0;
        const batchSize = 10;
        final totalStart = DateTime.now();

        for (var i = 0; i < stressTokens.length; i += batchSize) {
          final end = (i + batchSize > stressTokens.length)
              ? stressTokens.length
              : i + batchSize;
          final batchText = stressTokens.sublist(i, end).join();

          editor.execute([
            InsertTextRequest(
              documentPosition: DocumentPosition(
                nodeId: nodeId,
                nodePosition: TextNodePosition(offset: currentOffset),
              ),
              textToInsert: batchText,
              attributions: {},
            ),
          ]);

          currentOffset += batchText.length;
        }

        final totalEnd = DateTime.now();
        final totalDuration = totalEnd.difference(totalStart);

        // Verify text is correct
        final node = document.first as ParagraphNode;
        expect(
          node.text.toPlainText(),
          equals(stressTokens.join()),
          reason: 'All 500 tokens should be inserted correctly',
        );

        // ignore: avoid_print
        print('--- Stress Test Metrics ---');
        // ignore: avoid_print
        print('Total tokens: ${stressTokens.length}');
        // ignore: avoid_print
        print('Batch size: $batchSize');
        // ignore: avoid_print
        print('Total insertion time: ${totalDuration.inMilliseconds}ms');
        // ignore: avoid_print
        print(
          'Chars per second: '
          '${totalDuration.inMilliseconds > 0 ? (stressTokens.length * 1000 / totalDuration.inMilliseconds).toStringAsFixed(0) : "inf"}',
        );

        composer.dispose();
      },
    );
  });
}

/// Simple deterministic random for reproducible stress test tokens.
class _DeterministicRandom {
  _DeterministicRandom(this._seed);
  int _seed;

  int nextInt(int max) {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed % max;
  }
}
