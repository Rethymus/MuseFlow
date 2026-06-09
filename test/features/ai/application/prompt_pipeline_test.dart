/// Tests for PromptPipeline middleware chain and SynthesisRequest.
///
/// Validates AI-04 (PromptPipeline middleware: system → persona → banned list → user content)
/// and SynthesisRequest value object.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/banned_list_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/persona_injection_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/system_prompt_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/user_content_middleware.dart';
import 'package:museflow/features/ai/domain/synthesis_request.dart';
import 'package:openai_dart/openai_dart.dart';

void main() {
  group('SynthesisRequest', () {
    test('should create with required fragments and defaults', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final request = SynthesisRequest(fragments: fragments);

      expect(request.fragments, equals(fragments));
      expect(request.additionalInstruction, isNull);
      expect(request.maxOutputTokens, equals(2000));
      expect(request.temperature, equals(0.7));
    });

    test('should create with all parameters', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
        Fragment(id: 'f2', text: '碎片2', createdAt: DateTime.now()),
      ];

      final request = SynthesisRequest(
        fragments: fragments,
        additionalInstruction: '注意语气要自然',
        maxOutputTokens: 1000,
        temperature: 0.5,
      );

      expect(request.fragments.length, equals(2));
      expect(request.additionalInstruction, equals('注意语气要自然'));
      expect(request.maxOutputTokens, equals(1000));
      expect(request.temperature, equals(0.5));
    });

    test('should support copyWith', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final request = SynthesisRequest(fragments: fragments);
      final modified = request.copyWith(
        additionalInstruction: '新的指令',
        temperature: 0.9,
      );

      expect(modified.fragments, equals(fragments));
      expect(modified.additionalInstruction, equals('新的指令'));
      expect(modified.temperature, equals(0.9));
      expect(modified.maxOutputTokens, equals(2000));
    });

    test('should be immutable', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final request = SynthesisRequest(fragments: fragments);
      final copy = request.copyWith();

      expect(copy.fragments, equals(request.fragments));
      expect(copy.additionalInstruction, equals(request.additionalInstruction));
    });
  });

  group('PromptContext', () {
    test('should create with fragments and defaults', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final context = PromptContext(fragments: fragments);

      expect(context.fragments, equals(fragments));
      expect(context.additionalInstruction, isNull);
      expect(context.bannedPhrases, isEmpty);
      expect(context.messages, isEmpty);
      expect(context.tokenBudget, equals(4096));
      expect(context.previousChapterMemoryWarning, isNull);
      expect(context.nextChapterMemoryWarning, isNull);
    });

    test('should create with all parameters', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final context = PromptContext(
        fragments: fragments,
        additionalInstruction: '追加指令',
        bannedPhrases: ['然而', '综上所述'],
        tokenBudget: 8000,
        previousChapterMemoryWarning: '上一章摘要可能过期',
        nextChapterMemoryWarning: '下一章摘要可能过期',
      );

      expect(context.additionalInstruction, equals('追加指令'));
      expect(context.bannedPhrases, equals(['然而', '综上所述']));
      expect(context.tokenBudget, equals(8000));
      expect(context.previousChapterMemoryWarning, equals('上一章摘要可能过期'));
      expect(context.nextChapterMemoryWarning, equals('下一章摘要可能过期'));
    });

    test('should support adding messages', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final context = PromptContext(fragments: fragments);
      final updated = context.addMessage(ChatMessage.system('test'));

      expect(updated.messages.length, equals(1));
      // Original should be unchanged (immutability)
      expect(context.messages, isEmpty);
    });

    test('message helpers should preserve chapter memory warnings', () {
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(
        fragments: fragments,
        messages: [ChatMessage.system('old')],
        previousChapterMemoryWarning: '上一章摘要可能过期',
        nextChapterMemoryWarning: '下一章摘要可能过期',
      );

      final added = context.addMessage(ChatMessage.user('content'));
      final replaced = context.replaceSystemMessage(0, 'new');
      final withMessages = context.withMessages([ChatMessage.system('only')]);

      for (final updated in [added, replaced, withMessages]) {
        expect(updated.previousChapterMemoryWarning, '上一章摘要可能过期');
        expect(updated.nextChapterMemoryWarning, '下一章摘要可能过期');
      }
    });
  });

  group('PromptMiddleware', () {
    test('should define apply method that transforms PromptContext', () {
      // Verify the abstract class contract
      final middleware = _TestMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(fragments: fragments);

      final result = middleware.apply(context);
      expect(result.messages.length, equals(1));
    });
  });

  group('SystemPromptMiddleware', () {
    test('should add system message with base instruction', () {
      final middleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(fragments: fragments);

      final result = middleware.apply(context);

      expect(result.messages.length, equals(1));
      // Should be a system message
      expect(result.messages.first.toJson()['role'], equals('system'));
    });

    test('should contain role description in system message', () {
      final middleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(fragments: fragments);

      final result = middleware.apply(context);
      final content = result.messages.first.toJson()['content'] as String;

      expect(content, contains('中文小说作者'));
      expect(content, contains('碎片化的灵感'));
    });
  });

  group('PersonaInjectionMiddleware', () {
    test('should append persona to system message', () {
      final middleware = PersonaInjectionMiddleware();
      final systemMiddleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      var context = systemMiddleware.apply(PromptContext(fragments: fragments));

      context = middleware.apply(context);

      // Should still have only 1 message (appended to system)
      expect(context.messages.length, equals(1));
      final content = context.messages.first.toJson()['content'] as String;
      expect(content, contains('自然'));
      expect(content, contains('像人写的'));
    });

    test('should not crash if no system message exists', () {
      final middleware = PersonaInjectionMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(fragments: fragments);

      // Should handle gracefully (create system message or skip)
      final result = middleware.apply(context);
      expect(result, isNotNull);
    });
  });

  group('BannedListMiddleware', () {
    test('should append banned phrases to system message', () {
      final middleware = BannedListMiddleware();
      final systemMiddleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      var context = systemMiddleware.apply(
        PromptContext(
          fragments: fragments,
          bannedPhrases: ['然而', '综上所述', '值得注意的是'],
        ),
      );

      context = middleware.apply(context);

      expect(context.messages.length, equals(1));
      final content = context.messages.first.toJson()['content'] as String;
      expect(content, contains('避免以下词汇和句式'));
      expect(content, contains('然而'));
      expect(content, contains('综上所述'));
      expect(content, contains('值得注意的是'));
    });

    test('should skip when no banned phrases', () {
      final middleware = BannedListMiddleware();
      final systemMiddleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      var context = systemMiddleware.apply(PromptContext(fragments: fragments));

      final contentBefore =
          context.messages.first.toJson()['content'] as String;
      context = middleware.apply(context);
      final contentAfter = context.messages.first.toJson()['content'] as String;

      // Should not modify content when no banned phrases
      expect(contentAfter, equals(contentBefore));
    });
  });

  group('UserContentMiddleware', () {
    test('should create user message with numbered fragment texts', () {
      final middleware = UserContentMiddleware();
      final systemMiddleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
        Fragment(id: 'f2', text: '碎片2', createdAt: DateTime.now()),
        Fragment(id: 'f3', text: '碎片3', createdAt: DateTime.now()),
      ];
      var context = systemMiddleware.apply(PromptContext(fragments: fragments));

      context = middleware.apply(context);

      // Should now have 2 messages: system + user
      expect(context.messages.length, equals(2));
      final userMsg = context.messages[1];
      expect(userMsg.toJson()['role'], equals('user'));

      final content = userMsg.toJson()['content'] as String;
      expect(content, contains('请将以下灵感碎片整理成'));
      expect(content, contains('1.'));
      expect(content, contains('碎片1'));
      expect(content, contains('2.'));
      expect(content, contains('碎片2'));
      expect(content, contains('3.'));
      expect(content, contains('碎片3'));
    });

    test('should append additionalInstruction when present', () {
      final middleware = UserContentMiddleware();
      final systemMiddleware = SystemPromptMiddleware();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      var context = systemMiddleware.apply(
        PromptContext(fragments: fragments, additionalInstruction: '注意语气要自然'),
      );

      context = middleware.apply(context);

      final userMsg = context.messages[1];
      final content = userMsg.toJson()['content'] as String;
      expect(content, contains('注意语气要自然'));
    });

    test(
      'should not include instruction line when no additionalInstruction',
      () {
        final middleware = UserContentMiddleware();
        final systemMiddleware = SystemPromptMiddleware();
        final fragments = [
          Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
        ];
        var context = systemMiddleware.apply(
          PromptContext(fragments: fragments),
        );

        context = middleware.apply(context);

        final userMsg = context.messages[1];
        final content = userMsg.toJson()['content'] as String;
        expect(content, isNot(contains('追加指令')));
      },
    );
  });

  group('PromptPipeline', () {
    test('should apply middlewares in correct order', () {
      final pipeline = PromptPipeline.withDefaultMiddlewares();
      final fragments = [
        Fragment(id: 'f1', text: '剑光如水', createdAt: DateTime.now()),
        Fragment(id: 'f2', text: '少年拔剑', createdAt: DateTime.now()),
      ];

      final messages = pipeline.build(
        PromptContext(
          fragments: fragments,
          bannedPhrases: ['然而', '综上所述'],
          additionalInstruction: '注意语气',
        ),
      );

      // Should produce exactly 2 messages: system + user
      expect(messages.length, equals(2));

      // First message is system with all prompt-layer content
      expect(messages[0].toJson()['role'], equals('system'));
      final systemContent = messages[0].toJson()['content'] as String;
      expect(systemContent, contains('中文小说作者')); // SystemPrompt
      expect(systemContent, contains('像人写的')); // PersonaInjection
      expect(systemContent, contains('然而')); // BannedList
      expect(systemContent, contains('综上所述')); // BannedList

      // Second message is user with fragment content
      expect(messages[1].toJson()['role'], equals('user'));
      final userContent = messages[1].toJson()['content'] as String;
      expect(userContent, contains('剑光如水'));
      expect(userContent, contains('少年拔剑'));
      expect(userContent, contains('注意语气')); // additionalInstruction
    });

    test('should work without banned phrases', () {
      final pipeline = PromptPipeline.withDefaultMiddlewares();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final messages = pipeline.build(PromptContext(fragments: fragments));

      expect(messages.length, equals(2));
      final systemContent = messages[0].toJson()['content'] as String;
      expect(systemContent, contains('中文小说作者'));
      // Should NOT contain banned list section
      expect(systemContent, isNot(contains('避免以下词汇')));
    });

    test('should work without additionalInstruction', () {
      final pipeline = PromptPipeline.withDefaultMiddlewares();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final messages = pipeline.build(PromptContext(fragments: fragments));

      final userContent = messages[1].toJson()['content'] as String;
      expect(userContent, contains('碎片1'));
      // Should end after fragment list, no instruction line
      expect(userContent.trimRight(), isNot(endsWith('注意')));
    });

    test('should produce consistent output for same input', () {
      final pipeline = PromptPipeline.withDefaultMiddlewares();
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];
      final context = PromptContext(
        fragments: fragments,
        bannedPhrases: ['然而'],
        additionalInstruction: '指令',
      );

      final messages1 = pipeline.build(context);
      final messages2 = pipeline.build(context);

      expect(messages1.length, equals(messages2.length));
      for (var i = 0; i < messages1.length; i++) {
        expect(
          messages1[i].toJson()['content'],
          equals(messages2[i].toJson()['content']),
        );
      }
    });

    test('should support custom middleware order', () {
      final pipeline = PromptPipeline(
        middlewares: [SystemPromptMiddleware(), UserContentMiddleware()],
      );
      final fragments = [
        Fragment(id: 'f1', text: '碎片1', createdAt: DateTime.now()),
      ];

      final messages = pipeline.build(PromptContext(fragments: fragments));

      // Only 2 middlewares: system + user (no persona or banned list)
      expect(messages.length, equals(2));
      final systemContent = messages[0].toJson()['content'] as String;
      // Should NOT contain persona injection
      expect(systemContent, isNot(contains('像人写的')));
    });
  });
}

/// Test middleware that adds a single message.
class _TestMiddleware extends PromptMiddleware {
  @override
  PromptContext apply(PromptContext context) {
    return context.addMessage(ChatMessage.system('test'));
  }
}
