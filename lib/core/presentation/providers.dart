import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/infrastructure/fragment_repository.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/knowledge/application/name_index_service.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:museflow/features/knowledge/application/skill_generation_service.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/application/guardian_check_service.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/application/logic_guardian_service.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/guardian_annotation_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';
export 'package:museflow/features/editor/application/context_anchor_notifier.dart'
    show contextAnchorNotifierProvider, ContextAnchorNotifier;
export 'package:museflow/features/editor/presentation/editor_page.dart'
    show editorProvider;
export 'package:museflow/features/editor/application/editor_ai_notifier.dart'
    show editorAINotifierProvider, EditorAINotifier;

/// Provides a [FragmentRepository] backed by a Hive 'fragments' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final fragmentRepositoryProvider =
    FutureProvider<FragmentRepository>((ref) async {
  final box = await Hive.openBox<Fragment>('fragments');
  return FragmentRepository(box);
});

/// Provides a [SettingsRepository] backed by an encrypted Hive 'settings' box.
///
/// Uses AES encryption with a key stored in flutter_secure_storage.
/// Falls back to generating a new key if none exists.
final settingsRepositoryProvider =
    FutureProvider<SettingsRepository>((ref) async {
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

/// Provides a singleton [SecureStorageService] instance.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provides a [ProviderRepository] backed by a Hive 'ai_providers' box.
///
/// Opens the box without encryption (API keys go to SecureStorage).
final providerRepositoryProvider =
    FutureProvider<ProviderRepository>((ref) async {
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

/// Provides a singleton [OpenAIAdapter] for streaming AI completions.
///
/// Per AI-01: Supports any OpenAI-compatible API via configurable baseUrl.
/// Client caching prevents memory leaks.
final openaiAdapterProvider = Provider<OpenAIAdapter>((ref) {
  return OpenAIAdapter();
});

/// Provides a [PromptPipeline] with default middleware ordering per AI-04.
///
/// Middleware order: SystemPrompt -> PersonaInjection -> BannedList -> UserContent
final promptPipelineProvider = FutureProvider<PromptPipeline>((ref) async {
  KnowledgeInjectionMiddleware? knowledgeMiddleware;
  SkillEnforcementMiddleware? skillMiddleware;
  try {
    knowledgeMiddleware = await ref.watch(knowledgeInjectionMiddlewareProvider.future);
  } catch (_) {
    knowledgeMiddleware = null;
  }
  try {
    skillMiddleware = await ref.watch(skillEnforcementMiddlewareProvider.future);
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
final editorPromptPipelineProvider = FutureProvider<EditorPromptPipeline>((ref) async {
  KnowledgeInjectionMiddleware? knowledgeMiddleware;
  SkillEnforcementMiddleware? skillMiddleware;
  try {
    knowledgeMiddleware = await ref.watch(knowledgeInjectionMiddlewareProvider.future);
  } catch (_) {
    knowledgeMiddleware = null;
  }
  try {
    skillMiddleware = await ref.watch(skillEnforcementMiddlewareProvider.future);
  } catch (_) {
    skillMiddleware = null;
  }
  return EditorPromptPipeline(
    knowledgeInjectionMiddleware: knowledgeMiddleware,
    skillEnforcementMiddleware: skillMiddleware,
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
final characterCardRepositoryProvider =
    FutureProvider<CharacterCardRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('character_cards');
  return CharacterCardRepository(box);
});

/// Provides a [WorldSettingRepository] backed by a Hive 'world_settings' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final worldSettingRepositoryProvider =
    FutureProvider<WorldSettingRepository>((ref) async {
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

final nameIndexServiceProvider =
    NotifierProvider<NameIndexService, NameIndex>(NameIndexService.new);

final knowledgeInjectionMiddlewareProvider =
    FutureProvider<KnowledgeInjectionMiddleware>((ref) async {
  final nameIndex = ref.watch(nameIndexServiceProvider);
  final characterRepository = await ref.watch(characterCardRepositoryProvider.future);
  final worldSettingRepository = await ref.watch(worldSettingRepositoryProvider.future);
  final tokenBudgetCalculator = ref.watch(tokenBudgetCalculatorProvider);
  return KnowledgeInjectionMiddleware(
    nameIndex: nameIndex,
    characterRepository: characterRepository,
    worldSettingRepository: worldSettingRepository,
    tokenBudgetCalculator: tokenBudgetCalculator,
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

final skillGenerationServiceProvider = FutureProvider<SkillGenerationService>((ref) async {
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

/// Provides a [ForeshadowingRepository] backed by a Hive 'foreshadowing_entries' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final foreshadowingRepositoryProvider =
    FutureProvider<ForeshadowingRepository>((ref) async {
  final box = await Hive.openBox<dynamic>('foreshadowing_entries');
  return ForeshadowingRepository(box);
});

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

/// Provides a [PlotNodeRepository] backed by a Hive 'plot_nodes' box.
///
/// Opens the box asynchronously, so consumers must await this provider.
final plotNodeRepositoryProvider =
    FutureProvider<PlotNodeRepository>((ref) async {
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
final guardianCheckServiceProvider =
    FutureProvider<GuardianCheckService>((ref) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  final characterRepository =
      await ref.watch(characterCardRepositoryProvider.future);
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
final logicGuardianServiceProvider =
    FutureProvider<LogicGuardianService>((ref) async {
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
