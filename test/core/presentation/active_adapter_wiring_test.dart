import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/infrastructure/claude_adapter.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/presentation/provider_management_notifier.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:openai_dart/openai_dart.dart';

import '../../helpers/hive_test_helper.dart';

void main() {
  group('active AI adapter wiring', () {
    test('feature service providers use the active Claude adapter', () async {
      await setUpHiveTest();
      addTearDown(tearDownHiveTest);
      final characterBox = await Hive.openBox<dynamic>(
        'active_adapter_wiring_characters',
      );
      final openAIAdapter = _MarkerAdapter('openai');
      final claudeAdapter = _MarkerAdapter('claude');
      final provider = AIProvider(
        id: 'claude-provider',
        name: 'Claude',
        baseUrl: 'https://api.anthropic.com',
        type: AiProviderType.claude,
        model: 'claude-3-5-haiku-latest',
        createdAt: DateTime(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          activeProviderProvider.overrideWithValue(provider),
          activeApiKeyProvider.overrideWithValue('test-key'),
          openaiAdapterProvider.overrideWithValue(openAIAdapter),
          claudeAdapterProvider.overrideWithValue(claudeAdapter),
          characterCardRepositoryProvider.overrideWith(
            (ref) async => CharacterCardRepository(characterBox),
          ),
        ],
      );
      addTearDown(container.dispose);

      final skillGenerationService = await container.read(
        skillGenerationServiceProvider.future,
      );
      final deviationDetectionService = await container.read(
        deviationDetectionServiceProvider.future,
      );
      final editorialReviewService = await container.read(
        editorialReviewServiceProvider.future,
      );
      final templateCompletionService = await container.read(
        templateCompletionServiceProvider.future,
      );
      final openingGeneratorService = await container.read(
        openingGeneratorServiceProvider.future,
      );
      final chapterSummarizationService = container.read(
        chapterSummarizationServiceProvider,
      );
      final guardianCheckService = await container.read(
        guardianCheckServiceProvider.future,
      );
      final logicGuardianService = await container.read(
        logicGuardianServiceProvider.future,
      );

      expect(container.read(activeAdapterProvider), same(claudeAdapter));
      expect(skillGenerationService.openAIAdapter, same(claudeAdapter));
      expect(deviationDetectionService.openAIAdapter, same(claudeAdapter));
      expect(editorialReviewService.openAIAdapter, same(claudeAdapter));
      expect(templateCompletionService.openAIAdapter, same(claudeAdapter));
      expect(openingGeneratorService.openAIAdapter, same(claudeAdapter));
      expect(chapterSummarizationService, isNotNull);
      expect(chapterSummarizationService!.openAIAdapter, same(claudeAdapter));

      await guardianCheckService.checkCharacterConsistency(text: '空文本');
      await logicGuardianService.checkLogic(
        text: '空文本',
        context: _emptyGuardianContext(),
      );
      expect(openAIAdapter.calls, isZero);
      expect(claudeAdapter.calls, 2);
    });

    test('OpenAI-compatible providers keep using the OpenAI adapter', () {
      final openAIAdapter = _MarkerAdapter('openai');
      final claudeAdapter = _MarkerAdapter('claude');
      final provider = AIProvider(
        id: 'custom-provider',
        name: 'Custom OpenAI-compatible',
        baseUrl: 'https://llm.example.com/v1',
        type: AiProviderType.custom,
        model: 'custom-model',
        createdAt: DateTime(2026, 1, 1),
      );

      final container = ProviderContainer(
        overrides: [
          activeProviderProvider.overrideWithValue(provider),
          activeApiKeyProvider.overrideWithValue('test-key'),
          openaiAdapterProvider.overrideWithValue(openAIAdapter),
          claudeAdapterProvider.overrideWithValue(claudeAdapter),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(activeAdapterProvider), same(openAIAdapter));
      expect(openAIAdapter.calls, isZero);
      expect(claudeAdapter.calls, isZero);
    });

    test(
      'provider setup model discovery uses the dedicated model-list fetcher',
      () async {
        final openAIAdapter = _MarkerAdapter('openai');
        final claudeAdapter = _MarkerAdapter('claude');
        final modelListFetcher = _ModelListFetcher(['glm-4.5', 'glm-4.5-air']);

        final container = ProviderContainer(
          overrides: [
            providerServiceProvider.overrideWith(
              (ref) async => throw StateError('provider service not needed'),
            ),
            openaiAdapterProvider.overrideWithValue(openAIAdapter),
            claudeAdapterProvider.overrideWithValue(claudeAdapter),
            modelListFetcherProvider.overrideWithValue(modelListFetcher),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(providerManagementProvider.notifier);
        await notifier.fetchModels(
          apiKey: 'model-list-key',
          baseUrl: 'https://llm.example.com/v1',
        );

        final state = container.read(providerManagementProvider);
        expect(state.availableModels, ['glm-4.5', 'glm-4.5-air']);
        expect(state.isFetchingModels, isFalse);
        expect(modelListFetcher.calls, 1);
        expect(modelListFetcher.lastApiKey, 'model-list-key');
        expect(modelListFetcher.lastBaseUrl, 'https://llm.example.com/v1');
        expect(openAIAdapter.calls, isZero);
        expect(claudeAdapter.calls, isZero);
      },
    );

    test('adapter providers dispose cached clients with the container', () {
      final container = ProviderContainer();

      final openAIAdapter =
          container.read(openaiAdapterProvider) as OpenAIAdapter;
      final modelListFetcher = container.read(modelListFetcherProvider);
      final claudeAdapter =
          container.read(claudeAdapterProvider) as ClaudeAdapter;

      openAIAdapter.createStream(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434/v1',
        model: 'test-model',
        messages: [ChatMessage.user('hi')],
      );
      modelListFetcher.createStream(
        apiKey: 'test-key',
        baseUrl: 'http://localhost:11434/v1',
        model: 'test-model',
        messages: [ChatMessage.user('hi')],
      );
      claudeAdapter.createStream(
        apiKey: 'test-key',
        baseUrl: 'https://api.anthropic.com',
        model: 'claude-3-5-haiku-latest',
        messages: [ChatMessage.user('hi')],
      );

      expect(openAIAdapter.isActive, isTrue);
      expect(modelListFetcher.isActive, isTrue);
      expect(claudeAdapter.isActive, isTrue);

      container.dispose();

      expect(openAIAdapter.isActive, isFalse);
      expect(modelListFetcher.isActive, isFalse);
      expect(claudeAdapter.isActive, isFalse);
    });
  });
}

GuardianContextBundle _emptyGuardianContext() {
  return const GuardianContextBundle(
    manuscriptExcerpt: '空文本',
    relevantCharacters: [],
    relevantWorldSettings: [],
    skillConstraints: [],
    plotSummaries: [],
    unresolvedForeshadowing: [],
    omittedCharacterCount: 0,
    omittedWorldSettingCount: 0,
    omittedSkillCount: 0,
    omittedPlotNodeCount: 0,
    omittedForeshadowingCount: 0,
    totalTokensUsed: 0,
    tokenBudget: 4000,
  );
}

class _MarkerAdapter implements AIAdapter {
  _MarkerAdapter(this.name);

  final String name;
  int calls = 0;

  @override
  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) async* {
    calls += 1;
    yield name;
  }
}

class _ModelListFetcher extends OpenAIAdapter {
  _ModelListFetcher(this.models);

  final List<String> models;
  int calls = 0;
  String? lastApiKey;
  String? lastBaseUrl;

  @override
  Future<List<String>> fetchModelList({
    required String apiKey,
    required String baseUrl,
  }) async {
    calls += 1;
    lastApiKey = apiKey;
    lastBaseUrl = baseUrl;
    return models;
  }
}
