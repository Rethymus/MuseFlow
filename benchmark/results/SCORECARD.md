# Editor Selection Scorecard

**Date:** 2026-06-01
**Decision Framework:** D-02 weighted scoring
**Editors:** super_editor 0.3.0-dev.20 vs appflowy_editor 6.2.0

---

## Weighted Scoring Formula

**Total Score** = IME (40%) + Performance (30%) + API Extensibility (20%) + Community (10%)

Each category scored 1-5. Weighted sum produces final score (max 5.0).

---

## Category Scores

### 1. IME Compatibility (40% weight)

**PENDING -- filled by Plan 00-02 (CJK IME validation)**

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| Sogou Pinyin | -- | -- |
| Wubi | -- | -- |
| Microsoft Pinyin | -- | -- |
| Candidate window position | -- | -- |
| Composing text correctness | -- | -- |
| **IME Score** | **--** | **--** |

**Notes:**
- super_editor has 6 open CJK-specific bugs including #2588 (IME position) and #2728 (composing crash)
- appflowy_editor has P0 bug #696 (Sogou garbled order) -- potential showstopper

### 2. Large Document Performance (30% weight)

**PENDING -- filled after manual benchmark execution on Windows**

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| 10K chars (baseline) | -- | -- |
| 50K chars (chapter) | -- | -- |
| 100K chars (threshold) | -- | -- |
| 300K chars (target) | -- | -- |
| Zero crashes at all sizes | -- | -- |
| **Performance Score** | **--** | **--** |

**Methodology:** Frame timing via `SchedulerBinding.addTimingsCallback`. See PERFORMANCE_DATA.md.

### 3. API Extensibility (20% weight)

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| Custom Block Components | 4/5 | **5/5** |
| Floating Toolbar API | 2/5 | **5/5** |
| Document Model Queryability | 3/5 | **5/5** |
| **API Average** | **3.0/5** | **5.0/5** |

**Rationale:**
- appflowy_editor has a built-in `FloatingToolbar` widget with configurable items -- zero-effort AI action menu
- appflowy_editor's `Node.attributes` (JSON-compatible Map) naturally supports provenance metadata
- super_editor requires custom toolbar from scratch using `overlord` package
- See API_EXTENSIBILITY.md for detailed evaluation

### 4. Community Activity (10% weight)

| Metric | super_editor | appflowy_editor |
|--------|:-----------:|:---------------:|
| GitHub Stars | 1,924 | 652 |
| Last Push | 2026-05-28 | 2026-05-26 |
| Open Issues | 307 | 138 |
| Release Cadence | Dev channel only | 5 major versions (2024-2025) |
| Backing | Flutter Bounty Hunters | AppFlowy (large OSS) |
| IME Issues Total | 366 (366 total, many resolved) | ~10 (fewer, but P0 unfixed) |
| **Community Score** | **4/5** | **3/5** |

**Rationale:**
- super_editor has more stars and very active development (daily commits on dev channel)
- However, it has no stable release -- only dev channel (0.3.0-dev.*)
- appflowy_editor is backed by AppFlowy, a well-funded OSS project with many CJK users
- appflowy_editor has fewer open issues (138 vs 307) suggesting better issue resolution
- super_editor's 366 IME issues indicates heavy investment in IME, but many remain open
- appflowy_editor's stable release cadence gives more confidence for production use

---

## Weighted Score Calculation

| Category | Weight | super_editor | appflowy_editor |
|----------|--------|:-----------:|:---------------:|
| IME Compatibility | 40% | -- (PENDING) | -- (PENDING) |
| Performance | 30% | -- (PENDING) | -- (PENDING) |
| API Extensibility | 20% | 3.0 * 0.20 = **0.60** | 5.0 * 0.20 = **1.00** |
| Community Activity | 10% | 4.0 * 0.10 = **0.40** | 3.0 * 0.10 = **0.30** |
| **Total** | **100%** | **1.00 + PENDING** | **1.30 + PENDING** |

---

## Partial Analysis (API + Community only)

Based on the two completed categories (API Extensibility + Community = 30% weight):

- **appflowy_editor leads by +0.30 points** (1.30 vs 1.00)
- The lead would grow if performance data confirms appflowy_editor handles large documents well
- The IME category (40%) is the dominant factor and could override either direction
- If super_editor has significantly better IME support, it could close the gap

**Critical path:** IME validation (Plan 00-02) is the decisive factor. A P0 IME bug in either editor is disqualifying.

---

## Recommendation

**Cannot make final recommendation until IME and Performance scores are available.**

However, the preliminary data strongly favors **appflowy_editor** on API grounds:
1. Built-in `FloatingToolbar` saves significant development time
2. JSON-compatible attributes simplify provenance tracking
3. Block-based document model is inherently queryable for story structure

**Risk factor:** appflowy_editor's P0 Sogou IME bug (#696) could be disqualifying if confirmed during Plan 00-02 testing. If appflowy_editor fails IME validation, super_editor becomes the only option despite weaker APIs.

**Next steps:**
1. Plan 00-02 fills IME scores
2. Manual benchmark execution fills Performance scores
3. Final recommendation calculated from complete scorecard
4. Per D-04, update CLAUDE.md tech stack with winning editor
