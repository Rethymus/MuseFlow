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
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';
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
final promptPipelineProvider = Provider<PromptPipeline>((ref) {
  return PromptPipeline.withDefaultMiddlewares();
});

/// Provides a singleton [AntiAIScentProcessor] for post-processing text per AI-06.
final antiAIScentProcessorProvider = Provider<AntiAIScentProcessor>((ref) {
  return AntiAIScentProcessor();
});

/// Provides a singleton [TokenBudgetCalculator] for budget management per AI-07.
final tokenBudgetCalculatorProvider = Provider<TokenBudgetCalculator>((ref) {
  return TokenBudgetCalculator();
});

/// Provides an [EditorPromptPipeline] for editor AI operations.
///
/// Per D-16/D-17: Assembles prompts with operation-specific instructions
/// and selected text instead of fragments.
final editorPromptPipelineProvider = Provider<EditorPromptPipeline>((ref) {
  return EditorPromptPipeline();
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
