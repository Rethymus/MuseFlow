part of 'providers.dart';

/// Extracted from providers.dart to satisfy the 03-flutter-standards.md file-size cap.
/// Same library — providers reference each other via bare names unchanged.

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

/// Provides a singleton [SecureStorageService] instance.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provides a singleton [ConnectivityService] for offline fast-fail probes.
///
/// Injected into the AI adapter providers so streaming calls fast-fail with
/// [AINetworkException] when the device is definitively offline, instead of
/// waiting out the bounded network timeout. Best-effort (see [ConnectivityService]).
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
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
