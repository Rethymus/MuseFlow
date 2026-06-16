// Tests for [DialogueActMiddleware] — CI-01 PATHs response-strategy wiring.
//
// Closes the loop opened by 260614-ci1 (pure-logic DialogueActClassifier with
// zero consumers): the middleware classifies the user's free-text refine
// instruction and injects an act-specific Chinese response-strategy system
// message, or stays a no-op when there is nothing actionable.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/dialogue_act_middleware.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';

/// Returns the middleware's effect on a fresh context with the given
/// instruction — since this middleware is the only message source in a fresh
/// context, [result.messages] reflects exactly what it injected.
PromptContext _apply(String? instruction) {
  return const DialogueActMiddleware().apply(
    PromptContext(fragments: const [], additionalInstruction: instruction),
  );
}

/// Joins the text of every system message the middleware produced.
String _systemText(PromptContext context) {
  return context.messages
      .where((m) => m.toJson()['role'] == 'system')
      .map((m) => m.toJson()['content'] as String)
      .join('\n');
}

void main() {
  group('DialogueActMiddleware no-op cases', () {
    test('should be no-op when additionalInstruction is null', () {
      final result = _apply(null);
      expect(result.messages, isEmpty);
    });

    test('should be no-op when additionalInstruction is empty', () {
      final result = _apply('');
      expect(result.messages, isEmpty);
    });

    test('should be no-op when additionalInstruction is whitespace-only', () {
      final result = _apply('   \n\t  ');
      expect(result.messages, isEmpty);
    });

    test('should be no-op for ambiguous message with no signal', () {
      // "好的" matches no signal phrase → confidence 0 → no-op (avoids noise
      // on every generic refine; depth is the safe default).
      final result = _apply('好的');
      expect(result.messages, isEmpty);
    });

    test('should be no-op for followUp with signal (depth is the default)', () {
      // "为什么这么写" matches a followUp signal, but followUp has no entry in
      // _strategies — providing more depth is the non-destructive default and
      // injecting a strategy for every follow-up would add noise.
      final result = _apply('为什么这么写');
      expect(result.messages, isEmpty);
    });
  });

  group('DialogueActMiddleware strategy injection', () {
    test('should inject style-adjustment strategy for style request', () {
      final result = _apply('改成口语风格');
      final text = _systemText(result);
      expect(text, contains('响应策略·风格调整'));
      expect(text, contains('风格偏好'));
      expect(result.messages.length, 1);
    });

    test(
      'should inject content-exploration strategy for branching request',
      () {
        final result = _apply('如果换一种方向会怎样');
        final text = _systemText(result);
        expect(text, contains('响应策略·内容探索'));
        expect(text, contains('分支方向'));
      },
    );

    test('should inject intent-revision strategy for correction', () {
      final result = _apply('不对，我要的是紧张感');
      final text = _systemText(result);
      expect(text, contains('响应策略·意图修订'));
      expect(text, contains('真实意图'));
    });

    test('should inject injection strategy for insert request', () {
      final result = _apply('加一段对话');
      final text = _systemText(result);
      expect(text, contains('响应策略·内容注入'));
      expect(text, contains('忠实融入'));
    });
  });

  group('DialogueActMiddleware pipeline integration', () {
    test('withDefaultMiddlewares injects strategy for style refine', () {
      final messages = PromptPipeline.withDefaultMiddlewares().build(
        const PromptContext(fragments: [], additionalInstruction: '改成口语风格'),
      );
      final hasStrategy = messages.any(
        (m) =>
            m.toJson()['role'] == 'system' &&
            (m.toJson()['content'] as String).contains('响应策略·风格调整'),
      );
      expect(hasStrategy, isTrue);
    });

    test('withDefaultMiddlewares stays clean when no instruction given', () {
      final messages = PromptPipeline.withDefaultMiddlewares().build(
        const PromptContext(fragments: []),
      );
      final hasStrategy = messages.any(
        (m) =>
            m.toJson()['role'] == 'system' &&
            (m.toJson()['content'] as String).contains('响应策略'),
      );
      // First synthesis (no refine instruction) must not get a strategy tag.
      expect(hasStrategy, isFalse);
    });
  });
}
