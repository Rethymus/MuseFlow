# Editor Selection Scorecard

**Date:** 2026-06-01 (consolidated)
**Decision Framework:** D-02 weighted scoring
**Editors:** super_editor 0.3.0-dev.51 vs appflowy_editor 6.2.0

---

## Weighted Scoring Formula

**Total Score** = IME (40%) + Performance (30%) + API Extensibility (20%) + Community (10%)

Each category scored 1-5. Weighted sum produces final score (max 5.0).

---

## Category Scores

### 1. IME Compatibility (40% weight)

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| Compile on Flutter 3.44.0 | **5/5** (PASS) | **1/5** (FAIL) |
| Pinyin composing -> single char | **5/5** (PASS) | N/A (won't compile) |
| Multi-character commit | **5/5** (PASS) | N/A (won't compile) |
| Composition cancellation | **5/5** (PASS) | N/A (won't compile) |
| Mixed Chinese + ASCII | **5/5** (PASS) | N/A (won't compile) |
| Sogou Pinyin (manual) | PENDING | BLOCKED |
| Wubi (manual) | PENDING | BLOCKED |
| Microsoft Pinyin (manual) | PENDING | BLOCKED |
| Candidate window position | PENDING | BLOCKED |
| **IME Score** | **5.0** (automated) | **1.0** (compile failure) |

**Notes:**
- super_editor: 4/4 automated composition tests PASS. Manual testing pending (requires Windows desktop with physical keyboard).
- appflowy_editor: **Does not compile** on Flutter 3.44.0. Root cause: `DeltaTextInputService` missing `TextInputClient.onFocusReceived` implementation. All manual testing BLOCKED.
- The automated compile + composition tests are sufficient for scoring since appflowy_editor cannot even run.

### 2. Large Document Performance (30% weight)

**PENDING -- requires manual benchmark execution on Windows desktop**

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| 10K chars (baseline) | -- | -- |
| 50K chars (chapter) | -- | -- |
| 100K chars (threshold) | -- | -- |
| 300K chars (target) | -- | -- |
| Zero crashes at all sizes | -- | -- |
| **Performance Score** | **--** | **--** |

**Methodology:** Frame timing via `SchedulerBinding.addTimingsCallback`. See PERFORMANCE_DATA.md.

**Note:** appflowy_editor cannot be benchmarked since it does not compile.

### 3. API Extensibility (20% weight)

| Criteria | super_editor | appflowy_editor |
|----------|:-----------:|:---------------:|
| Custom Block Components | 4/5 | **5/5** |
| Floating Toolbar API | 2/5 | **5/5** |
| Document Model Queryability | 3/5 | **5/5** |
| **API Average** | **3.0/5** | **5.0/5** |

**Rationale:**
- appflowy_editor has a built-in `FloatingToolbar` widget with configurable items
- appflowy_editor's `Node.attributes` (JSON-compatible Map) naturally supports provenance metadata
- super_editor requires custom toolbar from scratch using `overlord` package
- See API_EXTENSIBILITY.md for detailed evaluation

**Note:** Despite higher API score, appflowy_editor cannot be used due to compile failure.

### 4. Community Activity (10% weight)

| Metric | super_editor | appflowy_editor |
|--------|:-----------:|:---------------:|
| GitHub Stars | 1,924 | 652 |
| Last Push | 2026-05-28 | 2026-05-26 |
| Open Issues | 307 | 138 |
| Release Cadence | Dev channel only | 5 major versions (2024-2025) |
| Backing | Flutter Bounty Hunters | AppFlowy (large OSS) |
| IME Issues Total | 366 (many resolved) | ~10 (P0 unfixed) |
| **Community Score** | **4/5** | **3/5** |

---

## Weighted Score Calculation

| Category | Weight | super_editor | appflowy_editor |
|----------|--------|:-----------:|:---------------:|
| IME Compatibility | 40% | 5.0 * 0.40 = **2.00** | 1.0 * 0.40 = **0.40** |
| Performance | 30% | -- (PENDING) | -- (PENDING) |
| API Extensibility | 20% | 3.0 * 0.20 = **0.60** | 5.0 * 0.20 = **1.00** |
| Community Activity | 10% | 4.0 * 0.10 = **0.40** | 3.0 * 0.10 = **0.30** |
| **Total (without Performance)** | **70%** | **3.00** | **1.70** |
| **Max possible with Performance** | **100%** | **3.00 + 1.50** | **1.70 + 1.50** |

---

## Final Recommendation

### **super_editor is the winning editor.**

The decision is clear even without performance data:

1. **appflowy_editor 6.2.0 does not compile** on Flutter 3.44.0 / Dart 3.12.0. This is a hard blocker -- the editor cannot be used at all until a compatible version is released.

2. **super_editor leads by 1.30 points** (3.00 vs 1.70) with 70% of categories scored. Even if appflowy_editor scored 5/5 on performance (best case), its total would be 3.20 -- barely ahead of super_editor's current 3.00 (which would also grow with performance data).

3. **super_editor passes all automated IME tests** (4/4), which is the highest-weighted category at 40%.

4. **The API extensibility gap** (3.0 vs 5.0) is real but manageable: super_editor's `overlord` package provides popover infrastructure for building a custom floating toolbar. The development cost is higher but not prohibitive.

### Action Items

- [x] Install super_editor in project pubspec.yaml (only the winning editor, per D-04)
- [x] Update CLAUDE.md tech stack: replace appflowy_editor with super_editor
- [ ] Manual IME testing with Sogou Pinyin, Wubi, Microsoft Pinyin (requires Windows desktop)
- [ ] Manual performance benchmarks (requires Windows desktop)
- [ ] Monitor appflowy_editor releases for Flutter 3.44.0 compatibility fix

---

*Consolidated from Plans 00-01 and 00-02 results on 2026-06-01*
