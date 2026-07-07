# Secret Storage Boundary

This document records the privacy boundary enforced by the current MuseFlow
storage code. It is intentionally narrower than the full storage architecture:
the goal is to make secret-handling regressions easy to spot during reviews.

## Secrets

These values must only be stored through `SecureStorageService`, which delegates
to `flutter_secure_storage` and the platform native backend:

| Value | Storage key owner | Source files |
| --- | --- | --- |
| AI provider API keys | Provider ID, prefixed by `api_key_` inside `SecureStorageService` | `lib/features/ai/application/provider_service.dart`, `lib/features/ai/infrastructure/provider_repository.dart`, `lib/core/infrastructure/secure_storage_service.dart` |
| Hive settings encryption key | `hive_encryption_key`, passed through `SecureStorageService` | `lib/core/presentation/providers_core.dart`, `lib/main.dart` |

Plaintext fallback files are not allowed for these values. If the platform
secure-storage backend is missing, locked, or unavailable, the caller should
surface or preserve that failure instead of silently writing secrets elsewhere.

## Non-Secret Provider Metadata

The `ai_providers` Hive box may store provider configuration such as name,
provider type, base URL, model, active state, and model parameters. It must not
store API key material or alternate key aliases such as `apiKey` or `key`.

The focused regression coverage for this boundary is:

```bash
flutter test test/features/ai/application/provider_service_test.dart
```

The provider-service test suite includes a Hive serialization check that creates
and rotates an API key, then asserts the raw provider Hive record contains no API
key fields or key values.

## Encrypted Settings Box

The `settings` Hive box is opened with `HiveAesCipher` using the encryption key
stored in secure storage. The box contains user preferences and window geometry,
not API provider keys.

Window geometry is read before `runApp` in `lib/main.dart`. If the encryption key
or box cannot be read at that point, startup falls back to default geometry; this
does not create or relocate any secret. The settings provider later opens the
same encrypted box through `settingsRepositoryProvider`.

## Verification

Use these focused checks when changing storage, provider management, platform
startup, exports, or test fixtures that touch API keys:

```bash
scripts/check_storage_architecture.sh
flutter test test/infrastructure/secure_storage_test.dart
flutter test test/features/ai/application/provider_service_test.dart
```

`scripts/check_storage_architecture.sh` is the CI guard for this document and
the source-level storage boundary. It checks the documented Hive box list,
TypeAdapter count, secure-storage key owners, and prevents
`SecureStorageService` from reintroducing plaintext or Hive fallback storage.

`test/infrastructure/secure_storage_test.dart` verifies there is no plaintext
Linux fallback directory. `test/features/ai/application/provider_service_test.dart`
verifies provider CRUD keeps API keys out of the provider Hive box.
