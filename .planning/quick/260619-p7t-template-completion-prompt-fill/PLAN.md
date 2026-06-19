---
quick_id: 260619-p7t
slug: template-completion-prompt-fill
date: 2026-06-19
status: complete
---

# template_completion prompt 改进——强制空白字段生成（修复 partial-fill echo）

## 触发：nwc 附带发现，echo 命中真实用户流程

nwc（260619-nwc）修复了 template_completion 的 JSON 解析（fence + nesting），但附带发现：GLM-4-flash
在 draft **部分预填**时倾向 **echo 空白**而非生成。curl 严谨确认（p7t 探测）：
- **现有 prompt ×2**：partial-fill draft（name/rules/backstory 预填，其余空白）→ 两 run 全部
  `world.description=''` + `char.personality=''`（echo 空白）。**echo 一致复现（2/2），非 fluke**。

**这命中真实用户流程**：用户选模板（修仙模板自带默认 name/rules 等）→ 编辑几个字段 → 点「AI 补全」
→ draft 必然部分预填 → 命中 echo → 空白字段填不上。nwc 的全空白测试刻意绕过了它。这是核心 onboarding
路径的**生成质量缺陷**（与 nwc 解析 bug 正交，PUA：一次一个关注点故拆为独立 quick task）。

## 方案（改进 system prompt，curl 探测已验证有效）

**改进 prompt ×2**（同 partial-fill draft）→ 两 run 全部：
- `world.description` 富生成（"青云界是一个充满神秘与奇遇的修仙世界..."）
- `char.personality` 富生成（"林风性格坚毅..."）
- `world.name='青云界'` **保留**（预填值不动）
- `top_keys=['world','characters']` **flat 顶层**（破 nesting，bonus）

三处加强（探测 proven）：
1. 强制生成：「为【值为空】的字段生成具体、丰富的中文内容，每处空白都必须填入生成的设定，
   禁止返回空字符串，禁止原样复制输入」
2. 明确保留：「已有值的字段（name/rules/backstory 等）保持原值不变」
3. 输出契约：「输出顶层 {world, characters}，不要包裹在 draft 或 responseShape 键下」

canned 测试走 `completionStream` 旁路 `_buildMessages`（不调 LLM）→ 改 prompt 零影响 canned。
`_resolveShape`/`_extractJsonObject`（nwc）保留——defense-in-depth，prompt 改进让 flat-output 成
common case，防御解析兜底模型 variance。

## 验证（证据）

- analyze 0
- TDD：现有 all-blank real-GLM 测试改 prompt 后仍 GREEN（回归）；新增 partial-fill real-GLM 测试
  GREEN（空白字段填充 aiCompleted + 预填字段保留）
- canned template_completion_service_test 5 测试零回归
- 无 key 优雅 skip

## 教训

- **prompt 工程需 curl 探测验证**——"只补全空白字段"被 GLM 误解为 echo，改进措辞 + 负向约束（禁止
  返空/复制）+ 显式输出契约才可靠。逐条 curl 探测 before coding 是 PUA 证据驱动。
- **真实用户流程 ≠ 测试用例**——全空白 draft 是 nwc 的测试简化，但真实流程是部分预填（模板默认值）。
  测试须覆盖真实场景（partial-fill），否则像 nwc 一样绕过缺陷。
- echo + nesting 同源于「模型 echo 输入 payload」——prompt 显式输出契约（顶层结构 + 禁包裹）一举破两者。
