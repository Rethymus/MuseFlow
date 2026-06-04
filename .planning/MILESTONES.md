# Milestones

## v1.0 MVP (Shipped: 2026-06-04)

**Phases completed:** 7 phases (0–6), 25 plans, ~40 tasks
**Timeline:** 4 days (2026-05-31 → 2026-06-04)
**Codebase:** 111 source files (18,685 LOC), 64 test files (12,286 LOC)
**Commits:** 173

**Key accomplishments:**

1. **Editor spike validated** — super_editor confirmed for CJK IME (Sogou/Wubi/MSPinyin) and 100K+ character Chinese document performance, de-risking the entire project
2. **Full app shell** — Windows desktop app with sidebar navigation, Hive CE persistence, flutter_secure_storage for API keys, and adaptive layout for Android
3. **Rich text editor** — super_editor integration with formatting toolbar, large document support, and system-level IME compatibility
4. **AI provider + PromptPipeline** — OpenAI adapter with SSE streaming, 5-stage middleware chain (system prompt → knowledge injection → skill enforcement → anti-AI-scent → user content), token budget management
5. **Fragment capture → synthesis flow** — Bullet-note mode, AI synthesis with streaming display, editable output before editor insertion
6. **Floating AI toolbar** — Selection-triggered overlay with 3 AI actions (tone rewrite, paragraph polish, free input), text provenance tracking (inline diff with accept/reject), selective undo stack, and context anchors
7. **Knowledge base + Skill system** — Character cards, world settings, name-index entity matching, AI-assisted world-building documents, real-time skill enforcement with deviation detection
8. **Story structure** — Foreshadowing tracking with resolution detection, plot node management, character consistency guardian, logic loop detection via AI analysis
9. **Format cleaning + export** — Deterministic Chinese punctuation/Markdown/whitespace fixer with preview-first confirmation, TXT/Markdown/JSON export
10. **Multi-provider + Android** — Claude preset via OpenAI-compatible endpoint, per-provider model parameters (temperature/topP/maxTokens), responsive layout for Android

**Known deferred items at close:** 3 (Phase 00/01 human testing on physical Windows device — see STATE.md)

**Audit score:** 47/50 requirements covered (3 pending manual verification on real hardware)

---
