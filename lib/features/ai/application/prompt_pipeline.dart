/// Prompt pipeline middleware system.
///
/// Provides [PromptPipeline], [PromptContext], and [PromptMiddleware] for
/// assembling AI chat messages in a composable, ordered fashion.
///
/// Per AI-04: Pipeline ordering is system prompt → persona injection →
/// banned list → user content. Each middleware transforms the context
/// sequentially, building the final message list.
library;

import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/banned_list_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/persona_injection_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/system_prompt_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/user_content_middleware.dart';
import 'package:openai_dart/openai_dart.dart';

/// Immutable context that flows through the middleware chain.
///
/// Each middleware reads from and appends to this context.
/// The [messages] list accumulates as middlewares run.
class PromptContext {
  /// The fragments to include in the user message.
  final List<Fragment> fragments;

  /// Optional additional instruction from the user.
  final String? additionalInstruction;

  /// Banned phrases to include in the system message negative checklist.
  final List<String> bannedPhrases;

  /// Accumulated chat messages built by middlewares.
  final List<ChatMessage> messages;

  /// Token budget for the request (default 4096).
  final int tokenBudget;

  const PromptContext({
    required this.fragments,
    this.additionalInstruction,
    this.bannedPhrases = const [],
    this.messages = const [],
    this.tokenBudget = 4096,
  });

  /// Creates a copy with an additional message appended.
  PromptContext addMessage(ChatMessage message) {
    return PromptContext(
      fragments: fragments,
      additionalInstruction: additionalInstruction,
      bannedPhrases: bannedPhrases,
      messages: [...messages, message],
      tokenBudget: tokenBudget,
    );
  }

  /// Creates a copy with messages replaced.
  PromptContext withMessages(List<ChatMessage> newMessages) {
    return PromptContext(
      fragments: fragments,
      additionalInstruction: additionalInstruction,
      bannedPhrases: bannedPhrases,
      messages: newMessages,
      tokenBudget: tokenBudget,
    );
  }

  /// Creates a copy replacing the system message at [index] with new content.
  PromptContext replaceSystemMessage(int index, String newContent) {
    final updated = [...messages];
    updated[index] = ChatMessage.system(newContent);
    return PromptContext(
      fragments: fragments,
      additionalInstruction: additionalInstruction,
      bannedPhrases: bannedPhrases,
      messages: updated,
      tokenBudget: tokenBudget,
    );
  }
}

/// Abstract middleware that transforms a [PromptContext].
///
/// Each middleware applies a transformation (e.g., adding a system message,
/// appending persona text, formatting user content) to the context.
/// Middlewares are applied sequentially by [PromptPipeline.build].
abstract class PromptMiddleware {
  /// Allows const subclasses.
  const PromptMiddleware();

  /// Transforms the given [context] and returns an updated context.
  PromptContext apply(PromptContext context);
}

/// Ordered pipeline of middlewares that assembles chat messages.
///
/// Per AI-04: The default ordering is:
/// 1. SystemPromptMiddleware (base system instruction)
/// 2. PersonaInjectionMiddleware (anti-AI-scent persona)
/// 3. BannedListMiddleware (negative checklist)
/// 4. UserContentMiddleware (fragment content)
///
/// Usage:
/// ```dart
/// final pipeline = PromptPipeline.withDefaultMiddlewares();
/// final messages = pipeline.build(context);
/// ```
class PromptPipeline {
  /// The ordered list of middlewares to apply.
  final List<PromptMiddleware> middlewares;

  const PromptPipeline({required this.middlewares});

  /// Creates a pipeline with the default middleware ordering per AI-04.
  factory PromptPipeline.withDefaultMiddlewares() {
    return PromptPipeline(
      middlewares: [
        SystemPromptMiddleware(),
        PersonaInjectionMiddleware(),
        BannedListMiddleware(),
        UserContentMiddleware(),
      ],
    );
  }

  /// Builds the final list of chat messages by applying all middlewares.
  List<ChatMessage> build(PromptContext context) {
    var current = context;
    for (final middleware in middlewares) {
      current = middleware.apply(current);
    }
    return current.messages;
  }
}
