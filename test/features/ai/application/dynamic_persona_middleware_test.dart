/// Tests for [DynamicPersonaMiddleware] lexical-signature injection.
///
/// Validates that the author's characteristic n-grams are injected into the
/// generation prompt with "自然融入" (naturally blend) phrasing, that the
/// anti-AI-scent anchor is preserved, that an empty signature is not injected,
/// and that a null style profile passes through unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/dynamic_persona_middleware.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/editor/domain/lexical_signature.dart';
import 'package:openai_dart/openai_dart.dart';

AuthorStyleProfile _profileWithSignature(List<String> terms) {
  return AuthorStyleProfile(
    manuscriptId: 'ms',
    analyzedChapterCount: 2,
    analyzedCharCount: 800,
    lexicalSignature: LexicalSignature(
      topTerms: terms
          .map((t) => LexicalTerm(term: t, score: 5.0, frequency: 3))
          .toList(),
    ),
  );
}

String _systemContent(PromptContext context) {
  final systemIndex = context.messages.indexWhere(
    (m) => m.toJson()['role'] == 'system',
  );
  final content = context.messages[systemIndex].toJson()['content'];
  return content is String ? content : '';
}

void main() {
  const middleware = DynamicPersonaMiddleware();

  PromptContext baseContext(AuthorStyleProfile? profile) {
    return PromptContext(
      fragments: [Fragment(id: 'f1', text: '碎片', createdAt: DateTime.now())],
      messages: [ChatMessage.system('你是一个写作助手。')],
      styleProfile: profile,
    );
  }

  group('DynamicPersonaMiddleware lexical-signature injection', () {
    test('injects top characteristic terms into system message', () {
      final profile = _profileWithSignature(const ['剑意', '凌厉']);
      final result = middleware.apply(baseContext(profile));
      final content = _systemContent(result);
      expect(content, contains('剑意'));
      expect(content, contains('凌厉'));
    });

    test('uses "自然融入" guidance phrasing (anti keyword stuffing)', () {
      final profile = _profileWithSignature(const ['剑意']);
      final result = middleware.apply(baseContext(profile));
      final content = _systemContent(result);
      expect(content, contains('自然融入'));
    });

    test('preserves anti-AI-scent anchor ("核心要求" / "AI生成的痕迹")', () {
      final profile = _profileWithSignature(const ['剑意']);
      final result = middleware.apply(baseContext(profile));
      final content = _systemContent(result);
      expect(content, contains('核心要求'));
      expect(content, contains('AI生成的痕迹'));
    });

    test('does not inject terms section when signature is empty', () {
      final profile = AuthorStyleProfile(
        manuscriptId: 'ms',
        analyzedChapterCount: 2,
        analyzedCharCount: 800,
        lexicalSignature: LexicalSignature.empty,
      );
      final result = middleware.apply(baseContext(profile));
      final content = _systemContent(result);
      expect(content, isNot(contains('作者常用表达')));
      // Other dimension guidance and the anti-AI-scent anchor remain.
      expect(content, contains('核心要求'));
    });

    test('null styleProfile passes context through unchanged', () {
      final context = baseContext(null);
      final result = middleware.apply(context);
      // Messages list is identical (same length, same content) when no profile.
      expect(result.messages.length, context.messages.length);
      expect(_systemContent(result), _systemContent(context));
    });
  });
}
