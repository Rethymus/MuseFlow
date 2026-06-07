import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('journey_test_');
  Hive.init(tempDir.path);

  // Open 15 Hive boxes required by knowledge/stats/story features.
  // Per D-01: all boxes needed for full feature operation.
  await Hive.openBox<dynamic>('manuscripts');
  await Hive.openBox<dynamic>('chapters');
  await Hive.openBox<dynamic>('token_audit');
  await Hive.openBox<dynamic>('ai_providers');
  await Hive.openBox<dynamic>('fragments');
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
