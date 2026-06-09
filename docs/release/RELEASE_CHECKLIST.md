# MuseFlow v1.4 Release Checklist

## Current Phase

Phase 1-4 in progress: GitHub metadata and release workflow are drafted locally; local verification gates and Android/Linux build smokes pass; remote CI, Windows artifacts, and GitHub Release verification are still pending.

## Local Verification Results

| Command | Status | Notes |
| --- | --- | --- |
| `flutter pub get` | PASS | Dependency warnings recorded in `BASELINE.md` |
| `dart format --set-exit-if-changed .` | PASS | Formatted 395 files, 0 changed |
| `flutter analyze` | PASS | No issues found |
| `flutter test` | PASS | 1170 passed, 12 skipped |
| `flutter test test/infrastructure/secure_storage_test.dart` | PASS | 5 tests passed; unavailable secure-storage plugin paths skipped in this Linux test shell; confirms no plaintext Linux fallback path is created |
| `flutter test integration_test/app_test.dart -d linux` | PASS | 4 Linux desktop smoke tests passed: app launch, settings navigation, provider settings navigation, and preset provider rendering |
| `scripts/check_readme_assets.sh` | PASS | Current 21 screenshot references are consistent |
| `scripts/check_repo_hygiene.sh` | PASS | No tracked generated/local/secret-like artifacts or obvious secret regex hits |
| `flutter build apk --release` | PASS | Built `build/app/outputs/flutter-apk/app-release.apk` (65.3 MB); Flutter emitted a non-blocking Kotlin Gradle Plugin migration warning for transitive plugins |
| `flutter build linux --release` | PASS | Built `build/linux/x64/release/bundle/museflow` |

## Release Automation Status

- CI workflow: created locally in `.github/workflows/ci.yml`; remote run pending.
- Release workflow: created locally in `.github/workflows/release.yml`; remote run pending.
- Latest Actions run: `27184067602` failed on Linux integration/build because the Ubuntu runner was missing `libsecret-1-dev`; workflow dependency fix is pending rerun.
- GitHub Release: not yet created.
- Artifacts required before close: Android APK, Linux tar.gz, Windows zip, SHA-256 checksums.

## Local Equivalent Commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/infrastructure/secure_storage_test.dart
flutter test integration_test/app_test.dart -d linux
scripts/check_readme_assets.sh
scripts/check_repo_hygiene.sh
```

## Known Open Items

- README screenshots refreshed locally. `scripts/generate_readme_screenshots.mjs` generated 21 reproducible 1440x1000 PNGs with offline demo data; visual spot-check confirmed readable Chinese and no square icon placeholders; `README.md` and `README.en.md` reference all 21 files.
- Attempted Linux desktop runtime capture from the local release bundle with isolated app data:

  ```bash
  HOME=/tmp/museflow-readme-home XDG_DATA_HOME=/tmp/museflow-readme-home/.local/share ./build/linux/x64/release/bundle/museflow
  ```

  Result: app process started but no window became discoverable through `xdotool`; stderr showed `libsecret_error: KeyringLocked`. This is consistent with the no-plaintext-fallback storage policy. Screenshot refresh still needs a real desktop session with unlocked Secret Service, or a test/demo boot path that bypasses native secure storage without weakening production storage behavior.
- Windows build must be validated by GitHub Actions.
- Push, observe remote CI through Kimi WebBridge or `gh`, repair failures, then publish and verify a GitHub Release.

## Next Exact Action

Commit the verified hardening changes, push, and observe GitHub Actions through `gh` fallback unless Kimi WebBridge reconnects.

## Remote Observation Method Update

Kimi WebBridge daemon was restarted successfully, but the browser extension is currently disconnected:

```text
{"extension_connected":false,"extension_id":"","extension_version":"","port":10086,"running":true,"version":"v1.9.17"}
```

Per the release plan fallback rule, remote CI and release observation will use authenticated `gh`/GitHub API unless the browser extension reconnects before push.
