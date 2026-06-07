import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/infrastructure/hive_adapters.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';

/// Creates a [ProviderContainer] configured for journey integration tests.
///
/// Opens 15 Hive boxes required by knowledge/stats/story features and
/// overrides providers for real GLM API access.
///
/// Per Pitfall 6: Does NOT open 'settings' box (SecureStorage fails in
/// test context).
///
/// Parameters:
/// - [apiKey] GLM API key (required)
/// - [baseUrl] API base URL (defaults to GLM endpoint)
/// - [model] Model name (defaults to glm-4-flash)
Future<ProviderContainer> createJourneyContainer({
  required String apiKey,
  String baseUrl = 'https://open.bigmodel.cn/api/paas/v4',
  String model = 'glm-4-flash',
}) async {
  if (apiKey == 'journey-local-test-key') {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  final tempDir = Directory.systemTemp.createTempSync('journey_test_');
  Hive.init(tempDir.path);
  _registerHiveAdapters();

  // Open Hive boxes required by knowledge/stats/story features.
  // The typed 'fragments' box is intentionally opened by fragmentRepositoryProvider
  // to avoid Hive type conflicts in journey tests.
  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<dynamic>('character_cards');
  await Hive.openBox<dynamic>('world_settings');
  await Hive.openBox<dynamic>('skill_documents');
  await Hive.openBox<dynamic>('writing_stats');
  await Hive.openBox<dynamic>('daily_writing_stats');
  await Hive.openBox<dynamic>('achievement_badges');
  await Hive.openBox<dynamic>('plot_nodes');
  await Hive.openBox<dynamic>('foreshadowing_entries');
  await Hive.openBox<dynamic>('graph_positions');
  await Hive.openBox<dynamic>('guardian_annotations');

  // Per D-02: Real OpenAIAdapter, NOT FakeAdapter
  final glmProvider = AIProvider(
    id: 'glm-journey',
    name: 'GLM',
    baseUrl: baseUrl,
    type: AiProviderType.openai,
    model: model,
    isActive: true,
    createdAt: DateTime.now(),
    temperature: 0.8,
    topP: 0.9,
  );

  return ProviderContainer(
    overrides: [
      openaiAdapterProvider.overrideWithValue(OpenAIAdapter()),
      worldTemplateRepositoryProvider.overrideWithValue(
        WorldTemplateRepository(assetLoader: (_) => File(_templateAssetPath).readAsString()),
      ),
      activeProviderProvider.overrideWithValue(glmProvider),
      activeApiKeyProvider.overrideWithValue(apiKey),
    ],
  );
}

/// Cleans up a journey test container.
///
/// Disposes the container and deletes all Hive boxes from disk.
Future<void> cleanupJourneyContainer(ProviderContainer container) async {
  container.dispose();
  await Hive.deleteFromDisk();
}

const _templateAssetPath = 'assets/templates/world_presets/templates_zh.json';

void _registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(HiveTypeIds.fragment)) {
    Hive.registerAdapter(FragmentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.appSettings)) {
    Hive.registerAdapter(AppSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.characterCard)) {
    Hive.registerAdapter(CharacterCardAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.worldSetting)) {
    Hive.registerAdapter(WorldSettingAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.skillDocument)) {
    Hive.registerAdapter(SkillDocumentAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.foreshadowingEntry)) {
    Hive.registerAdapter(ForeshadowingEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.plotNode)) {
    Hive.registerAdapter(PlotNodeAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.guardianAnnotation)) {
    Hive.registerAdapter(GuardianAnnotationAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.manuscript)) {
    Hive.registerAdapter(ManuscriptAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.chapter)) {
    Hive.registerAdapter(ChapterAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.tokenAuditRecord)) {
    Hive.registerAdapter(TokenAuditRecordAdapter());
  }
}
