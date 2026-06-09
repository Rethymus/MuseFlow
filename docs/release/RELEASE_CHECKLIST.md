# MuseFlow v1.4 Release Checklist

## Current Phase

Complete: Web testing target is implemented, remote CI is green on `main`, and GitHub Release `v0.1.3` is published with verified Android, Linux, Windows, Web, and checksum artifacts.

## Local Verification Results

| Command | Status | Notes |
| --- | --- | --- |
| `flutter pub get` | PASS | Dependency warnings recorded in `BASELINE.md`; discontinued `super_editor_markdown` removed during Web target hardening |
| `dart format --set-exit-if-changed .` | PASS | Formatted 395 files, 0 changed |
| `flutter analyze` | PASS | No issues found |
| `flutter test` | PASS | 1170 passed, 12 skipped |
| `flutter test test/infrastructure/secure_storage_test.dart` | PASS | 5 tests passed; unavailable secure-storage plugin paths skipped in this Linux test shell; confirms no plaintext Linux fallback path is created |
| `xvfb-run -a flutter test integration_test/app_test.dart -d linux` | PASS | Remote CI run `27206511246` passed 4 Linux desktop smoke tests via xvfb; local shell lacks `xvfb-run`, and direct WSL Linux run built the test app but hung without output |
| `scripts/check_readme_assets.sh` | PASS | Current 21 screenshot references are consistent |
| `scripts/check_repo_hygiene.sh` | PASS | No tracked generated/local/secret-like artifacts or obvious secret regex hits |
| `flutter build apk --release` | PASS | Built `build/app/outputs/flutter-apk/app-release.apk` (65.3 MB); Flutter emitted a non-blocking Kotlin Gradle Plugin migration warning for transitive plugins |
| `flutter build linux --release` | PASS | Built `build/linux/x64/release/bundle/museflow` |
| `flutter build web --release` | PASS | Built `build/web`; Web is a testing/UAT target, not a production secure-storage target |

## Release Automation Status

- CI workflow: PASS on `main` for commit `04575bb3f24d7d95cc15364488c544463cbc3120`, run `27206511246`.
- Release workflow: PASS for tag `v0.1.3`, run `27207296155`, commit `04575bb3f24d7d95cc15364488c544463cbc3120`.
- GitHub Release: published as `MuseFlow v0.1.3` at `https://github.com/Rethymus/MuseFlow/releases/tag/v0.1.3`; not draft and not prerelease; published 2026-06-09T13:01:27Z.
- Release assets verified:
  - `museflow-v0.1.3-android-unsigned.apk` - 65,418,200 bytes, SHA-256 `dbd42da7f8cbd4296f33ad6cc312d731fde7c7e4d2d00708b3ccba5ced3a84fd`
  - `museflow-v0.1.3-linux-x64.tar.gz` - 12,595,280 bytes, SHA-256 `0f23449a9b7b206b661030e45c8b745c1193021d6742cfe5a344e3604706f3ba`
  - `museflow-v0.1.3-web.zip` - 14,921,179 bytes, SHA-256 `2699d3517a63a2865cf830d3eb408006ecdf10d69d90d1c906328fdd0f0b5af0`
  - `museflow-v0.1.3-windows-x64.zip` - 14,935,393 bytes, SHA-256 `d8aa5ab757b000bfb16a8753a0968e62e870137adc37c2dcfe38f4c4b4bbff24`
  - `SHA256SUMS.txt` - 390 bytes, SHA-256 `fb0a7969642753bf844c635a6e687d6783e40acf41156e0880dc9f65da2c42c4`
- Checksum verification: PASS after `gh release download v0.1.3 -D /tmp/museflow-v0.1.3-release` and `sha256sum -c SHA256SUMS.txt`.

## Local Equivalent Commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/infrastructure/secure_storage_test.dart
xvfb-run -a flutter test integration_test/app_test.dart -d linux
flutter build web --release
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
- GitHub Release `v0.1.3`: published, not draft, not prerelease, with Android/Linux/Windows/Web artifacts and checksums.
- Release checksums: PASS for Android, Linux, Windows, and Web artifacts.

## Remote Observation Method Update

Kimi WebBridge daemon was running during the final continuation audit, but the browser extension was not connected:

```text
{"extension_connected":false,"extension_id":"","extension_version":"","port":10086,"running":true,"version":"v1.9.17"}
```

Final remote CI and release observation uses authenticated `gh`/GitHub API evidence.
