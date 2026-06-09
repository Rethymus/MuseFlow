# MuseFlow v1.4 Release Hardening Goal

Use this file as the long-form objective for a `/goal` run. The short command should be:

```text
/goal follow the instructions in docs/goal/release-hardening-v1.4.md
```

## Mission

Turn MuseFlow into a lightweight, secure, repository-clean Flutter project that follows current GitHub project conventions, has CI/CD and release automation, honestly documents platform support, validates native storage behavior, refreshes README screenshots from real user workflows, and finishes with a successful GitHub Release.

This is a planning objective for a long-running autonomous agent. Do not treat planning as completion. Completion requires local verification, remote GitHub Actions evidence, a published release, valid artifacts, current README screenshots, and a clean git state.

Expected execution horizon: about 10 focused hours. The agent must assume this is a long-running owner task, not a short edit. If the first pass finishes early, use remaining time for deeper validation, failure hardening, platform artifact checks, screenshot spot-checks, and repository cleanup until the final completion criteria are met.

## Short Goal Command

Use exactly this short objective to avoid the `/goal` 4000-character limit:

```text
/goal follow the 10-hour autonomous release-hardening plan in docs/goal/release-hardening-v1.4.md until CI/CD, platform artifacts, storage validation, README screenshots, and GitHub Release are complete.
```

The objective is not "write these files". The objective is "ship the repository to a verified release-ready state". Do not mark complete while any remote CI, release, screenshot, storage, or cleanliness criterion remains open.

## Current Repository Facts To Recheck First

These facts were observed on 2026-06-09 and must be revalidated before execution:

- Branch: `main` is synchronized with `origin/main`.
- `.github/` currently has no files.
- `pubspec.yaml` version is `0.1.0+1`.
- Existing platform directories: `android/`, `linux/`, `windows/`.
- Missing platform directories: `ios/`, `macos/`, `web/`.
- README files currently claim Windows / Android / Linux targets.
- `docs/readme/screenshots/` currently contains 19 PNG files.
- Tests exist under `test/` and `integration_test/`.
- Existing storage stack: Hive CE and `flutter_secure_storage`.
- `.gitignore` exists but must be audited for platform generated files, machine-local files, build outputs, and secrets.
- `android/local.properties` and generated platform registrant files appear in the working tree view and must be checked for git tracking status before any cleanup.

## Required Skills And Operating Rules

Use these skills and workflows when available:

- `pua`: owner constraint and failure escalation.
- `kimi-webbridge`: real browser observation of GitHub Actions and Release pages after pushes.
- GSD skills such as `gsd-plan-phase`, `gsd-execute-phase`, `gsd-code-review`, `gsd-verify-work`, and `gsd-ship` for phased execution and verification.
- OMC/ECC/TCC or available review skills for code review, security review, and release review when present.

If a named skill or tool is unavailable, do not stop. Record the missing capability and use local commands, `gh` CLI, GitHub API, Flutter tests, logs, and review documents as the fallback.

Autonomous loop for every phase:

1. Inspect current files, git state, relevant source, docs, workflows, and platform directories.
2. Decide the next smallest high-value target and its evidence.
3. Act with scoped edits only.
4. Verify locally with the narrowest relevant command, and full verification at phase boundaries.
5. Push when local gates pass.
6. Observe remote Actions with Kimi WebBridge. If WebBridge is unhealthy, follow its operations guide; if still blocked, use `gh`/GitHub API and record the blocker.
7. Repair failures from logs, not guesses.
8. Record files changed, commands run, local results, remote URLs/status, screenshot status, risks, and next phase entry.

Failure rules:

- Never call a CI/release/platform/storage failure an environment problem without evidence.
- First failure: read the full log and fix the root cause.
- Second failure of the same issue: output `[PUA-DIAGNOSIS] 问题是 ___；证据是 ___；下一步动作是 ___。` and switch to a substantially different approach.
- Third failure of the same issue: perform the full PUA L2/L3 checklist: read failure signal, search, read original source/materials, verify assumptions, reverse assumptions, isolate minimally, and change direction.
- Do not remove tests, weaken assertions, broaden ignores, or drop platforms just to get green CI.
- Do not ask the user to manually check CI. The agent must observe it through WebBridge or GitHub API.

## Ten-Hour Execution Budget

This timeline is a pacing model, not a reason to stop at exactly ten hours. Preserve the order unless evidence shows a higher-priority risk. If a phase finishes early, pull the next phase forward. If a phase overruns, keep the final completion criteria authoritative.

### Hour 0.0-0.5: Startup, Skill Health, And Repository Reality

Primary objective: prove the starting state.

Actions:

- Read this file fully before editing.
- Check `git status --short --branch`, `git remote -v`, current branch, latest commits, tags, tracked generated files, and untracked files.
- Check `gh auth status` and repository URL if `gh` is available.
- Check `~/.kimi-webbridge/bin/kimi-webbridge status`.
- If WebBridge is unhealthy, read the Kimi WebBridge operations guide immediately and attempt repair. If repair fails, create a recorded fallback plan using `gh`/GitHub API.
- Inspect `.github/`, `pubspec.yaml`, `.gitignore`, README files, platform dirs, test dirs, and `.planning/`.

Required output:

- Create or update `docs/release/BASELINE.md` with starting facts, command results, and unknowns.
- Add a "Remote Observation Method" section stating WebBridge healthy/unhealthy and fallback.

Continue only when:

- Current repository facts are recorded.
- No untracked or tracked machine artifact is ignored without explanation.

### Hour 0.5-1.5: Baseline Commands And Failure Map

Primary objective: establish what passes before changing code.

Actions:

- Run `flutter --version`.
- Run `flutter pub get`.
- Run `dart format --set-exit-if-changed .`.
- Run `flutter analyze`.
- Run `flutter test`.
- Run the smallest stable integration smoke. If existing integration tests require a device or desktop harness, identify the runnable subset or create a documented plan for a CI-friendly smoke.
- Record failures with exact command, exit code, relevant log excerpt, suspected root cause, and priority.

Required output:

- `docs/release/BASELINE.md` includes a command table and failure map.
- If baseline fails, create a fix queue ordered by security, CI blockers, release blockers, platform blockers, storage risks, README drift, test coverage, cleanup.

Continue only when:

- The next implementation steps are derived from real baseline data.

### Hour 1.5-2.5: GitHub Project Skeleton And Local Check Scripts

Primary objective: make GitHub workflows and repo checks explicit.

Actions:

- Add `.github/workflows/ci.yml`.
- Add `.github/dependabot.yml`.
- Add issue templates and PR template.
- Add `SECURITY.md` and `CONTRIBUTING.md`.
- Add small repository check scripts only if they reduce workflow complexity; otherwise keep checks inline in workflow YAML.
- Ensure CI permissions are minimal and fork PRs do not access secrets.
- Ensure `.gitignore` blocks local/generated artifacts without hiding source files needed by Flutter.

Required output:

- GitHub metadata files exist.
- CI has jobs for format, analyze, tests, README assets, hygiene, and at least build-smoke preparation.
- Local equivalent commands are documented in `docs/release/RELEASE_CHECKLIST.md`.

Continue only when:

- YAML is syntax-sane by inspection or local validation.
- No workflow requires unavailable secrets for PR validation.

### Hour 2.5-3.5: CI Matrix, Integration Smoke, README Asset Checks

Primary objective: make push/PR validation meaningful and fast.

Actions:

- Wire CI jobs for:
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - selected integration smoke
  - README asset consistency
  - repository hygiene and secret scan
- Prefer checks that run on Ubuntu for fast feedback.
- If integration smoke is unstable, fix it or create a minimal smoke that launches app/navigation/settings/manuscript library using existing test patterns.
- Do not skip unstable tests without a documented external constraint and a replacement smoke.

Required output:

- CI workflow can run locally by equivalent commands.
- README asset/hygiene check is represented in code, script, or workflow step.

Continue only when:

- Local equivalent validation passes or has an explicit fix queue.

### Hour 3.5-4.75: Platform Strategy And Native Storage Validation

Primary objective: convert platform claims into documented build/storage facts.

Actions:

- Create `docs/platform/PLATFORM_SUPPORT.md`.
- Create `docs/platform/STORAGE_VALIDATION.md`.
- Audit Hive initialization paths and `flutter_secure_storage` usage in source.
- Document expected storage behavior:
  - Windows: app data + Credential Manager.
  - Android: app data + Android Keystore.
  - Linux: XDG/app data + Secret Service/libsecret dependency.
  - Web/macOS/iOS: only if generated and validated; otherwise document as conditional/future.
- Add or update tests for storage abstractions where possible without relying on host-specific secret services.
- Run Android and Linux build smoke locally if environment supports them.
- Leave Windows build to Actions unless a Windows environment exists.

Required output:

- Platform support tiers and storage validation matrix are committed-ready.
- README platform claims have a clear source of truth.

Continue only when:

- Tier 1 platform list is honest.
- Any unsupported/conditional platform has a concrete reason, not vague caution.

### Hour 4.75-5.75: Release Workflow And Artifact Packaging

Primary objective: make GitHub produce release artifacts.

Actions:

- Implement `.github/workflows/release.yml` with `workflow_dispatch` and `push` tag `v*`.
- Build Android APK and optional AAB.
- Build Linux release and package tar.gz.
- Build Windows release on `windows-latest` and package zip.
- Generate SHA-256 checksums.
- Generate release notes with version, platforms, signing status, known limits, and verification commands.
- Do not claim signed artifacts unless signing secrets/certificates actually exist.

Required output:

- Release workflow can run manually.
- `docs/release/RELEASE_CHECKLIST.md` explains release triggering, artifacts, checksums, and post-release verification.

Continue only when:

- Release workflow has minimal permissions and can publish via `GITHUB_TOKEN`.

### Hour 5.75-6.75: Lightweight, Security, Dependency, And Repo Hygiene Pass

Primary objective: remove avoidable risk and weight.

Actions:

- Run `flutter pub outdated`.
- Inspect dependencies for unused or loose constraints, including `path: any` and `super_editor_markdown`.
- Search for secrets and unsafe examples with `rg -n` over source, docs, workflow files, and tests.
- Search `TODO|FIXME|skip|ignore` and triage.
- Check tracked files for generated artifacts and machine-local files.
- Review Android namespace/minSdk/targetSdk/versionCode, Windows metadata, Linux CMake/package metadata.

Required output:

- Record dependency/security decisions in `docs/release/BASELINE.md` or `docs/release/RELEASE_CHECKLIST.md`.
- Remove or fix safe cleanup items.
- Leave a documented backlog only for items that are genuinely out of scope or require external assets/accounts.

Continue only when:

- No obvious plaintext secret or build artifact remains tracked.

### Hour 6.75-8.0: Full User-View UAT And Screenshot Refresh

Primary objective: update README screenshots from real current UI, not old assumptions.

Actions:

- Run the app in a mode suitable for deterministic demo data. Prefer existing FakeAdapter/test fixtures if no real API key is available.
- Use browser/desktop automation or Flutter screenshot tooling to capture a desktop viewport at least 1440x1000.
- Act as a real author and execute every major workflow:
  1. manuscript library
  2. capture inbox
  3. AI organization
  4. chapter editor
  5. editor AI toolbar
  6. character cards
  7. world settings
  8. template gallery
  9. skill rules
  10. foreshadowing
  11. plot timeline
  12. story arc
  13. logic guardian
  14. cleanup/export
  15. writing stats
  16. token audit
  17. reports hub
  18. report details
  19. settings
  20. AI model management
  21. AI phrase filtering
- Save refreshed screenshots under `docs/readme/screenshots/`.
- Update `README.md` and `README.en.md` together.
- Spot-check every screenshot for readable Chinese, non-loading state, no error page, no stale feature claims.

Required output:

- Screenshot set is current and referenced by both READMEs.
- README states only verified platform support and release status.

Continue only when:

- README image checks pass.
- Screenshots were generated from actual UI states after the code changes.

### Hour 8.0-8.75: Full Local Regression And Fix Loop

Primary objective: prove local readiness before pushing.

Actions:

- Run:
  - `flutter pub get`
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - selected integration smoke
  - README image/reference check
  - repository hygiene check
  - `flutter build apk --release`
  - `flutter build linux --release`
- Fix failures based on logs.
- For repeated failures, apply PUA escalation exactly.

Required output:

- `docs/release/RELEASE_CHECKLIST.md` contains local regression results.

Continue only when:

- Local gates pass, or a blocker is documented with exact external dependency evidence.

### Hour 8.75-9.5: Push, Observe Actions, Repair Remote Failures

Primary objective: make remote CI green.

Actions:

- Commit logical changes.
- Push to `origin/main` or a release-hardening branch if branch protection requires PR flow.
- Use Kimi WebBridge to inspect latest Actions run. If unhealthy, use `gh`/GitHub API and record why.
- For every failed job:
  - open failed step
  - read logs
  - identify root cause
  - reproduce locally or create minimal verification
  - fix
  - run relevant local test
  - commit and push again
- Continue until main/PR CI is green.

Required output:

- Actions run URL(s), status, failed job summaries, and repair notes recorded in release checklist.

Continue only when:

- Latest required CI run is green, or a concrete external blocker is documented.

### Hour 9.5-10.0+: Release, Verify Artifacts, And Close

Primary objective: publish and verify the GitHub Release.

Actions:

- Decide version/tag from `pubspec.yaml` and release policy.
- Trigger release by tag or `workflow_dispatch`.
- Observe release workflow through Kimi WebBridge or fallback API.
- Repair release failures:
  - build failure: fix code/workflow
  - permission failure: fix workflow permissions
  - signing failure: downgrade to clearly labeled unsigned artifact if no secrets exist
  - artifact upload/checksum failure: fix packaging/upload
- Open Release page and verify:
  - Android artifact exists
  - Linux artifact exists
  - Windows artifact exists
  - checksums exist
  - release notes include platform support, signing status, known limitations, verification summary
- Ensure final `git status` is clean and local/remote are synchronized.

Required output:

- Final report with commits, tag, Actions URLs, Release URL, local command results, platform support, storage validation, screenshot refresh summary, and residual risks.

Continue beyond 10 hours if:

- CI is red.
- Release is missing or incomplete.
- Artifacts/checksums are missing.
- README screenshots are stale.
- Working tree is dirty.

## Long-Run Recovery And Context Handoff

Because this is a long run, preserve restartability:

- After each hour or major phase, update `docs/release/RELEASE_CHECKLIST.md` with:
  - current phase
  - completed actions
  - commands and results
  - latest local blockers
  - latest remote URLs
  - next exact action
- If context compaction or interruption happens, resume from the latest checklist entry.
- Do not restart from scratch unless the checklist is missing or contradicted by current git state.
- If a remote run is still in progress, poll it until success/failure before final reporting.

## Phase 0: Baseline Audit And Risk Freeze

Goal: establish facts before changing CI or release automation.

Tasks:

- Check `git status`, remotes, branch, tags, release history, tracked generated files, and current untracked files.
- Audit `.gitignore` and tracked files for `build/`, `.dart_tool/`, `ephemeral/`, `local.properties`, IDE state, logs, keys, and caches.
- Compare `pubspec.yaml`, platform directories, README files, `.planning/PROJECT.md`, and `.planning/ROADMAP.md`.
- Run and record:
  - `flutter --version`
  - `flutter pub get`
  - `dart format --set-exit-if-changed .`
  - `flutter analyze`
  - `flutter test`
  - selected `integration_test` smoke or current stable integration subset
- Create or update a baseline report under `.planning/` or `docs/release/BASELINE.md` with pass/fail status, root causes, priorities, and commands.

Acceptance:

- A factual baseline exists.
- Later work references this baseline instead of generic assumptions.

## Phase 1: GitHub Project Standardization

Goal: add standard GitHub project structure with minimal permissions.

Tasks:

- Add or update:
  - `.github/workflows/ci.yml`
  - `.github/workflows/release.yml`
  - `.github/dependabot.yml`
  - `.github/ISSUE_TEMPLATE/`
  - `.github/PULL_REQUEST_TEMPLATE.md`
  - `SECURITY.md`
  - `CONTRIBUTING.md`
  - `CODE_OF_CONDUCT.md` only if appropriate for the repo
- Pin Flutter setup strategy with `subosito/flutter-action` on stable or an explicit version after checking project SDK constraints.
- Configure pub and Gradle caches.
- Use minimum permissions:
  - CI: `contents: read`
  - Release: `contents: write` only where required
- Ensure fork PR safety and no secret exposure.

Acceptance:

- GitHub files exist and match current project needs.
- Local commands and CI commands stay aligned.

## Phase 2: CI Validation Matrix

Goal: catch regressions on every push and PR.

Required CI jobs:

- Format: `dart format --set-exit-if-changed .`
- Static analysis: `flutter analyze`
- Unit/widget tests: `flutter test`
- Integration smoke: stable app-launch/navigation/settings/manuscript-library smoke via existing or new `integration_test`
- README asset checks:
  - every image referenced by `README.md` and `README.en.md` exists
  - screenshot directory and README references are consistent
- Repository hygiene:
  - no tracked build outputs, ephemeral outputs, `local.properties`, keys, tokens, or caches
  - no obvious plaintext API keys or secrets
- Optional non-blocking coverage reporting, with thresholds introduced only after baseline is stable.

Acceptance:

- `ci.yml` passes on Ubuntu for push/PR.
- Flaky tests are diagnosed and fixed. Skips require documented external evidence.

## Phase 3: Platform And Native Storage Support

Goal: make platform support an audited fact.

Tasks:

- Create `docs/platform/PLATFORM_SUPPORT.md`:
  - Tier 1 candidates: Windows, Android, Linux.
  - Tier 2 candidates: Web, macOS, iOS only if generated, adapted, and validated; otherwise document runner/signing/storage limitations.
- Decide whether to generate `web/`, `macos/`, and `ios/`. Web can build on Linux but must pass Hive/secure-storage support analysis. macOS/iOS need macOS runners and iOS release signing constraints.
- Create `docs/platform/STORAGE_VALIDATION.md` covering:
  - Hive paths on Windows app data, Linux XDG/app data, Android app data, and Web if enabled.
  - Secure storage behavior for Windows Credential Manager, Android Keystore, Linux Secret Service/libsecret, and Web support or fallback.
  - Manual or automated smoke: save API key, save window size, create manuscript/chapter, restart and read, clear stats without deleting prose, import/export.
- Add tests or documented smoke scripts where practical.
- Build Tier 1 platforms:
  - Android: `flutter build apk --release`, and AAB if release needs it.
  - Linux: `flutter build linux --release`, package as tar.gz.
  - Windows: build on `windows-latest`, package as zip.
  - Web only if accepted: `flutter build web --release`.

Acceptance:

- Every Tier 1 platform has a build artifact in CI/release.
- README and release notes do not claim unverified platforms.

## Phase 4: Release Automation

Goal: publish artifacts through GitHub Actions.

Tasks:

- Implement `.github/workflows/release.yml`.
- Triggers:
  - `push` tags matching `v*`
  - `workflow_dispatch`
- Release workflow:
  - read version from `pubspec.yaml`
  - build Android APK and optional AAB
  - build Linux release package
  - build Windows zip on `windows-latest`
  - optionally build Web static package if supported
  - generate SHA-256 checksums
  - generate release notes with summary, platform support, known limits, signing status, and verification commands
  - publish with `softprops/action-gh-release` or `gh release`
- Signing policy:
  - do not claim signing without secrets/certificates
  - Android may publish unsigned artifacts if no signing secrets exist, clearly labeled
  - Windows/macOS unsigned artifacts must be clearly documented

Acceptance:

- `workflow_dispatch` can create a draft or prerelease.
- tag `vX.Y.Z` creates a release with artifacts, checksums, and notes.

## Phase 5: Remote CI/CD Observation Loop

Goal: close the loop after each push.

Tasks:

- Run `~/.kimi-webbridge/bin/kimi-webbridge status`.
- If healthy, use WebBridge to open GitHub Actions, inspect latest run, inspect failed jobs/steps, and record URL/status.
- If unhealthy, read the skill operations guide, attempt repair, then fall back to `gh run list`, `gh run view`, `gh run view --log`, or GitHub API.
- For every failure, record:
  - problem
  - evidence
  - root cause
  - fix
  - local verification
  - next remote run URL/status

Acceptance:

- Every pushed CI/release run has an observed URL and status.
- Failures are repaired or documented with concrete external blockers.

## Phase 6: Lightweight, Secure, No-Extra-Code Cleanup

Goal: reduce risk and repository weight.

Tasks:

- Run dependency audit:
  - `flutter pub outdated`
  - check unused dependencies
  - replace `path: any` with a reasonable compatible constraint if safe
- Search and triage `TODO`, `FIXME`, `skip`, `ignore`, dead files, stale helpers, and duplicate logic.
- Security checks:
  - scan for API keys, tokens, passwords, private base URLs, and accidental secrets
  - ensure secure storage never falls back to plaintext for sensitive values
  - review workflow secret exposure and permissions
- Native metadata:
  - Android namespace/minSdk/targetSdk/versionCode
  - Windows app metadata/icon
  - Linux CMake/package metadata
- Remove unneeded machine or generated files from tracking when confirmed safe.

Acceptance:

- `flutter analyze` has no actionable issue or has documented accepted non-blockers.
- No tracked secrets or machine artifacts.
- Dependency and cleanup decisions are recorded.

## Phase 7: Full User-View UAT And README Screenshot Refresh

Goal: update README screenshots from actual user workflows after code/platform changes.

Required user journeys and screenshots:

1. Manuscript library: create/view multiple manuscripts, status, target words.
2. Capture inbox: add ideas and filter tags.
3. AI organization: select fragments and organize with real key or FakeAdapter/offline demo.
4. Chapter editor: open manuscript, switch chapters, edit prose, verify auto-save state.
5. Editor AI floating toolbar: rewrite tone, polish paragraph, free input.
6. Knowledge base character cards: add/view character.
7. World settings: add/view setting.
8. Template gallery: choose template, preview, draft.
9. Skill rules: enable/disable rules.
10. Story structure foreshadowing: plant, develop, resolve.
11. Plot timeline: nodes and status.
12. Story arc graph.
13. Logic guardian panel.
14. Cleanup and export.
15. Writing stats.
16. Token audit.
17. Reports hub.
18. Token cost/pain point/anti-AI-scent/consistency reports.
19. Settings.
20. AI model management.
21. AI phrase filtering.

Screenshot requirements:

- Real UI, readable Chinese, no loading state, no error page.
- Desktop at least 1440x1000.
- Add Android/Web groups only if those platforms are supported and validated.
- Update `README.md` and `README.en.md` together.
- Keep `docs/readme/screenshots/` references and actual files consistent.

Acceptance:

- README image references all exist.
- Screenshot count and references are intentionally consistent.
- Manual visual spot-check confirms images are readable and current.

## Phase 8: Full Regression

Goal: prove changes did not break existing features.

Run:

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- selected integration smoke
- `flutter build apk --release`
- `flutter build linux --release`
- Windows build through GitHub Actions
- README image/reference check
- release workflow dry run or `workflow_dispatch` draft/prerelease

Acceptance:

- Local verification passes or has concrete documented external blockers.
- GitHub Actions pass.
- Release workflow succeeds at least once via `workflow_dispatch`.

## Phase 9: Publish And Close

Goal: push final state and publish a release.

Tasks:

- Update `.planning/PROJECT.md` and `.planning/ROADMAP.md` with v1.4 / release-hardening milestone.
- Commit in clear logical commits, for example:
  - `ci: add GitHub Actions validation matrix`
  - `build: add release artifact workflow`
  - `chore: harden platform storage and repo hygiene`
  - `docs: refresh README screenshots`
- Push to origin.
- Observe Actions with Kimi WebBridge or fallback API.
- Fix all failures.
- Create a tag based on `pubspec.yaml`, for example `v0.1.0` or the next decided version.
- Wait for release workflow.
- Open Release page and verify artifacts, checksums, notes, and platform limits.
- Add README badges for CI, Release, and License if applicable.

Acceptance:

- `origin/main` latest CI is green.
- GitHub Release exists and is reachable.
- Windows, Android, and Linux artifacts exist with checksums, unless a documented external blocker exists.
- README screenshots are current.
- `git status` is clean.

## Final Completion Criteria

Only mark the goal complete when all are true:

- local `HEAD` and `origin/main` are synchronized
- `git status` is clean
- latest main-branch GitHub Actions are green
- release workflow succeeded
- GitHub Release page exists for the selected tag
- target platform artifacts and checksums exist
- README.md and README.en.md image references are valid
- screenshots under `docs/readme/screenshots/` reflect current user-visible functionality
- `flutter analyze` passes
- `flutter test` passes
- platform build smoke passes or has honest signed-off limitations
- no tracked plaintext secrets, machine artifacts, generated build output, or temporary code

Final report must include:

- commits
- tag
- Actions URLs and statuses
- Release URL
- local command results
- platform support summary
- storage validation summary
- screenshot refresh summary
- remaining risks or follow-up backlog
