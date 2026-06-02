# Phase 2: AI Provider + Capture Synthesis - Context

**Gathered:** 2026-06-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can configure an AI provider (OpenAI-compatible), select captured fragments, have AI synthesize them into coherent story paragraphs with anti-AI-scent treatment, edit the result, and send it to the editor. The core creative loop (capture → synthesize → edit) works end-to-end.

**In scope:**
- AI adapter interface + OpenAI-compatible adapter with streaming SSE
- Provider management UI (CRUD, presets) with secure key storage
- PromptPipeline middleware chain + anti-AI-scent system (prompt layer + post-processing)
- Fragment-to-paragraph synthesis flow with token budget management and error handling
- Settings page expansion to host AI provider configuration

**Out of scope:**
- Claude API adapter (Phase 6)
- Floating AI toolbar on text selection (Phase 3)
- Knowledge base auto-injection (Phase 4)
- Per-provider model parameter config (Phase 6)
- Custom model import (Phase 6)
- Android-specific AI optimization (Phase 6)

</domain>

<decisions>
## Implementation Decisions

### Provider 配置体验
- **D-01:** Provider management lives inside the Settings page as a sub-page (设置 → AI 模型). Left panel: saved provider list. Right panel: configuration form.
- **D-02:** Preset providers shown as clickable cards (OpenAI, DeepSeek, Ollama). Clicking a preset pre-fills Base URL, user only needs to enter API Key. "自定义" card for fully manual configuration. Ollama preset has no Key field.
- **D-03:** API Key input uses password field (hidden by default) with eye icon toggle. "测试连接" button sends a minimal API request to validate the key. Immediate feedback on validity.
- **D-04:** Default mode: simple radio selection — one active provider at a time. Settings include "高阶模式" toggle that, when enabled, reveals per-scene provider assignment (e.g., synthesis uses DeepSeek, polish uses GPT-4). Progressive complexity exposure.

### 碎片合成交互流程
- **D-05:** Synthesis result displayed in a slide-out panel from the right side of the capture page. Does not navigate away from the capture workspace. Panel shows streaming text in real time with edit capability.
- **D-06:** Iteration support: "重新生成" button at bottom of panel, with an optional text field for追加指令 (e.g., "换个语气", "多加点描写"). Empty field = plain regeneration. Each generation is independent; user can compare results.
- **D-07:** Confirmed text is inserted at the editor's cursor position (not appended to end). Switches to editor page after insertion so user sees the result in context.

### 反AI味策略
- **D-08:** Dual-layer anti-AI-scent: Prompt layer (first defense) + Post-processing layer (second defense). REQUIREMENTS AI-05 and AI-06 both implemented.
- **D-09:** Post-processing uses a built-in banned phrase list (seeded with common Chinese AI clichés) that users can edit in settings. Add/remove entries to match personal sensitivity.
- **D-10:** Post-processing replacement strategy: simple banned words are auto-replaced with synonyms (e.g., 然而→但是, 综上所述→删除). Complex structural patterns (套话句式) are highlighted for user to manually fix. Hybrid approach — don't over-automate, don't over-interrupt.
- **D-11:** Prompt layer combines persona injection ("你是一位经验丰富的中文小说作者") with negative checklist ("避免以下词汇和句式"). Persona sets the tone, checklist is the safety net. More token cost but higher compliance.

### Token 预算与错误处理
- **D-12:** Token budget auto-calculated based on model's context window: system prompt + persona + banned list + selected fragments + reserved output space. User sees nothing about tokens in normal flow.
- **D-13:** When fragments exceed budget, remove the last-selected fragments first (LIFO). Display "已移除 N 个碎片以保证质量" notice so user knows what was excluded.
- **D-14:** Error handling displays friendly messages directly in the synthesis panel (not dialogs/SnackBar): network failure → "网络连接失败", rate limit → "请求太快，请稍后再试", invalid key → "API Key 无效，请检查设置". Each error includes a "重试" button.
- **D-15:** Streaming display shows tokens in real time (typewriter effect). If stream breaks mid-generation, preserve received content and show "生成中断，可继续编辑或重试". Never lose partial work.

### Claude's Discretion
- Exact synthesis prompt template structure (system/persona/content ordering)
- Banned phrase initial seed list content (Chinese AI clichés)
- Auto-replacement synonym mapping table
- Token counting implementation for Chinese text (approximation algorithm)
- PromptPipeline middleware ordering and interface design
- Synthesis panel animation timing and dimensions
- Provider entity data model and Hive storage schema
- "高阶模式" toggle placement in settings UI
- Complex structural pattern detection rules for highlighting

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Project vision, core value (反AI味是产品灵魂), constraints, key decisions
- `.planning/REQUIREMENTS.md` — Full v1 requirements; Phase 2 covers AI-01, AI-03–AI-08, MODL-01, MODL-02, CAPT-03, CAPT-04
- `.planning/ROADMAP.md` §Phase 2 — Success criteria (6 items), risks (anti-AI-scent unproven, Chinese token estimation), plan list (02-01 to 02-04)
- `.planning/STATE.md` — Current project position (Phase 2, ready to plan)

### Architecture & Standards
- `CLAUDE.md` §Technology Stack — openai_dart for OpenAI-compatible APIs, anthropic_sdk_dart deferred to Phase 6, ollama_dart available
- `CLAUDE.md` §Architecture — Four-layer architecture, AI adapter unified interface, PromptPipeline middleware design
- `.claude/rules/02-museflow-architecture.md` — Layer responsibilities, dependency direction constraints
- `.claude/rules/03-flutter-standards.md` — Immutability, Widget rules, Riverpod patterns, error handling

### Prior Phase Context
- `.planning/phases/00-technical-validation/00-CONTEXT.md` — Phase 0 decisions (SSE streaming validated, openai_dart confirmed working)
- `.planning/phases/01-app-shell-editor-capture-ui/01-CONTEXT.md` — Phase 1 decisions (sidebar nav, capture UI, quick-capture, fragment multi-select)

### Existing Code
- `lib/core/infrastructure/secure_storage_service.dart` — API key storage with provider prefix pattern
- `lib/core/infrastructure/fragment_repository.dart` — Fragment CRUD with Hive backend
- `lib/core/domain/fragment.dart` — Immutable fragment entity with copyWith
- `lib/core/application/fragment_service.dart` — Fragment use case layer
- `lib/features/capture/presentation/capture_provider.dart` — Multi-select, tag filtering, CaptureState
- `lib/features/settings/presentation/settings_page.dart` — Placeholder settings page to expand
- `lib/app.dart` — GoRouter configuration (routes for capture/editor/settings)
- `lib/core/presentation/providers.dart` — Riverpod provider definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SecureStorageService`: Already uses `api_key_<providerId>` prefix pattern — extend for AI provider keys
- `FragmentRepository` + `FragmentService`: CRUD + filtering/sorting — synthesis reads from these
- `CaptureNotifier` / `CaptureState`: Has multi-select state (`selectedFragmentIds`) — synthesis trigger reads this
- `SettingsRepository`: Encrypted Hive storage — can store provider configs and anti-AI-scent settings
- `GoRouter` in `app.dart`: Add settings sub-routes for AI provider management
- `lib/features/ai/` directory: Already scaffolded (domain/application/infrastructure/presentation) with .gitkeep files

### Established Patterns
- Manual immutable entities with copyWith (no freezed codegen yet) — follow same pattern for AI domain objects
- Riverpod FutureProvider for repositories, AsyncNotifier for state — AI providers follow same pattern
- Hive TypeAdapters for serialization — AI entities need adapters
- Material 3 dark theme with indigo seed — new UI follows this
- Four-layer architecture: domain → application → infrastructure → presentation

### Integration Points
- `CaptureProvider.selectedFragmentIds` → synthesis reads selected fragments
- `SettingsPage` → expand with "AI 模型" sub-page
- `GoRouter` → add `/settings/ai-providers` sub-route
- `EditorPage` (super_editor) → insert synthesized text at cursor position
- `SecureStorageService` → store API keys for each provider
- `lib/features/ai/` → all new AI code lives here (adapter, pipeline, synthesis)

</code_context>

<specifics>
## Specific Ideas

- "子弹笔记" UX should extend to synthesis — it should feel like a natural next step from capturing, not a separate workflow
- Progressive complexity: default users see simple one-provider experience, power users unlock per-scene assignment via toggle
- Anti-AI-scent is the product soul — better to over-invest in the prompt template and banned phrase list than to ship generic AI output
- Synthesis panel should feel like a drafting workspace, not a chat interface — the user is a writer, not a chatbot user

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-AI Provider + Capture Synthesis*
*Context gathered: 2026-06-02*
