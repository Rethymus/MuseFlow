part of 'providers.dart';

/// Extracted from providers.dart to satisfy the 03-flutter-standards.md file-size cap.
/// Same library — providers reference each other via bare names unchanged.

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
    openAIAdapter: ref.watch(activeAdapterProvider),
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
        openAIAdapter: ref.watch(activeAdapterProvider),
        apiKey: apiKey,
        baseUrl: provider.baseUrl,
        model: provider.model,
      );
    });

/// Provides an [EditorialReviewService] for the 4-dimension LLM editorial
/// review panel. Throws if no AI provider/key is configured.
final editorialReviewServiceProvider = FutureProvider<EditorialReviewService>((
  ref,
) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  return EditorialReviewService(
    openAIAdapter: ref.watch(activeAdapterProvider),
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});

final deviationNotifierProvider =
    AsyncNotifierProvider<DeviationNotifier, DeviationResult>(
      DeviationNotifier.new,
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
final characterRelationshipNotifierProvider =
    AsyncNotifierProvider<
      CharacterRelationshipNotifier,
      List<CharacterRelationship>
    >(CharacterRelationshipNotifier.new);
