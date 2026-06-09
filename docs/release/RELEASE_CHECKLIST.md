# MuseFlow v1.4 Release Checklist

## Current Phase

Complete: local gates pass, remote CI is green on `main`, and GitHub Release `v0.1.0` is published with verified Android, Linux, Windows, and checksum artifacts.

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

- CI workflow: PASS on `main`, latest run `27185384533`, commit `e3ff6482f09a7628398cff86c60f6fbd2518d297`.
- Release workflow: PASS, run `27184897133`, tag `v0.1.0`.
- GitHub Release: published at `https://github.com/Rethymus/MuseFlow/releases/tag/v0.1.0`.
- Release assets verified:
  - `museflow-v0.1.0-android-unsigned.apk` (65,336,120 bytes)
  - `museflow-v0.1.0-linux-x64.tar.gz` (12,591,980 bytes)
  - `museflow-v0.1.0-windows-x64.zip` (14,930,513 bytes)
  - `SHA256SUMS.txt` (300 bytes)
- Checksum verification: PASS. Downloaded all release assets and ran `sha256sum -c SHA256SUMS.txt`; all three platform artifacts returned `OK`.

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

## Residual Non-Blocking Notes

- README screenshots are refreshed and complete. `scripts/generate_readme_screenshots.mjs` generated 21 reproducible 1440x1000 PNGs with offline demo data; visual spot-check confirmed readable Chinese and no square icon placeholders; `README.md` and `README.en.md` reference all 21 files, and `scripts/check_readme_assets.sh` passes.
- Attempted Linux desktop runtime capture from the local release bundle with isolated app data:

  ```bash
  HOME=/tmp/museflow-readme-home XDG_DATA_HOME=/tmp/museflow-readme-home/.local/share ./build/linux/x64/release/bundle/museflow
  ```

  Result: app process started but no window became discoverable through `xdotool`; stderr showed `libsecret_error: KeyringLocked`. This is expected secure behavior under a locked Secret Service and confirms the app does not fall back to plaintext secret files. README screenshots were refreshed through the reproducible offline UI evidence flow instead of weakening production secure-storage behavior.
- GitHub Actions emitted non-blocking Node.js 20 deprecation warnings for current marketplace actions. This does not block the release, but dependency updates should address it before GitHub removes Node.js 20 runner support.
- GitHub Actions noted `windows-latest` redirection to `windows-2025-vs2026` by June 15, 2026; Windows release artifact still built and uploaded successfully.

## Final Audit

- `git status --short --branch`: clean, `main...origin/main`.
- Local `HEAD` and `origin/main`: `e3ff6482f09a7628398cff86c60f6fbd2518d297`.
- Latest `main` CI: PASS, run `27185384533`.
- GitHub Release `v0.1.0`: published and not draft/prerelease.
- Release checksums: PASS for Android, Linux, and Windows artifacts.

## Remote Observation Method Update

Kimi WebBridge daemon was restarted successfully, but the browser extension is currently disconnected:

```text
{"extension_connected":false,"extension_id":"","extension_version":"","port":10086,"running":true,"version":"v1.9.17"}
```

Per the release plan fallback rule, remote CI and release observation will use authenticated `gh`/GitHub API unless the browser extension reconnects before push.
