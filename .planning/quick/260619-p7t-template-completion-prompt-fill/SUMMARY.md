---
quick_id: 260619-p7t
slug: template-completion-prompt-fill
date: 2026-06-19
status: complete
commits: [9ea98e3]
---

# template_completion prompt 改进——强制空白字段生成（修复 partial-fill echo）

## 闭环

nwc（260619-nwc）修复了 template_completion 的 JSON 解析（fence + nesting），但附带发现：GLM-4-flash
在 draft **部分预填**时倾向 **echo 空白**而非生成。p7t curl 严谨确认（探测 4 次）：
- **现有 prompt ×2**（partial-fill：name/rules/backstory 预填，其余空白）→ 两 run 全部
  `world.description=''` + `char.personality=''`（echo 空白）。**echo 一致复现 2/2，非 fluke**。

**这命中真实用户流程**：用户选模板（修仙模板自带默认 name/rules）→ 编辑几个字段 → 点「AI 补全」→
draft 必然部分预填 → 命中 echo → 空白字段填不上。nwc 的全空白测试刻意绕过了它（为避免混合 echo
抖动）。这是核心 onboarding 路径的**生成质量缺陷**（与 nwc 解析 bug 正交，PUA：一次一个关注点故拆独立 quick）。

## 方案（改进 system prompt + temperature 0.3，curl 探测 proven）

**改进 prompt ×2**（同 partial-fill draft）→ 两 run 全部：
- `world.description` 富生成（"青云界是一个充满神秘与奇遇的修仙世界..."）
- `char.personality` 富生成（"林风性格坚毅..."）
- `world.name='青云界'` **保留**（预填值不动）
- `top_keys=['world','characters']` **flat 顶层**（破 nesting，bonus）

三处加强（探测 proven）：①强制生成「为【值为空】的字段生成…禁止返回空字符串/原样复制输入」
②明确保留「已有值字段保持原值不变」③输出契约「顶层 {world,characters}，不包裹 draft/responseShape」。

**附带修 temperature**：改进 prompt 初次跑 all-blank 用例时 1 次 `FormatException char 772`（JSON 中途
畸形）。curl 探测 all-blank 2/2 GREEN 证非系统性→**模型非确定性 flake**（高 temp 偶发未转义引号/截断）。
根因：生产 `createStream` 不传 temperature（GLM 默认 ~0.7-0.9）。对齐 `logic_guardian`/`guardian_check`
结构化 JSON 服务用 **temperature: 0.3**（低 temp 降畸形概率，真实用户受益+提测试可靠性）。canned 走
`completionStream` 旁路 createStream 不受影响。

canned 测试走 `completionStream` 旁路 `_buildMessages`（不调 LLM）→ 改 prompt/temperature 零影响 canned。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter analyze`（全项目） | 0 issues |
| TDD 探测 | ✅ 现有 prompt echo 2/2 / 改进 prompt 生成 2/2（curl 证据）|
| real-GLM all-blank（回归） | ✅ GREEN——world.description+personality 填充 aiCompleted |
| real-GLM partial-fill（新增，真实用户流程） | ✅ GREEN——空白字段填充 aiCompleted + 预填 name '青云界' templateDefault 保留 + backstory '出身寒微' userEdited 保留 |
| 可靠性 | ✅ 连续 2 次全跑 4/4 GREEN（temp 0.3 消除 char-772 畸形 flake）|
| canned template_completion_service_test | ✅ 5 测试零回归 |
| 无 key | ✅ 优雅 skip（CI 安全）|

## 教训

- **prompt 工程需 curl 探测验证**——"只补全空白字段"被 GLM 误解为 echo，改进措辞 + 负向约束（禁止返空/
  复制）+ 显式输出契约才可靠。逐条 curl 探测 before coding 是 PUA 证据驱动。
- **真实用户流程 ≠ 测试用例**——全空白 draft 是 nwc 测试简化，但真实流程是部分预填（模板默认值）。测试须
  覆盖真实场景（partial-fill），否则像 nwc 一样绕过缺陷。
- **echo + nesting 同源于「模型 echo 输入 payload」**——prompt 显式输出契约（顶层结构 + 禁包裹）一举破两者。
- **结构化 JSON 调用须低 temperature**——高 temp 偶发 JSON 中途畸形（未转义引号/截断），0.3 对齐 guardians
  既有约定降概率。flaky 测试比没测试更糟，须连跑确认可靠性。
