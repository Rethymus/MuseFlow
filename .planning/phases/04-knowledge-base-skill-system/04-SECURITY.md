---
phase: 04
slug: knowledge-base-skill-system
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-04
---

# Phase 04 — Security

Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| User input -> Hive storage | Entity names, descriptions, backstory, world-setting fields, aliases, and generated skill documents are stored locally in Hive. | User-authored creative content / local app data |
| Entity data -> AI prompt | Knowledge base content can be injected into AI system messages. | User-authored creative content sent to configured AI provider |
| AI output -> SkillDocument storage | AI-generated skill content is parsed into a local skill document. | AI-generated text / local app data |
| Active skill rules -> AI prompt | Active skill constraints are injected into AI system messages. | User-authored world-building rules sent to configured AI provider |
| AI deviation analysis -> user-facing warnings | AI-generated contradiction analysis is shown in the editor UI. | AI-generated advisory warnings |
| User keyboard input -> dialog search -> entity list | Quick-insert search filters local knowledge entities and inserts selected display names. | Local search query / local knowledge entity names |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-04-01 | Tampering | Entity field content | mitigate | CharacterCard and WorldSetting enforce field length limits and reject control characters in names and aliases at the domain layer. | closed |
| T-04-02 | Denial of Service | Hive storage | mitigate | CharacterCard and WorldSetting enforce max field lengths and max 20 aliases with max 50 chars each. | closed |
| T-04-03 | Information Disclosure | KnowledgeInjectionMiddleware | accept | Knowledge data is user-authored creative content; prompt injection occurs only through configured AI flows. | closed |
| T-04-04 | Tampering | NameIndex | mitigate | NameIndex is in-memory and rebuilt from repository-backed entity state through NameIndexService; external callers cannot persistently mutate authoritative storage through the index. | closed |
| T-04-05 | Tampering | AI-generated skill content | mitigate | Wizard separates concept input, generation, and completion; generated content is shown to the user before leaving the wizard, with no invisible background persistence beyond the explicit generation flow. | closed |
| T-04-06 | Denial of Service | Skill document size | mitigate | SkillDocument enforces max 50000-character content; SkillSections enforces max 10000 characters per section, including rawContent. | closed |
| T-04-07 | Tampering | DeviationDetectionService output | mitigate | Deviation warnings are advisory UI only, are dismissible, and parse failure returns no warnings instead of blocking or mutating content. | closed |
| T-04-08 | Information Disclosure | Skill rules in AI prompt | accept | Active skill content is user-authored creative world-building content; users control which skills are active. | closed |
| T-04-09 | Tampering | Entity name insertion | accept | Quick insert writes plain text display names into the editor document; there is no executable content path and the user can edit or delete inserted text. | closed |

Status: open · closed
Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-03 | Knowledge base prompt injection sends user-authored creative content, not app secrets; user controls the knowledge entries and configured provider. | GSD security audit | 2026-06-04 |
| AR-04-02 | T-04-08 | Active skill rules are user-authored creative content and activation is user-controlled. | GSD security audit | 2026-06-04 |
| AR-04-03 | T-04-09 | Inserted knowledge references are plain text editor content and remain user-editable. | GSD security audit | 2026-06-04 |

---

## Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-04-01 | `lib/features/knowledge/domain/character_card.dart` and `lib/features/knowledge/domain/world_setting.dart` validate field lengths and reject ASCII control characters in `name` and `aliases`; tests cover name and alias control-character rejection. |
| T-04-02 | `CharacterCard` and `WorldSetting` constructors limit alias count to 20 and alias length to 50; domain tests cover oversized fields and aliases. |
| T-04-03 | `lib/features/knowledge/application/knowledge_injection_middleware.dart` injects matched local entity context into system messages within a 30% token budget. Accepted by phase threat model. |
| T-04-04 | `lib/features/knowledge/infrastructure/name_index.dart` keeps in-memory maps only; `NameIndexService` rebuilds from repositories. |
| T-04-05 | `lib/features/knowledge/presentation/skill_generation_wizard.dart` uses a three-step flow: concept, AI generation, save/finish display. |
| T-04-06 | `lib/features/knowledge/domain/skill_document.dart` enforces `SkillDocument.maxContentLength = 50000` and `SkillSections.maxSectionLength = 10000`; `test/features/knowledge/domain/skill_document_test.dart` covers reject/accept boundaries. |
| T-04-07 | `DeviationDetectionService` filters low severity, returns empty results on parse/API failures, and `DeviationWarningWidget` exposes dismiss and clear-all controls. |
| T-04-08 | `SkillEnforcementMiddleware` injects active skill rules/taboos/terminology into system messages; accepted by phase threat model. |
| T-04-09 | `QuickInsertDialog` inserts `entity.displayName` through `InsertTextRequest` as plain text. |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-04 | 9 | 7 | 2 | OpenCode GSD secure-phase |
| 2026-06-04 | 9 | 9 | 0 | OpenCode remediation verification |

---

## Blocking Items

No open blocking items.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-04
