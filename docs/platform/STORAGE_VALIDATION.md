# MuseFlow Storage Validation

Captured for v1.4 release hardening on 2026-06-09.

## Storage Model

| Data | Mechanism | Sensitivity | Notes |
| --- | --- | --- | --- |
| API keys and Hive encryption key | `flutter_secure_storage` | Secret | Must use native secure storage only; plaintext fallback is prohibited |
| App settings | Hive CE encrypted box | User settings | Encryption key is stored through `SecureStorageService` |
| Manuscripts, chapters, fragments, knowledge, structure, stats | Hive CE boxes | Local project data | Stored locally; not synced by this app |

## Platform Expectations

| Platform | Hive location expectation | Secret storage expectation | Validation status |
| --- | --- | --- | --- |
| Windows | App data path from Flutter path provider/Hive | Windows Credential Manager | Release workflow built Windows artifact; secure-storage behavior remains tied to native Credential Manager runtime |
| Android | App-private data directory | Android Keystore/encrypted preferences | Local and release workflow APK builds passed; runtime secure-storage behavior remains tied to Android Keystore |
| Linux | XDG/app data path from Flutter path provider/Hive | Secret Service/libsecret | Unit test shell lacks platform plugin; no plaintext fallback is created |
| Web | Not supported in this release | Not validated | No web runner |
| macOS | Not supported in this release | Not validated | No macOS runner |
| iOS | Not supported in this release | Not validated | No iOS runner |

## Security Decision

`SecureStorageService` no longer writes API keys or encryption keys to `~/.local/share/museflow/secrets` or any other plaintext fallback. If a native secure-storage backend is missing, locked, or unavailable, the platform exception is allowed to surface. This is safer than silently storing secrets in files.

## Automated Evidence

```bash
flutter test test/infrastructure/secure_storage_test.dart
```

Result: PASS. The focused run completed 5 tests. In this Linux test shell, secure-storage plugin calls are unavailable and those platform operations use the existing skip path; the regression test confirms the old plaintext Linux fallback directory is not created.

## Linux Runtime Capture Attempt

Command:

```bash
HOME=/tmp/museflow-readme-home XDG_DATA_HOME=/tmp/museflow-readme-home/.local/share ./build/linux/x64/release/bundle/museflow
```

Result: process started, but no visible window was discoverable by `xdotool`; stderr included `libsecret_error: KeyringLocked`. This confirms that a locked or unavailable Secret Service prevents startup paths that need secure storage, rather than falling back to plaintext files. README screenshots were refreshed through the reproducible offline UI evidence flow so production secure-storage behavior stayed strict.

## Manual Runtime Smoke For Future Signed Releases

These checks are recommended before a future signed end-user release, especially on a real Windows desktop and Android device:

1. Save an API key, restart the app, and confirm the provider still reports a saved key.
2. Save window size/position, restart, and confirm geometry restores.
3. Create a manuscript and chapter, restart, and confirm content persists.
4. Clear writing stats and confirm prose/manuscripts remain.
5. Export manuscript data and confirm no API key or Hive encryption key appears in the export.
