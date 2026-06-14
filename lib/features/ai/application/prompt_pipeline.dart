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
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/banned_list_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/contrastive_subtraction_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/dynamic_persona_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/few_shot_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/persona_injection_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/system_prompt_middleware.dart';
import 'package:museflow/features/ai/application/prompt_middlewares/user_content_middleware.dart';
import 'package:museflow/features/editor/domain/editor_ai_state.dart';
import 'package:museflow/features/editor/domain/author_style_profile.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:openai_dart/openai_dart.dart';

/// Abstract interface for context anchors that can be injected into prompts.
///
/// Defined here to avoid circular dependency between the AI and editor layers.
/// Plan 03's ContextAnchor will implement this interface.
abstract class AnchorReference {
  /// The text content of the anchor (e.g., character description, setting).
  String get text;

  /// A human-readable label for the anchor (e.g., "角色卡", "世界观").
  String get label;
}

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

  /// Selected text from the editor for AI operations (null for fragment mode).
  final String? selectedText;

  /// Context anchors injected into the prompt (e.g., character cards, settings).
  final List<AnchorReference>? anchors;

  /// The editor AI operation type (null for non-editor prompts).
  final EditorAIOperation? selectedOperation;

  /// User's custom instruction for free-input operations.
  final String? userInstruction;

  /// Truncated summary of the previous chapter for AI context injection.
  ///
  /// Per D-24: Injected by ChapterContextMiddleware into the system message
  /// so the AI understands surrounding narrative context.
  final String? previousChapterSummary;

  /// Truncated summary of the next chapter for AI context injection.
  final String? nextChapterSummary;

  /// Author-facing warning about the previous chapter summary freshness.
  ///
  /// When present, [ChapterContextMiddleware] tells the model to treat the
  /// adjacent summary as review context instead of authoritative manuscript
  /// truth. This preserves author control when stored chapter memory is stale.
  final String? previousChapterMemoryWarning;

  /// Author-facing warning about the next chapter summary freshness.
  final String? nextChapterMemoryWarning;

  /// Pre-formatted multi-chapter context chain with decreasing detail.
  ///
  /// Per LFIN-01: Up to 3 previous chapter summaries, each with less detail
  /// the further back they are:
  /// - N-1: up to 220 chars (full context)
  /// - N-2: up to 150 chars (reduced context)
  /// - N-3: up to 80 chars (brief mention)
  final String? chapterContextChain;

  /// Author style profile for dynamic persona and few-shot injection.
  ///
  /// When present, [DynamicPersonaMiddleware] replaces the fixed persona
  /// text with style-aware instructions, and [FewShotMiddleware] injects
  /// author paragraph samples.
  final AuthorStyleProfile? styleProfile;

  /// Character gender mapping for pronoun coreference resolution.
  ///
  /// Per Phase 20 (KNOW-01): Maps character names to their gender so
  /// [KnowledgeInjectionMiddleware] can resolve 他/她 pronouns to the
  /// correct character when building knowledge context.
  final Map<String, dynamic> characterGenders;

  /// User-selected creativity level (AA-03) that overrides the provider's
  /// default sampling temperature at the generation call site.
  ///
  /// Null means "honor the provider-configured temperature" (historical
  /// behavior). When set, generation call sites use
  /// [CreativityLevel.temperature] instead of the provider default.
  final CreativityLevel? creativityLevel;

  const PromptContext({
    required this.fragments,
    this.additionalInstruction,
    this.bannedPhrases = const [],
    this.messages = const [],
    this.tokenBudget = 4096,
    this.selectedText,
    this.anchors,
    this.selectedOperation,
    this.userInstruction,
    this.previousChapterSummary,
    this.nextChapterSummary,
    this.previousChapterMemoryWarning,
    this.nextChapterMemoryWarning,
    this.chapterContextChain,
    this.styleProfile,
    this.characterGenders = const {},
    this.creativityLevel,
  });

  /// Creates a copy with an additional message appended.
  PromptContext addMessage(ChatMessage message) {
    return PromptContext(
      fragments: fragments,
      additionalInstruction: additionalInstruction,
      bannedPhrases: bannedPhrases,
      messages: [...messages, message],
      tokenBudget: tokenBudget,
      selectedText: selectedText,
      anchors: anchors,
      selectedOperation: selectedOperation,
      userInstruction: userInstruction,
      previousChapterSummary: previousChapterSummary,
      nextChapterSummary: nextChapterSummary,
      previousChapterMemoryWarning: previousChapterMemoryWarning,
      nextChapterMemoryWarning: nextChapterMemoryWarning,
      chapterContextChain: chapterContextChain,
      styleProfile: styleProfile,
      characterGenders: characterGenders,
      creativityLevel: creativityLevel,
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
      selectedText: selectedText,
      anchors: anchors,
      selectedOperation: selectedOperation,
      userInstruction: userInstruction,
      previousChapterSummary: previousChapterSummary,
      nextChapterSummary: nextChapterSummary,
      previousChapterMemoryWarning: previousChapterMemoryWarning,
      nextChapterMemoryWarning: nextChapterMemoryWarning,
      chapterContextChain: chapterContextChain,
      styleProfile: styleProfile,
      characterGenders: characterGenders,
      creativityLevel: creativityLevel,
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
      selectedText: selectedText,
      anchors: anchors,
      selectedOperation: selectedOperation,
      userInstruction: userInstruction,
      previousChapterSummary: previousChapterSummary,
      nextChapterSummary: nextChapterSummary,
      previousChapterMemoryWarning: previousChapterMemoryWarning,
      nextChapterMemoryWarning: nextChapterMemoryWarning,
      chapterContextChain: chapterContextChain,
      styleProfile: styleProfile,
      characterGenders: characterGenders,
      creativityLevel: creativityLevel,
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
  ///
  /// When a style profile is present in the [PromptContext], the
  /// [DynamicPersonaMiddleware] replaces the fixed persona text with
  /// style-aware instructions, and [FewShotMiddleware] injects author
  /// paragraph samples. Both are no-ops when no profile is available.
  factory PromptPipeline.withDefaultMiddlewares({
    KnowledgeInjectionMiddleware? knowledgeInjectionMiddleware,
    SkillEnforcementMiddleware? skillEnforcementMiddleware,
  }) {
    return PromptPipeline(
      middlewares: [
        SystemPromptMiddleware(),
        PersonaInjectionMiddleware(),
        const DynamicPersonaMiddleware(),
        const FewShotMiddleware(),
        BannedListMiddleware(),
        const ContrastiveSubtractionMiddleware(),
        ?knowledgeInjectionMiddleware,
        ?skillEnforcementMiddleware,
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
