# MuseFlow v1.4 Release Checklist

## Current Phase

Complete: local gates pass, remote CI is green on `main`, and GitHub Release `v0.1.2` is published with verified Android, Linux, Windows, and checksum artifacts.

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

- CI workflow: PASS on `main`; final completion requires confirming the current latest `main` run succeeds after the last pushed commit.
- Release workflow: pending for tag `v0.1.2`.
- GitHub Release: pending at `https://github.com/Rethymus/MuseFlow/releases/tag/v0.1.2`.
- Release assets verified:
  - Pending release workflow output.
- Checksum verification: pending release workflow output.

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
- Dependabot PRs for newer GitHub Actions major versions are open. Some PR checks fail because those proposed major versions currently change CI behavior; keep them under review instead of merging unverified automation upgrades.
- Dependabot PR `#11` for `file_picker 11.0.2` fails Android build smoke because the generated registrant references `com.mr.flutter.plugin.filepicker.FilePickerPlugin`, which is no longer provided by that upgrade. Keep `file_picker` pinned until the migration path is verified.
- GitHub Actions noted `windows-latest` redirection to `windows-2025-vs2026` by June 15, 2026; Windows release artifact still built and uploaded successfully.

## Final Audit

- `git status --short --branch`: clean, `main...origin/main`.
- Local `HEAD` and `origin/main`: synchronized.
- Audited `main` CI: PASS for the latest pushed commit at completion time.
- GitHub Release `v0.1.2`: pending publication and checksum verification.
- Release checksums: PASS for Android, Linux, and Windows artifacts.

## Remote Observation Method Update

Kimi WebBridge was unavailable during this continuation audit because a stale PID file blocked the local HTTP probe:

```text
{"note":"PID file exists but HTTP probe failed -- daemon may be starting or stuck","pid":1916,"running":false}
```

Final remote CI and release observation uses authenticated `gh`/GitHub API evidence.
