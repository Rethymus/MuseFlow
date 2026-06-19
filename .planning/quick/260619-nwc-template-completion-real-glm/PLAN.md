---
quick_id: 260619-nwc
slug: template-completion-real-glm
date: 2026-06-19
status: complete
---

# template_completion 真实 GLM 验证 + JSON 防御解析（闭合第4条 LLM 结构化 JSON 输出 gap）

## 触发：新故事脚手架「AI 补全」核心 onboarding 路径在真实 GLM-4-flash 下完全失败

ea1/ea2/ea3 闭合 editor AI 三大 LLM 输出路径真实覆盖后，穷尽侦察第4个独立零真实覆盖路径：
`TemplateCompletionService`（新故事模板脚手架，`template_draft_page` 的「AI 补全」按钮）要求**严格 JSON**
（world + characters 结构），却用**裸 `jsonDecode(buffer.toString())`（line 83）零防御解析**。canned 测试
喂干净 flat JSON via `completionStream`——完全漏掉真实模型行为。

curl 双重确认 GLM-4-flash 真实输出**双重失败**：
- **(A) fence 包裹 100%**：` ```json ... ``` ` 包裹 → 裸 jsonDecode 抛 `FormatException: Expecting value:
  line 1 column 1 (char 0)` → `succeeded:false` → 用户点「AI 补全」静默失败。
- **(B) 嵌套 echo**：模型把 `world`/`characters` 嵌在 `draft`/`responseShape` 下返回（echo 输入 payload
  结构），`_applyCompletion` 读**顶层** `json['world']`/`json['characters']` → null → 即便修 fence 也
  "succeeded:true 但填不上任何字段"。

与 ea2/ea3 同脆弱类（LLM 结构化 JSON 输出最易翻车），但 template_completion 是**同类中唯一零防御**
的——logic_guardian/guardian_check/editorial_review 都已有 `_extractJson`/`parseFromLLM`。这是用 temp
BigModel key 解锁的 gap-analysis Phase 25「真实 API E2E」漏网 bug。

## 方案（构造注入 + 双重防御，对齐既有 _extractJson/parseFromLLM 模式）

`TemplateCompletionService` 构造注入（openAIAdapter/apiKey/baseUrl/model 直接传）→ 真实测试最简洁，
镜像 ea3。修复两处：

1. **`_extractJsonObject` 防御解析**（strip fence + 隔离首个 `{...}`）：line 83 `jsonDecode(raw)` →
   `jsonDecode(_extractJsonObject(raw))`。镜像 logic_guardian.dart:139 / guardian_check_service.dart:208
   的 `_extractJson`（数组改对象版）。
2. **`_resolveShape` nesting 回退**：`_applyCompletion` 开头 `final shape = _resolveShape(json)` → 顶层
   优先（既有契约），回退 `draft` → `responseShape`（真实模型 echo payload 结构）。
3. **env-gated real-GLM 测试**：断言 `result.succeeded && world.description 非空 + aiCompleted`（端到端
   验证 fence-strip + nesting + aiFill「只填空白」语义全通）。无 key 优雅 skip。

canned 测试 flat 顶层 JSON 走 `_resolveShape` 第一分支 + `_extractJsonObject` 无 fence 直返 → 零回归。

## 验证（证据）

- analyze 0
- 真实 GLM-4-flash GREEN：completion 真正 APPLY（world.description 非空 + aiCompleted / world.name
  '模板世界' preserved / character personality 填充 / backstory '用户背景' preserved）
- TDD：先 RED（未修代码跑测试 → succeeded:false 证 fence bug），再 GREEN
- canned template_completion_service_test 全绿（零行为回归）
- 无 key 优雅 skip（CI 安全）

## 教训

- 第4条 LLM 结构化输出路径——JSON 解析防御应是**全产品统一约定**（logic_guardian/guardian_check/
  editorial_review/template_completion），逐条真实 API 验证才能抓到裸 jsonDecode 这类漏网
- 真实模型会 **echo 输入 payload 结构**（把目标 shape 嵌在 envelope key 下），解析器不能假设 flat——
  需 shape-resolution 回退。这是 canned 测试结构性盲区（fake adapter 永远返回契约形状）
- gap-analysis Phase 25「需外部 key/网络，本环境不可执行」的漏网 bug 必须用真实 key 逐路径闭合
