import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/infrastructure/fragment_repository.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/platform/export_file_writer.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/claude_adapter.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_chapter_memory_context_builder.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/application/character_relationship_notifier.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/application/name_index_service.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:museflow/features/knowledge/application/skill_generation_service.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/character_relationship_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/stats/application/writing_stats_collector.dart';
import 'package:museflow/features/stats/application/writing_stats_notifier.dart';
import 'package:museflow/features/stats/application/achievement_notifier.dart';
import 'package:museflow/features/stats/application/achievement_service.dart';
import 'package:museflow/features/stats/application/token_audit_notifier.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/manuscript/application/chapter_auto_save.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_purge_service.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/application/guardian_check_service.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/application/logic_guardian_service.dart';
import 'package:museflow/features/story_structure/application/node_position_notifier.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/guardian_annotation_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/node_position_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';
import 'package:museflow/features/templates/application/template_completion_service.dart';
import 'package:museflow/features/templates/application/template_instantiation_service.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/editor/infrastructure/style_profile_repository.dart';
export 'package:museflow/features/editor/application/context_anchor_notifier.dart'
    show contextAnchorNotifierProvider, ContextAnchorNotifier;
export 'package:museflow/features/editor/presentation/editor_page.dart'
    show editorProvider;
export 'package:museflow/features/editor/application/editor_ai_notifier.dart'
    show editorAINotifierProvider, EditorAINotifier;

/// Provides a [FragmentRepository] backed by a Hive 'fragments' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final fragmentRepositoryProvider = FutureProvider<FragmentRepository>((
  ref,
) async {
  final box = await Hive.openBox<Fragment>('fragments');
  return FragmentRepository(box);
});

/// Provides a [SettingsRepository] backed by an encrypted Hive 'settings' box.
///
/// Uses AES encryption with a key stored in flutter_secure_storage.
/// Falls back to generating a new key if none exists.
final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  const encryptionKeyStoreKey = 'hive_encryption_key';

  final secureStorage = ref.read(secureStorageServiceProvider);
  String? storedKey = await secureStorage.getApiKey(encryptionKeyStoreKey);

  List<int> encryptionKey;
  if (storedKey != null) {
    // Decode the base64-encoded key
    encryptionKey = base64Decode(storedKey);
  } else {
    // Generate a new encryption key and store it as base64
    encryptionKey = Hive.generateSecureKey();
    await secureStorage.saveApiKey(
      encryptionKeyStoreKey,
      base64Encode(encryptionKey),
    );
  }

  final box = await Hive.openBox(
    'settings',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  return SettingsRepository(box);
});

/// Provides an [OnboardingProgressRepository] backed by the same encrypted
/// Hive 'settings' box used by [SettingsRepository].
///
/// Depends on [settingsRepositoryProvider] and accesses the shared box
/// for onboarding progress and completion flag persistence.
final onboardingProgressProvider = FutureProvider<OnboardingProgressRepository>(
  (ref) async {
    final settingsRepo = await ref.watch(settingsRepositoryProvider.future);
    return OnboardingProgressRepository(settingsRepo.box);
  },
);

/// Whether to run an automatic skill-consistency (deviation) check after each
/// editor AI operation. OFF by default to avoid a hidden second LLM call that
/// silently doubles token cost on every operation (cost-transparency promise).
///
/// RED stub: always returns false until the gate is wired (Task 2 GREEN).
final autoDeviationCheckProvider =
    NotifierProvider<AutoDeviationCheckNotifier, bool>(
      AutoDeviationCheckNotifier.new,
    );

/// Notifier backing [autoDeviationCheckProvider].
class AutoDeviationCheckNotifier extends Notifier<bool> {
  @override
  bool build() => false; // RED stub

  Future<void> set(bool value) async {
    state = value;
  }
}

/// Provides a singleton [SecureStorageService] instance.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provides a [ProviderRepository] backed by a Hive 'ai_providers' box.
///
/// Opens the box without encryption (API keys go to SecureStorage).
final providerRepositoryProvider = FutureProvider<ProviderRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('ai_providers');
  final secureStorage = ref.read(secureStorageServiceProvider);
  return ProviderRepository(box, secureStorage);
});

/// Provides a [ProviderService] for AI provider management.
///
/// Depends on [providerRepositoryProvider] and [secureStorageServiceProvider].
final providerServiceProvider = FutureProvider<ProviderService>((ref) async {
  final repository = await ref.watch(providerRepositoryProvider.future);
  final secureStorage = ref.read(secureStorageServiceProvider);
  return ProviderService(repository, secureStorage);
});

final activeProviderProvider = Provider<AIProvider?>((ref) {
  final serviceAsync = ref.watch(providerServiceProvider);
  return serviceAsync.asData?.value.getActiveProvider();
});

final apiKeyFutureProvider = FutureProvider<String?>((ref) async {
  final provider = ref.watch(activeProviderProvider);
  if (provider == null) return null;
  final service = await ref.watch(providerServiceProvider.future);
  return service.getApiKey(provider.id);
});

final activeApiKeyProvider = Provider<String?>((ref) {
  final apiKeyAsync = ref.watch(apiKeyFutureProvider);
  return apiKeyAsync.asData?.value;
});

/// Provides a singleton [AIAdapter] for streaming AI completions.
///
/// Per AI-01: Supports any OpenAI-compatible API via configurable baseUrl.
/// Client caching prevents memory leaks. Typed as [AIAdapter] so tests can
/// override with FakeAdapter.
final openaiAdapterProvider = Provider<AIAdapter>((ref) {
  return OpenAIAdapter();
});

/// Provides a singleton [ClaudeAdapter] for Claude/Anthropic API streaming.
///
/// Uses anthropic_sdk_dart for native Claude Messages API with streaming.
/// Messages are converted from OpenAI format to Anthropic format internally.
final claudeAdapterProvider = Provider<AIAdapter>((ref) {
  return ClaudeAdapter();
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
      return EditorChapterMemoryContextBuilder(
        chapterRepository: chapterRepository,
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

/// Provides a [CharacterCardRepository] backed by a Hive 'character_cards' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final characterCardRepositoryProvider = FutureProvider<CharacterCardRepository>(
  (ref) async {
    final box = await Hive.openBox<dynamic>('character_cards');
    return CharacterCardRepository(box);
  },
);

/// Provides a [WorldSettingRepository] backed by a Hive 'world_settings' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final worldSettingRepositoryProvider = FutureProvider<WorldSettingRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('world_settings');
  return WorldSettingRepository(box);
});

final skillRepositoryProvider = FutureProvider<SkillRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('skill_documents');
  return SkillRepository(box);
});

/// Provides a [CharacterCardNotifier] for character card CRUD operations.
///
/// Presentation layer uses this (not the repository directly) per
/// Clean Architecture compliance.
final characterCardNotifierProvider =
    AsyncNotifierProvider<CharacterCardNotifier, List<CharacterCard>>(
      CharacterCardNotifier.new,
    );

/// Provides a [WorldSettingNotifier] for world setting CRUD operations.
///
/// Presentation layer uses this (not the repository directly) per
/// Clean Architecture compliance.
final worldSettingNotifierProvider =
    AsyncNotifierProvider<WorldSettingNotifier, List<WorldSetting>>(
      WorldSettingNotifier.new,
    );

final nameIndexServiceProvider = NotifierProvider<NameIndexService, NameIndex>(
  NameIndexService.new,
);

final knowledgeInjectionMiddlewareProvider =
    FutureProvider<KnowledgeInjectionMiddleware>((ref) async {
      final nameIndex = ref.watch(nameIndexServiceProvider);
      final characterRepository = await ref.watch(
        characterCardRepositoryProvider.future,
      );
      final worldSettingRepository = await ref.watch(
        worldSettingRepositoryProvider.future,
      );
      final tokenBudgetCalculator = ref.watch(tokenBudgetCalculatorProvider);

      // Phase 21 (KNOW-02): Include relationship repository when available
      CharacterRelationshipRepository? relationshipRepository;
      try {
        relationshipRepository = await ref.watch(
          characterRelationshipRepositoryProvider.future,
        );
      } catch (_) {
        relationshipRepository = null;
      }

      return KnowledgeInjectionMiddleware(
        nameIndex: nameIndex,
        characterRepository: characterRepository,
        worldSettingRepository: worldSettingRepository,
        tokenBudgetCalculator: tokenBudgetCalculator,
        relationshipRepository: relationshipRepository,
      );
    });

final skillEnforcementMiddlewareProvider =
    FutureProvider<SkillEnforcementMiddleware>((ref) async {
      final repository = await ref.watch(skillRepositoryProvider.future);
      return SkillEnforcementMiddleware(
        skillRepository: repository,
        tokenBudgetCalculator: ref.watch(tokenBudgetCalculatorProvider),
      );
    });

final skillGenerationServiceProvider = FutureProvider<SkillGenerationService>((
  ref,
) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  return SkillGenerationService(
    openAIAdapter: ref.watch(openaiAdapterProvider),
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});

final skillGenerationNotifierProvider =
    AsyncNotifierProvider<SkillGenerationNotifier, SkillGenerationState>(
      SkillGenerationNotifier.new,
    );

final skillListNotifierProvider =
    AsyncNotifierProvider<SkillListNotifier, List<SkillDocument>>(
      SkillListNotifier.new,
    );

final deviationDetectionServiceProvider =
    FutureProvider<DeviationDetectionService>((ref) async {
      final provider = ref.watch(activeProviderProvider);
      final apiKey = ref.watch(activeApiKeyProvider);
      if (provider == null || apiKey == null || apiKey.isEmpty) {
        throw StateError('未配置可用的 AI 模型');
      }
      return DeviationDetectionService(
        openAIAdapter: ref.watch(openaiAdapterProvider),
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: provider.model,
      );
    });

final deviationNotifierProvider =
    AsyncNotifierProvider<DeviationNotifier, DeviationResult>(
      DeviationNotifier.new,
    );

final worldTemplateRepositoryProvider = Provider<WorldTemplateRepository>((
  ref,
) {
  return WorldTemplateRepository();
});

final templateInstantiationServiceProvider =
    FutureProvider<TemplateInstantiationService>((ref) async {
      final worldRepository = await ref.watch(
        worldSettingRepositoryProvider.future,
      );
      final characterRepository = await ref.watch(
        characterCardRepositoryProvider.future,
      );
      final chapterRepo = await ref.watch(chapterRepositoryProvider.future);
      return TemplateInstantiationService(
        worldSettingRepository: worldRepository,
        characterCardRepository: characterRepository,
        chapterRepository: chapterRepo,
      );
    });

final templateCompletionServiceProvider =
    FutureProvider<TemplateCompletionService>((ref) async {
      final provider = ref.watch(activeProviderProvider);
      final apiKey = ref.watch(activeApiKeyProvider);
      if (provider == null || apiKey == null || apiKey.isEmpty) {
        throw StateError('未配置可用的 AI 模型');
      }
      return TemplateCompletionService(
        openAIAdapter: ref.watch(openaiAdapterProvider),
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: provider.model,
      );
    });

final openingGeneratorServiceProvider = FutureProvider<OpeningGeneratorService>(
  (ref) async {
    final provider = ref.watch(activeProviderProvider);
    final apiKey = ref.watch(activeApiKeyProvider);
    if (provider == null || apiKey == null || apiKey.isEmpty) {
      throw StateError('未配置可用的 AI 模型');
    }
    return OpeningGeneratorService(
      openAIAdapter: ref.watch(openaiAdapterProvider),
      apiKey: apiKey,
      baseUrl: provider.baseUrl,
      model: provider.model,
    );
  },
);

final writingStatsRepositoryProvider = FutureProvider<WritingStatsRepository>((
  ref,
) async {
  final aggregateBox = await Hive.openBox<dynamic>('writing_stats');
  final dailyBox = await Hive.openBox<dynamic>('daily_writing_stats');
  final badgeBox = await Hive.openBox<dynamic>('achievement_badges');
  return WritingStatsRepository(aggregateBox, dailyBox, badgeBox);
});

final writingStatsCollectorProvider = FutureProvider<WritingStatsCollector>((
  ref,
) async {
  final repository = await ref.watch(writingStatsRepositoryProvider.future);
  final collector = WritingStatsCollector(repository);
  ref.onDispose(collector.dispose);
  return collector;
});

final writingStatsNotifierProvider =
    AsyncNotifierProvider<WritingStatsNotifier, StatsSnapshot>(
      WritingStatsNotifier.new,
    );

// Token Audit Providers
final tokenAuditRepositoryProvider = FutureProvider<TokenAuditRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('token_audit');
  return TokenAuditRepository(box);
});

final tokenAuditServiceProvider = FutureProvider<TokenAuditService>((
  ref,
) async {
  final repository = await ref.watch(tokenAuditRepositoryProvider.future);
  final calculator = TokenBudgetCalculator();
  final service = TokenAuditService(repository, calculator);
  ref.onDispose(service.dispose);
  return service;
});

final tokenAuditNotifierProvider =
    AsyncNotifierProvider<TokenAuditNotifier, TokenAuditSnapshot>(
      TokenAuditNotifier.new,
    );

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return const AchievementService();
});

final achievementNotifierProvider =
    AsyncNotifierProvider<AchievementNotifier, List<AchievementBadge>>(
      AchievementNotifier.new,
    );

/// Provides a [ForeshadowingRepository] backed by a Hive 'foreshadowing_entries' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final foreshadowingRepositoryProvider = FutureProvider<ForeshadowingRepository>(
  (ref) async {
    final box = await Hive.openBox<dynamic>('foreshadowing_entries');
    return ForeshadowingRepository(box);
  },
);

/// Provides a singleton [ForeshadowingReminderService] for deterministic reminder logic.
///
/// Stateless service, registered as a provider for consistency
/// with the rest of the dependency graph.
final foreshadowingReminderServiceProvider =
    Provider<ForeshadowingReminderService>((ref) {
      return ForeshadowingReminderService();
    });

/// Provides a [ForeshadowingNotifier] for foreshadowing entry CRUD operations.
///
/// Presentation layer uses this (not the repository directly) per
/// Clean Architecture compliance.
final foreshadowingNotifierProvider =
    AsyncNotifierProvider<ForeshadowingNotifier, List<ForeshadowingEntry>>(
      ForeshadowingNotifier.new,
    );

/// Provides a [CharacterRelationshipRepository] backed by a Hive
/// 'character_relationships' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final characterRelationshipRepositoryProvider =
    FutureProvider<CharacterRelationshipRepository>((ref) async {
      final box = await Hive.openBox<dynamic>('character_relationships');
      return CharacterRelationshipRepository(box);
    });

/// Provides a [CharacterRelationshipNotifier] for relationship CRUD operations.
///
/// Per Phase 21 (KNOW-02): Presentation layer uses this (not the repository
/// directly) per Clean Architecture compliance.
final characterRelationshipNotifierProvider = AsyncNotifierProvider<
    CharacterRelationshipNotifier, List<CharacterRelationship>>(
  CharacterRelationshipNotifier.new,
);

/// Provides a [PlotNodeRepository] backed by a Hive 'plot_nodes' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final plotNodeRepositoryProvider = FutureProvider<PlotNodeRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('plot_nodes');
  return PlotNodeRepository(box);
});

/// Provides a [PlotNodeNotifier] for plot node CRUD operations.
///
/// Presentation layer uses this (not the repository directly) per
/// Clean Architecture compliance.
final plotNodeNotifierProvider =
    AsyncNotifierProvider<PlotNodeNotifier, List<PlotNode>>(
      PlotNodeNotifier.new,
    );

/// Provides a [NodePositionRepository] backed by a Hive 'graph_positions' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final nodePositionRepositoryProvider = FutureProvider<NodePositionRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('graph_positions');
  return NodePositionRepository(box);
});

/// Provides a [NodePositionNotifier] for graph node position CRUD operations.
final nodePositionNotifierProvider =
    AsyncNotifierProvider<NodePositionNotifier, Map<String, Offset>>(
      NodePositionNotifier.new,
    );

/// Provides a [GuardianAnnotationRepository] backed by a Hive
/// 'guardian_annotations' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final guardianAnnotationRepositoryProvider =
    FutureProvider<GuardianAnnotationRepository>((ref) async {
      final box = await Hive.openBox<dynamic>('guardian_annotations');
      return GuardianAnnotationRepository(box);
    });

/// Provides a [GuardianNotifier] for guardian annotation lifecycle management.
///
/// Presentation layer uses this for check state and annotation dismissal.
final guardianNotifierProvider =
    AsyncNotifierProvider<GuardianNotifier, GuardianCheckResult>(
      GuardianNotifier.new,
    );

/// Provides a [GuardianCheckService] for manual character consistency checks.
///
/// Requires an active AI provider with API key. Throws [StateError] if
/// no provider is configured (UI should check before triggering checks).
final guardianCheckServiceProvider = FutureProvider<GuardianCheckService>((
  ref,
) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  final characterRepository = await ref.watch(
    characterCardRepositoryProvider.future,
  );
  return GuardianCheckService.fromRepository(
    characterRepository: characterRepository,
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});

/// Provides a [LogicGuardianService] for manual logic consistency checks.
///
/// Requires an active AI provider with API key. Throws [StateError] if
/// no provider is configured (UI should check before triggering checks).
final logicGuardianServiceProvider = FutureProvider<LogicGuardianService>((
  ref,
) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  return LogicGuardianService(
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});

/// Provides an [ExportService] for building and writing exported manuscripts.
///
/// Uses dart:io file writer for production. Injected via provider for
/// consistency with the rest of the dependency graph.
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(fileWriter: writeExportFile);
});

// ============================================================================
// Manuscript & Chapter Providers
// ============================================================================

/// Provides a [ManuscriptRepository] backed by a Hive 'manuscripts' box.
final manuscriptRepositoryProvider = FutureProvider<ManuscriptRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('manuscripts');
  return ManuscriptRepository(box);
});

/// Provides a [ChapterRepository] backed by a Hive 'chapters' box.
final chapterRepositoryProvider = FutureProvider<ChapterRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('chapters');
  return ChapterRepository(box);
});

/// Provides a [ManuscriptNotifier] for manuscript CRUD operations.
final manuscriptNotifierProvider =
    AsyncNotifierProvider<ManuscriptNotifier, List<Manuscript>>(
      ManuscriptNotifier.new,
    );

/// Provides a [ChapterNotifier] for chapter CRUD operations.
final chapterNotifierProvider =
    AsyncNotifierProvider<ChapterNotifier, List<Chapter>>(ChapterNotifier.new);

/// Provides a [ChapterAutoSave] service for debounced document persistence.
///
/// Uses a 2-second debounce duration per D-19. Disposes the auto-save
/// service when the provider is disposed.
final chapterAutoSaveProvider = FutureProvider<ChapterAutoSave>((ref) async {
  final repository = await ref.watch(chapterRepositoryProvider.future);
  final autoSave = ChapterAutoSave(repository);
  ref.onDispose(autoSave.dispose);
  return autoSave;
});

/// Provides a [ManuscriptPurgeService] for 30-day soft-delete auto-purge.
///
/// Injects both [ManuscriptRepository] and [ChapterRepository] for
/// cascade deletion (chapters before manuscripts).
final manuscriptPurgeServiceProvider = FutureProvider<ManuscriptPurgeService>((
  ref,
) async {
  final manuscriptRepo = await ref.watch(manuscriptRepositoryProvider.future);
  final chapterRepo = await ref.watch(chapterRepositoryProvider.future);
  return ManuscriptPurgeService(
    manuscriptRepository: manuscriptRepo,
    chapterRepository: chapterRepo,
  );
});

/// Provides a [StyleProfileRepository] for author style profile persistence.
///
/// Uses the 'style_profiles' Hive box.
final styleProfileRepositoryProvider = FutureProvider<StyleProfileRepository>((
  ref,
) async {
  final box = await Hive.openBox<dynamic>('style_profiles');
  return StyleProfileRepository(box);
});
