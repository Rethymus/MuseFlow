---
quick_id: 260619-nwc
slug: template-completion-real-glm
date: 2026-06-19
status: complete
commits: [34ad8ed]
---

# template_completion 真实 GLM 验证 + JSON 防御解析（闭合第4条 LLM 结构化 JSON 输出 gap）

## 闭环

ea1/ea2/ea3 闭合 editor AI 三大 LLM 输出路径真实覆盖后，穷尽侦察第4个独立零真实覆盖路径：
`TemplateCompletionService`（新故事模板脚手架，`template_draft_page` 的「AI 补全」按钮）要求**严格 JSON**
（world + characters 结构），却用**裸 `jsonDecode(buffer.toString())` 零防御解析**，且 `_applyCompletion`
只读**顶层** `world`/`characters`。这是同类 JSON 路径中**唯一零防御**的——logic_guardian/guardian_check/
editorial_review 都已有 `_extractJson`/`parseFromLLM`。

用 temp BigModel key（GLM-4-flash）curl 双重确认真实输出**双重失败**：
- **(A) fence 包裹 100%**：` ```json ... ``` ` → 裸 jsonDecode 抛 FormatException → `succeeded:false`。
- **(B) 嵌套 echo**：模型把 world/characters 嵌在 `draft`/`responseShape` 下（echo 输入 payload envelope）→
  `_applyCompletion` 读顶层 null → 即便修 fence 也"succeeded:true 但零字段填上"。

canned `template_completion_service_test` 喂干净 flat JSON via fake stream——两个失败模式全漏。这是
gap-analysis Phase 25「需外部 key/网络，本环境不可执行」的漏网 bug，用户给 temp key 解锁后逐路径侦察捕获。

## 方案（构造注入 + 双重防御，对齐既有 _extractJson/parseFromLLM 模式）

`TemplateCompletionService` 构造注入（openAIAdapter/apiKey/baseUrl/model 直接传）→ 真实测试镜像 ea3
最简洁。两处修复：

1. **`_extractJsonObject` 防御解析**（strip fence + 隔离首个 `{...}`）：line 83 `jsonDecode(raw)` →
   `jsonDecode(_extractJsonObject(raw))`。镜像 logic_guardian.dart:139 / guardian_check_service.dart:208
   的 `_extractJson`（数组版改对象版）。
2. **`_resolveShape` nesting 回退**：`_applyCompletion` 开头解析 shape——顶层优先（既有 flat 契约），
   回退 `draft` → `responseShape`（真实模型 echo payload envelope）。

canned 测试 flat 顶层 JSON 走 `_resolveShape` 第一分支 + `_extractJsonObject` 无 fence 直返 → 零行为回归
（5 测试全绿）。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze` (templates feature) | 0 issues |
| TDD RED（未修代码跑 real-GLM 测试） | ✅ 复现 bug——`FormatException: Unexpected character (at character 1) \`\`\`json` → succeeded:false（Dart 级铁证，与 curl 探测一致）|
| 真实 GLM-4-flash GREEN（修复后） | ✅ `world.description="一个充满神秘和仙术的世界，修仙者们在这里追求长生不老。"` + `character personality="机智、勇敢、坚韧不拔"`，两者 aiCompleted；fence-strip + nesting + aiFill 全通 |
| canned template_completion_service_test | ✅ 5 测试全绿（flat-JSON 路径零回归）|
| 无 key | ✅ 优雅 skip（CI 安全）|

## 附带发现（prompt 行为，记为后续，非本修复范围）

GLM-4-flash 在 draft **部分预填**时倾向 **echo 空白**而非生成（probe：draft 含预填 name+空 description 时，
`[draft] description=''`）——全空白 draft（主 onboarding 场景：新作者从空模板开始）则可靠全填。这是与解析
鲁棒性**正交**的 prompt 质量问题（PUA：一次改一个关注点，不混入本解析修复）。aiFill「保留非空」语义由
canned 测试确定性覆盖，real-GLM 测试聚焦解析链路（全空白 draft）。

## 教训

- **第4条 LLM 结构化输出路径**——JSON 解析防御应是**全产品统一约定**（logic_guardian/guardian_check/
  editorial_review/template_completion 四路径已齐）。逐条真实 API 验证才能抓到裸 jsonDecode 这类漏网，
  canned fake-adapter 测试是结构性盲区（永远返回契约形状，不暴露 fence/嵌套）。
- **真实模型会 echo 输入 payload 结构**（把目标 shape 嵌在 envelope key 下），解析器不能假设 flat——
  需 shape-resolution 回退。这是 canned 测结构性盲区。
- **gap-analysis Phase 25「需外部 key/网络，本环境不可执行」**的漏网 bug 必须用真实 key 逐路径闭合——
  用户给 temp BigModel key 正是解锁此门。本路径修复让新故事 onboarding「AI 补全」在默认中国作者 provider
  上从「静默失败」变为「真正可用」。
- **测试名须诚实**：初版测试名含 "non-blank preserved" 但断言已移至 canned（real-GLM 改全空白 draft
  避混合 echo 抖动）——按项目反欺骗文化修正测试名匹配实际断言。
