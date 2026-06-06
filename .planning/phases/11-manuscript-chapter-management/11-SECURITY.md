---
phase: 11
slug: manuscript-chapter-management
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-06
updated: 2026-06-06
---

# Phase 11 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Phase:** 11 — manuscript-chapter-management  
**ASVS Level:** L1  
**Audit State:** VERIFIED  
**Threats Closed:** 20/20  
**Threats Open:** 0/20  
**Unregistered Flags:** none

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Domain entity deserialization | Hive box data flows through `fromJson` into manuscript/chapter domain entities. | Local persisted manuscript/chapter metadata and content |
| Genre string input | User-created or preset genres flow into genre lookup and manuscript metadata. | Local user input |
| Hive write operations | Repository writes pass through entity `toJson` serialization. | Local manuscript/chapter records |
| Auto-save flush | Pending Markdown content is written to Hive on timer or force trigger. | Local manuscript chapter content |
| User input → Manuscript fields | Title, genre, description entered by user flow into domain entity. | Local user input |
| Widget → GoRouter navigation | Manuscript ID from user action flows into route path parameters. | Local manuscript ID |
| Document content → Markdown serialization | SuperEditor document is serialized to Markdown for persistence. | Local user-authored document content |
| Chapter title input → Chapter entity | Chapter title text flows into local domain entity and Hive storage. | Local user input |
| Route parameter → manuscriptId | Manuscript ID from URL is used for local chapter/manuscript queries. | Local route parameter |
| Template chapter titles → Chapter entities | Template-provided titles become local chapter skeletons. | Local template/user data |
| Chapter summaries → AI prompt | Adjacent chapter summaries can be injected into the AI prompt context. | User content sent through existing AI feature |
| UI → Riverpod notifier | Local UI actions trigger chapter loading/saving through providers. | Local IDs/content |
| Editor document → Hive repository | User manuscript content is serialized and persisted locally. | Local manuscript content |
| Flutter lifecycle → save service | App lifecycle events trigger best-effort persistence attempts. | Local pending editor content |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-11-01-plan01 | Tampering | `Manuscript.fromJson` / `Chapter.fromJson` | mitigate | Type-safe deserialization/casts; UI-level title length validation; no unsafe dynamic mutation. | closed |
| T-11-02-plan01 | Denial of Service | Hive box corruption | mitigate | Corrupted Hive data guarded by `fromJson` type safety; no broad unsafe parser path. | closed |
| T-11-SC-plan01 | Tampering | `super_editor_markdown` package install | mitigate | Package resolved and later serialization shifted to SuperEditor built-in APIs where relevant. | closed |
| T-11-03-plan02 | Denial of Service | `ChapterAutoSave` race condition | mitigate | `forceSave` cancels debounce timer; dirty flag gates writes; single `_flush` path performs persistence. | closed |
| T-11-04-plan02 | Information Disclosure | `ManuscriptRepository.getAllIncludingDeleted` | accept | Local-only method used for purge/recovery service, not UI-facing in reviewed code. | closed |
| T-11-05-plan02 | Tampering | `ChapterNotifier.reorder` sortOrder manipulation | mitigate | Recalculate sortOrder values sequentially after reorder/delete/split/merge operations. | closed |
| T-11-01-plan03 | Tampering | `ManuscriptCreateDialog` / `ManuscriptSettingsPage` | mitigate | Manuscript title non-empty and max-length validation; custom genres are bounded to 20 chars. | closed |
| T-11-02-plan03 | Spoofing | Route parameter `:id` | accept | Single-user local app; route ID used only for local Hive lookup. | closed |
| T-11-03-plan03 | Denial of Service | Manuscript card grid | accept | Local bounded rendering by manuscript list count. | closed |
| T-11-04-plan04 | Denial of Service | `serializeDocumentToMarkdown` | accept | Serialization is local and proportional to document size; debounced save reduces repeated calls. | closed |
| T-11-05-plan04 | Tampering | `ChapterRenameDialog` | mitigate | Chapter title validation: non-empty and max 100 chars. | closed |
| T-11-06-plan04 | Information Disclosure | Auto-save Markdown | accept | User content remains local in chapter repository; no network transmission in auto-save path. | closed |
| T-11-07-plan04 | Tampering | `ChapterCreateDialog` | mitigate | Chapter title validation: non-empty and max 100 chars. | closed |
| T-11-08-plan05 | Tampering | `ExportBundle.chapters` | accept | User's own local content in explicit export bundle. | closed |
| T-11-09-plan05 | Denial of Service | Purge service on startup | accept | Local Hive data, bounded by manuscript count, wrapped in try/catch. | closed |
| T-11-10-plan05 | Information Disclosure | Chapter summaries in AI prompt | accept | User's own content sent through existing user-configured AI feature/API keys. | closed |
| T-11-06-01 | Tampering | `EditorWithSidebar` manuscript/chapter selection | mitigate | Editor entry loads chapters by `widget.manuscriptId` before first selection. | closed |
| T-11-06-02 | Denial of Service | `ChapterAutoSave.forceSave` / Hive write path | mitigate | Await forced saves on switch/navigation; catch/log lifecycle best-effort errors; dispose only releases editor resources and does not start unawaited persistence. | closed |
| T-11-06-03 | Repudiation | Local save operations | accept | ASVS L1 local-only single-user app; persistence behavior verified by tests instead of audit logging. | closed |
| T-11-06-SC | Tampering | Package installs | accept | Gap-closure plan introduced no package installs. | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Threat Verification Evidence

| Threat ID | Status | Evidence |
|-----------|--------|----------|
| T-11-01-plan01 | CLOSED | `Manuscript.fromJson` and `Chapter.fromJson` now use checked extraction helpers instead of unsafe direct casts: `Manuscript.fromJson` delegates to `_requiredString`, `_optionalInt`, `_optionalStringList`, `_requiredDateTime`, and `_optionalDateTime` at `/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart:73-87`; helper validation throws controlled `FormatException`s at `/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart:155-215`. `Chapter.fromJson` delegates to `_requiredString`, `_requiredInt`, and `_requiredDateTime` at `/home/re/code/MuseFlow/lib/features/manuscript/domain/chapter.dart:59-69`; helper validation throws controlled `FormatException`s at `/home/re/code/MuseFlow/lib/features/manuscript/domain/chapter.dart:117-143`. Manuscript title length validation exists in create/settings UI at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:73-74`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:160-163`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:113-115`, and `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:251-257`. |
| T-11-02-plan01 | CLOSED | Corrupted Hive data now encounters explicit parser guards instead of unchecked `as` casts: manuscript required/optional strings and ints are validated at `/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart:155-173`, list element types at `/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart:175-190`, and dates via `DateTime.tryParse` at `/home/re/code/MuseFlow/lib/features/manuscript/domain/manuscript.dart:193-215`. Chapter required fields and dates are similarly guarded at `/home/re/code/MuseFlow/lib/features/manuscript/domain/chapter.dart:117-143`. |
| T-11-SC-plan01 | CLOSED | Package resolved and deprecation/shift documented: `/home/re/code/MuseFlow/pubspec.yaml:55`, `/home/re/code/MuseFlow/pubspec.lock:745-752`, `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-01-SUMMARY.md:125-128`, `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-04-SUMMARY.md:83-88`. Editor uses SuperEditor built-in serialization: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:20`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:143-145`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:225-229`. |
| T-11-03-plan02 | CLOSED | `forceSave` cancels debounce and awaits `_flush`; dirty flag gates writes: `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:13-17`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:27-33`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:39-58`. |
| T-11-04-plan02 | CLOSED | Accepted risk. Code evidence: `getAllIncludingDeleted` is repository/purge-service scoped: `/home/re/code/MuseFlow/lib/features/manuscript/infrastructure/manuscript_repository.dart:59-70`, `/home/re/code/MuseFlow/lib/features/manuscript/infrastructure/manuscript_purge_service.dart:41-53`. |
| T-11-05-plan02 | CLOSED | Sequential sort-order recalculation exists for reorder/delete/split/merge: `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_notifier.dart:83-87`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_notifier.dart:50-55`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_notifier.dart:154-169`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_notifier.dart:200-208`. |
| T-11-01-plan03 | CLOSED | Manuscript create/settings forms enforce non-empty and max-length validation: create title input maxLength at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:73-74`, create submit guard at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:156-163`, settings title input maxLength at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:113-115`, and settings save guard at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:243-257`. The product allows custom genres, but the input is bounded and validated: create custom genre maxLength/guard at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:114-115` and `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_create_dialog.dart:169-176`; settings custom genre maxLength/guard at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:155-156` and `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:262-275`. |
| T-11-02-plan03 | CLOSED | Accepted risk. Route ID is used for local editor/settings lookup: `/home/re/code/MuseFlow/lib/app.dart:60-72`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_settings_page.dart:74-84`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:114-123`. |
| T-11-03-plan03 | CLOSED | Accepted risk. Grid is bounded by local manuscript list count: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/manuscript_library_page.dart:154-166`. |
| T-11-04-plan04 | CLOSED | Accepted risk. Serialization is used from editor changes into debounced auto-save: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:225-229`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:18-21`, `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:27-33`. |
| T-11-05-plan04 | CLOSED | Rename dialog validates non-empty and max 100 chars with formatter: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/chapter_rename_dialog.dart:35-39`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/chapter_rename_dialog.dart:55-66`. |
| T-11-06-plan04 | CLOSED | Accepted risk. Auto-save persists local markdown to local chapter repository: `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:27-42`, `/home/re/code/MuseFlow/lib/features/manuscript/infrastructure/chapter_repository.dart:89-105`. |
| T-11-07-plan04 | CLOSED | Create dialog validates non-empty and max 100 chars with formatter: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/chapter_create_dialog.dart:35-39`, `/home/re/code/MuseFlow/lib/features/manuscript/presentation/chapter_create_dialog.dart:55-66`. |
| T-11-08-plan05 | CLOSED | Accepted risk. Export chapters are explicit local user content: `/home/re/code/MuseFlow/lib/features/story_structure/domain/export_bundle.dart:44-49`, `/home/re/code/MuseFlow/lib/features/story_structure/domain/export_bundle.dart:103-106`, `/home/re/code/MuseFlow/lib/features/story_structure/application/export_service.dart:107-120`. |
| T-11-09-plan05 | CLOSED | Accepted risk. Startup purge is local and wrapped in try/catch: `/home/re/code/MuseFlow/lib/main.dart:78-93`, `/home/re/code/MuseFlow/lib/features/manuscript/infrastructure/manuscript_purge_service.dart:41-58`. |
| T-11-10-plan05 | CLOSED | Accepted risk. Chapter summaries are prompt context fields injected into existing AI prompt pipeline: `/home/re/code/MuseFlow/lib/features/ai/application/prompt_pipeline.dart:64-71`, `/home/re/code/MuseFlow/lib/features/editor/application/chapter_context_middleware.dart:21-41`, `/home/re/code/MuseFlow/lib/features/editor/application/editor_prompt_pipeline.dart:40-43`. |
| T-11-06-01 | CLOSED | Editor entry calls `loadChapters(widget.manuscriptId)` before first selection: `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:104-128`. |
| T-11-06-02 | CLOSED | Forced saves are awaited for controllable transitions: chapter switch awaits `_forceSaveAsync()` at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:173-188`, settings navigation awaits at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:190-195`, and back navigation awaits at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:459`. Lifecycle pause/inactive uses best-effort async save with caught/logged errors at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:80-88` and `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:242-260`. Dispose no longer calls an unawaited save path: it calls `_disposeEditorOnly()` at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:72-76`, and `_disposeEditorOnly()` is documented/implemented as cleanup-only at `/home/re/code/MuseFlow/lib/features/manuscript/presentation/editor_with_sidebar.dart:263-278`. `ChapterAutoSave.dispose()` only cancels the debounce timer at `/home/re/code/MuseFlow/lib/features/manuscript/application/chapter_auto_save.dart:60-69`. |
| T-11-06-03 | CLOSED | Accepted risk. Persistence behavior covered by focused summary/tests: `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-06-SUMMARY.md:53-68`. |
| T-11-06-SC | CLOSED | Accepted risk. Gap-closure summary states no package additions/new security surface: `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-06-SUMMARY.md:11-13`, `/home/re/code/MuseFlow/.planning/phases/11-manuscript-chapter-management/11-06-SUMMARY.md:75-77`. |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-11-01 | T-11-04-plan02 | Soft-deleted manuscripts are retrievable by `getAllIncludingDeleted`, but the method is for purge/recovery service and is not UI-facing in reviewed code. Scope: local Hive data only. | GSD security audit | 2026-06-06 |
| AR-11-02 | T-11-02-plan03 | Route parameter `:id` can name any local manuscript ID, but this is a single-user local app with no auth boundary; ID is used only for local Hive lookup. | GSD security audit | 2026-06-06 |
| AR-11-03 | T-11-03-plan03 | Manuscript card grid renders based on local manuscript count; no remote attacker-controlled list exists in this feature. | GSD security audit | 2026-06-06 |
| AR-11-04 | T-11-04-plan04 | Markdown serialization is proportional to local document size; debounced save reduces repeated calls. | GSD security audit | 2026-06-06 |
| AR-11-05 | T-11-06-plan04 | Auto-save writes user's own manuscript markdown to local Hive; no network transmission occurs in auto-save path. | GSD security audit | 2026-06-06 |
| AR-11-06 | T-11-08-plan05 | ExportBundle includes user's own local chapter content in a user-initiated export pipeline. | GSD security audit | 2026-06-06 |
| AR-11-07 | T-11-09-plan05 | Startup purge iterates local manuscripts, is bounded by manuscript count, and is wrapped in try/catch. | GSD security audit | 2026-06-06 |
| AR-11-08 | T-11-10-plan05 | Chapter summaries may be included in AI prompt context through the existing user-configured AI feature/API keys; this introduces no new third-party boundary beyond AI features. | GSD security audit | 2026-06-06 |
| AR-11-09 | T-11-06-03 | ASVS L1 local-only single-user app has no audit log requirement; persistence behavior is verified by tests instead. | GSD security audit | 2026-06-06 |
| AR-11-10 | T-11-06-SC | Gap-closure changes introduced no package installs. | GSD security audit | 2026-06-06 |

*Accepted risks do not resurface in future audit runs unless the threat model changes.*

---

## Open Threats

None — all previously open threats were re-verified as closed on 2026-06-06.

| Threat ID | Category | Mitigation Expected | Evidence Gap | Recommended Remediation |
|-----------|----------|---------------------|--------------|-------------------------|
| — | — | — | — | — |

---

## Unregistered Flags

None. SUMMARY threat-flag sections either reported no new security-relevant surface or mapped to registered threats.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-06 | 20 | 16 | 4 | gsd-security-auditor |
| 2026-06-06 | 4 retried | 0 newly closed | 4 confirmed open | gsd-security-auditor retry |
| 2026-06-06 | 4 re-verified | 4 newly closed | 0 | secure-phase orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified — all Phase 11 threats have dispositions and verified closures; `threats_open: 0`.
