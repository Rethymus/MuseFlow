part of 'providers.dart';

/// Extracted from providers.dart to satisfy the 03-flutter-standards.md file-size cap.
/// Same library — providers reference each other via bare names unchanged.

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

/// Provides a [ChapterSummaryRepository] backed by a Hive 'chapter_summaries'
/// box (MC-02 slice 2). Keyed by chapterId (1:1 chapter→summary).
final chapterSummaryRepositoryProvider =
    FutureProvider<ChapterSummaryRepository>((ref) async {
      final box = await Hive.openBox<dynamic>('chapter_summaries');
      return ChapterSummaryRepository(box);
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
