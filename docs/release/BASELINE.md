# MuseFlow v1.4 Release Hardening Baseline

Captured: 2026-06-09, Asia/Shanghai.

## Repository State

| Check | Result |
| --- | --- |
| Branch | `main` |
| Remote | `origin https://github.com/Rethymus/MuseFlow.git` |
| Sync state at startup | `main...origin/main` |
| Latest audited release commit | `18ea4b2 chore: prepare v0.1.2 release` |
| Tags | `v0.1.2`, `v0.1.1`, `v0.1.0`, `v1.3-phase16-complete`, `v1.2`, `v1.0` |
| Flutter project version | `0.1.2+3` |
| Platform directories | Present: `android/`, `linux/`, `windows/`; absent: `ios/`, `macos/`, `web/` |
| GitHub metadata | Present: issue templates, PR template, Dependabot config, CI workflow, and release workflow |
| README screenshots at startup | 21 PNG files under `docs/readme/screenshots/`; both READMEs reference the same 21 files |
| Untracked files at startup | None |

## Remote Observation Method

Kimi WebBridge daemon was running during the final continuation audit, but the browser extension was not connected:

```text
{"extension_connected":false,"extension_id":"","extension_version":"","port":10086,"running":true,"version":"v1.9.17"}
```

Remote CI and release observation therefore used authenticated `gh`/GitHub API evidence. The final audit must verify the current `main` run at the time of completion rather than relying on a stale hard-coded run id.

## Baseline Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `flutter --version` | PASS | Flutter 3.44.0 stable, Dart 3.12.0 |
| `flutter pub get` | PASS with warnings | 1 discontinued package: `super_editor_markdown`; 26 packages newer outside constraints |
| `dart format --set-exit-if-changed .` | FAIL initially, then PASS after formatting | Initial run formatted 219 files; rerun formatted 383 files with 0 changes |
| `flutter analyze` | FAIL initially, then PASS after fix | Initial lint: missing braces in `consistency_drift_chart.dart`; rerun: no issues |
| `flutter test` | PASS | 1170 tests passed, 12 skipped |
| `flutter test test/infrastructure/secure_storage_test.dart` | PASS | 5 tests passed; platform plugin unavailable in this Linux test shell, no plaintext fallback created |
| `flutter test integration_test/app_test.dart -d linux` | PASS | 4 integration smoke tests passed on Linux desktop |

## Hygiene Findings

- `android/local.properties` exists locally but is ignored by `android/.gitignore` and is not tracked.
- No tracked build outputs, `.dart_tool`, `ephemeral`, local properties, key stores, or obvious secret files were found by the baseline tracked-file scan.
- No obvious plaintext secrets were found by the baseline regex scan over source, docs, workflows, and tests.
- Linux generated plugin registrant files and Windows generated plugin registrant files are tracked as normal Flutter platform source artifacts.

## Failure Map And Fix Queue

| Priority | Item | Status | Evidence / Next Action |
| --- | --- | --- | --- |
| P0 | Format gate failed on current `HEAD` | Fixed locally | Repository-wide `dart format` changed 219 files; rerun passed |
| P0 | Analyzer lint blocked CI readiness | Fixed locally | Added braces in `lib/features/reports/presentation/charts/consistency_drift_chart.dart`; analyzer passed |
| P0 | Linux secure-storage plaintext fallback contradicted release security goal | Fixed and validated | Removed plaintext fallback from `SecureStorageService`; focused test passed; locked Secret Service behavior fails securely |
| P0 | GitHub CI/CD absent | Fixed and remotely verified | Added CI and release workflows; final audit verifies the current `main` CI run passes before closing the goal |
| P0 | Platform artifact builds unverified | Fixed and release-verified | Android and Linux build locally; release workflow published Android, Linux, and Windows artifacts |
| P0 | GitHub Release publication for v1.4 hardening | Fixed and verified | Published `v0.1.2`; Android/Linux/Windows artifacts and `SHA256SUMS.txt` are present; checksum verification passed |
| P1 | README screenshots are 19 images but v1.4 plan requires 21 workflow screenshots | Fixed locally | Generated 21 reproducible offline UI screenshots with `scripts/generate_readme_screenshots.mjs`; both READMEs reference all 21 files and README asset check passes |
| P1 | Platform support docs absent | Fixed locally | Added `docs/platform/PLATFORM_SUPPORT.md` and `docs/platform/STORAGE_VALIDATION.md` |
| P2 | Dependency cleanup | Improved, with remaining migration work deferred | Replaced the unconstrained direct `path: any` dependency with `path: ^1.9.1`. `flutter pub outdated` still reports `super_editor_markdown` as discontinued and several major-version updates. These are not CI/release blockers; replacing the editor Markdown stack should be handled as a separate migration with focused regression tests. |
