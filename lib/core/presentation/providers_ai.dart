part of 'providers.dart';

/// Extracted from providers.dart to satisfy the 03-flutter-standards.md file-size cap.
/// Same library — providers reference each other via bare names unchanged.

/// Whether to run an automatic skill-consistency (deviation) check after each
/// editor AI operation. OFF by default to avoid a hidden second LLM call that
/// silently doubles token cost on every operation (cost-transparency promise).
final autoDeviationCheckProvider =
    NotifierProvider<AutoDeviationCheckNotifier, bool>(
      AutoDeviationCheckNotifier.new,
    );

/// Notifier backing [autoDeviationCheckProvider].
///
/// Reads the persisted preference synchronously from [SettingsRepository]
/// (falls back to `false` while the encrypted box is still loading). Toggling
/// via [set] updates state immediately and persists the new value.
class AutoDeviationCheckNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settings = ref.watch(settingsRepositoryProvider).value;
    return settings?.getAutoDeviationCheck() ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final settings = ref.read(settingsRepositoryProvider).value;
    if (settings != null) {
      await settings.saveAutoDeviationCheck(value);
    }
  }
}

/// User-facing creativity level (AA-03) that governs generation temperature.
///
/// Persists across sessions in [SettingsRepository]. Generation call sites
/// (synthesis + editor AI operations) read this and use its [temperature] to
/// override the provider-configured default, per TempParaphraser (EMNLP 2025):
/// higher sampling diversity reduces AI-text detection rate. Defaults to
/// [CreativityLevel.balanced] when the encrypted box is still loading or no
/// preference is persisted yet.
final creativityLevelProvider =
    NotifierProvider<CreativityLevelNotifier, CreativityLevel>(
      CreativityLevelNotifier.new,
    );

/// Notifier backing [creativityLevelProvider].
class CreativityLevelNotifier extends Notifier<CreativityLevel> {
  @override
  CreativityLevel build() {
    final settings = ref.watch(settingsRepositoryProvider).value;
    return settings?.getCreativityLevel() ?? CreativityLevel.balanced;
  }

  Future<void> set(CreativityLevel level) async {
    state = level;
    final settings = ref.read(settingsRepositoryProvider).value;
    if (settings != null) {
      await settings.saveCreativityLevel(level);
    }
  }
}

/// Provides a singleton [AIAdapter] for streaming AI completions.
///
/// Per AI-01: Supports any OpenAI-compatible API via configurable baseUrl.
/// Client caching prevents memory leaks. Typed as [AIAdapter] so tests can
/// override with FakeAdapter.
final openaiAdapterProvider = Provider<AIAdapter>((ref) {
  return OpenAIAdapter(
    // Offline fast-fail: if the device is definitively offline, the adapter
    // surfaces AINetworkException before any network call instead of waiting
    // out the bounded timeout. Best-effort — never blocks when uncertain.
    onlineCheck: () => ref.read(connectivityServiceProvider).isProbablyOffline(),
  );
});

/// Provides a singleton [ClaudeAdapter] for Claude/Anthropic API streaming.
///
/// Uses anthropic_sdk_dart for native Claude Messages API with streaming.
/// Messages are converted from OpenAI format to Anthropic format internally.
final claudeAdapterProvider = Provider<AIAdapter>((ref) {
  return ClaudeAdapter(
    onlineCheck: () => ref.read(connectivityServiceProvider).isProbablyOffline(),
  );
});

/// Routes to the correct AI adapter based on the active provider type.
///
/// - [AiProviderType.claude] → [ClaudeAdapter] (Anthropic Messages API)
/// - All other types (openai, deepseek, ollama, custom) → [OpenAIAdapter]
///   (OpenAI-compatible API)
///
/// This is the single point of dispatch; all callers should use this
/// provider rather than referencing a specific adapter directly.
final activeAdapterProvider = Provider<AIAdapter>((ref) {
  final provider = ref.watch(activeProviderProvider);
  if (provider?.type == AiProviderType.claude) {
    return ref.watch(claudeAdapterProvider);
  }
  return ref.watch(openaiAdapterProvider);
});

/// Provides a [PromptPipeline] with default middleware ordering per AI-04.
///
/// Middleware order: SystemPrompt -> PersonaInjection -> BannedList -> UserContent
final promptPipelineProvider = FutureProvider<PromptPipeline>((ref) async {
  KnowledgeInjectionMiddleware? knowledgeMiddleware;
  SkillEnforcementMiddleware? skillMiddleware;
  try {
    knowledgeMiddleware = await ref.watch(
      knowledgeInjectionMiddlewareProvider.future,
    );
  } catch (_) {
    knowledgeMiddleware = null;
  }
  try {
    skillMiddleware = await ref.watch(
      skillEnforcementMiddlewareProvider.future,
    );
  } catch (_) {
    skillMiddleware = null;
  }
  return PromptPipeline.withDefaultMiddlewares(
    knowledgeInjectionMiddleware: knowledgeMiddleware,
    skillEnforcementMiddleware: skillMiddleware,
  );
});

/// Provides a singleton [AntiAIScentProcessor] for post-processing text per AI-06.
final antiAIScentProcessorProvider = Provider<AntiAIScentProcessor>((ref) {
  return AntiAIScentProcessor();
});

/// Provides a singleton [TokenBudgetCalculator] for budget management per AI-07.
final tokenBudgetCalculatorProvider = Provider<TokenBudgetCalculator>((ref) {
  return TokenBudgetCalculator();
});

/// Provides a [GuardianContextBuilder] for assembling bounded guardian context.
///
/// Uses the default guardian token budget (4000 tokens) and the shared
/// [TokenBudgetCalculator].
final guardianContextBuilderProvider = Provider<GuardianContextBuilder>((ref) {
  return GuardianContextBuilder(
    tokenBudgetCalculator: ref.watch(tokenBudgetCalculatorProvider),
    tokenBudget: 4000,
  );
});

/// Provides an [EditorPromptPipeline] for editor AI operations.
///
/// Per D-16/D-17: Assembles prompts with operation-specific instructions
/// and selected text instead of fragments.
final editorPromptPipelineProvider = FutureProvider<EditorPromptPipeline>((
  ref,
) async {
  KnowledgeInjectionMiddleware? knowledgeMiddleware;
  SkillEnforcementMiddleware? skillMiddleware;
  try {
    knowledgeMiddleware = await ref.watch(
      knowledgeInjectionMiddlewareProvider.future,
    );
  } catch (_) {
    knowledgeMiddleware = null;
  }
  try {
    skillMiddleware = await ref.watch(
      skillEnforcementMiddlewareProvider.future,
    );
  } catch (_) {
    skillMiddleware = null;
  }
  return EditorPromptPipeline(
    knowledgeInjectionMiddleware: knowledgeMiddleware,
    skillEnforcementMiddleware: skillMiddleware,
  );
});

/// Builds adjacent chapter memory context for editor AI prompt calls.
final editorChapterMemoryContextBuilderProvider =
    FutureProvider<EditorChapterMemoryContextBuilder>((ref) async {
      final chapterRepository = await ref.watch(
        chapterRepositoryProvider.future,
      );
      final chapterSummaryRepository = await ref.watch(
        chapterSummaryRepositoryProvider.future,
      );
      return EditorChapterMemoryContextBuilder(
        chapterRepository: chapterRepository,
        chapterSummaryRepository: chapterSummaryRepository,
      );
    });

/// Provides a [ChapterSummarizationService] bound to the active AI provider
/// (MC-02 slice 1 capability, slice 3 wiring). Returns null when no provider
/// is active or no API key is configured — callers MUST null-check.
final chapterSummarizationServiceProvider = Provider<ChapterSummarizationService?>((ref) {
  final provider = ref.watch(activeProviderProvider);
  if (provider == null) return null;
  final apiKey = ref.watch(activeApiKeyProvider);
  if (apiKey == null || apiKey.isEmpty) return null;
  final adapter = ref.watch(activeAdapterProvider);
  return ChapterSummarizationService(
    openAIAdapter: adapter,
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});

/// Provides a [ChapterSummaryRefreshService] for fire-and-forget summary
/// refresh on chapter save (MC-02 slice 3 write side). Returns null when
/// the summarization service (no provider/apiKey) or repository is
/// unavailable — ChapterNotifier.save skips cleanly.
final chapterSummaryRefreshServiceProvider =
    FutureProvider<ChapterSummaryRefreshService?>((ref) async {
  final summarizationService = ref.watch(chapterSummarizationServiceProvider);
  if (summarizationService == null) return null;
  final summaryRepository = await ref.watch(
    chapterSummaryRepositoryProvider.future,
  );
  return ChapterSummaryRefreshService(
    summarizationService: summarizationService,
    summaryRepository: summaryRepository,
  );
});

/// Provides a [DiffCalculator] instance for sentence-level diff computation.
///
/// Stateless utility, but registered as a provider for consistency
/// with the rest of the dependency graph.
final diffCalculatorProvider = Provider<DiffCalculator>((ref) {
  return DiffCalculator();
});

/// Provides a singleton [SelectiveUndoService] for AI undo management.
///
/// Per EDIT-06: Separate AI undo stack from document undo.
/// Ctrl+Z undoes human edits; Ctrl+Shift+Z undoes AI accepts.
final selectiveUndoServiceProvider = Provider<SelectiveUndoService>((ref) {
  return SelectiveUndoService();
});
