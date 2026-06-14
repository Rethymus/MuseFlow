/// Tests for [ContrastiveSubtractionMiddleware] — CoPA-style contrastive
/// subtraction (AA-02).
///
/// Validates that a decomposed "减去机器味" instruction block (4 CoPA patterns:
/// uniform sentence length, over-perfect logic, mechanical transitions,
/// emotion-driven rhythm with human burstiness) is injected into the system
/// message, that it is **orthogonal** to the banned-phrase list (injects even
/// when bannedPhrases is empty), that it appends to (not replaces) the existing
/// system message, and that it creates a system message when none exists.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:openai_dart/openai_dart.dart';

String _systemContent(PromptContext context) {
  final systemIndex = context.messages.indexWhere(
    (m) => m.toJson()['role'] == 'system',
  );
  if (systemIndex == -1) return '';
  final content = context.messages[systemIndex].toJson()['content'];
  return content is String ? content : '';
}

PromptContext _baseContext({List<String> bannedPhrases = const []}) {
  return PromptContext(
    fragments: [Fragment(id: 'f1', text: '碎片', createdAt: DateTime.now())],
    messages: [ChatMessage.system('你是一个写作助手。')],
    bannedPhrases: bannedPhrases,
  );
}

void main() {
  const middleware = ContrastiveSubtractionMiddleware();

  group('ContrastiveSubtractionMiddleware AA-02 contrastive subtraction', () {
    test('injects a titled "对比减法" instruction block', () {
      final result = middleware.apply(_baseContext());
      expect(_systemContent(result), contains('对比减法'));
    });

    test('pattern 1: addresses uniform sentence length + burstiness', () {
      final result = middleware.apply(_baseContext());
      final content = _systemContent(result);
      expect(content, contains('句长'));
      // Must reference burstiness / 长短句 alternation, not just "vary sentences".
      expect(content, anyOf(contains('长短句'), contains('突发'), contains('不均匀')));
    });

    test('pattern 2: addresses over-perfect logic (允许跳跃留白)', () {
      final result = middleware.apply(_baseContext());
      final content = _systemContent(result);
      expect(content, contains('逻辑'));
      expect(content, anyOf(contains('留白'), contains('跳跃'), contains('非线性')));
    });

    test('pattern 3: enumerates mechanical transition words to avoid', () {
      final result = middleware.apply(_baseContext());
      final content = _systemContent(result);
      // Must name concrete mechanical connectors (然而/此外/综上所述...).
      expect(content, contains('然而'));
      expect(content, anyOf(contains('此外'), contains('综上所述'), contains('不仅')));
    });

    test('pattern 4: addresses emotion-driven rhythm (节奏突变)', () {
      final result = middleware.apply(_baseContext());
      final content = _systemContent(result);
      expect(content, contains('节奏'));
    });

    test('ORTHOGONAL: injects even when bannedPhrases is empty', () {
      // Contrastive subtraction is a different dimension from the keyword
      // blacklist. It must inject regardless of whether any banned phrases
      // are configured — otherwise users with no banned phrases lose the
      // sentence-organization anti-AI-scent layer entirely.
      final result = middleware.apply(_baseContext(bannedPhrases: const []));
      final content = _systemContent(result);
      expect(content, contains('对比减法'));
      expect(content, contains('句长'));
    });

    test(
      'appends to existing system message (preserves base persona text)',
      () {
        final result = middleware.apply(_baseContext());
        final content = _systemContent(result);
        // The original persona text must survive.
        expect(content, contains('你是一个写作助手。'));
        // ...and the subtraction block must be appended after it.
        expect(content.indexOf('你是一个写作助手。'), lessThan(content.indexOf('对比减法')));
      },
    );

    test('creates a system message when none exists', () {
      final ctx = PromptContext(
        fragments: [Fragment(id: 'f1', text: '碎片', createdAt: DateTime.now())],
        messages: const [],
      );
      final result = middleware.apply(ctx);
      expect(result.messages, isNotEmpty);
      expect(result.messages.first.toJson()['role'], 'system');
      expect(_systemContent(result), contains('对比减法'));
    });

    test(
      'does not duplicate injection on repeated apply (idempotent append)',
      () {
        // The middleware may run in pipelines that pre-compose system text;
        // ensure applying twice doesn't duplicate the block (guard against
        // re-entrancy if the same context flows through twice).
        final once = middleware.apply(_baseContext());
        final twice = middleware.apply(once);
        final content = _systemContent(twice);
        expect('对比减法'.allMatches(content).length, lessThanOrEqualTo(1));
      },
    );
  });
}
