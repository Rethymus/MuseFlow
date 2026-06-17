---
slug: add-glm-preset
quick_id: 260618-1g3
status: complete
created: 2026-06-18
completed: 2026-06-18
type: quick
---

# Add GLM/BigModel Preset Provider — Summary

## Outcome ✅

新增 GLM/BigModel (智谱) preset provider，并修复该 preset 暴露的左面板溢出 bug。真实 GLM API key 端到端验证全过。

## What Changed

| File | Change |
|------|--------|
| `lib/features/ai/infrastructure/preset_providers.dart` | `PresetProviders.all` 末尾加 `preset-glm`（name 'GLM (智谱)'、baseUrl `https://open.bigmodel.cn/api/paas/v4`、type `AiProviderType.openai` 复用 OpenAI 兼容适配器、model `glm-4-flash`）+ 文档注释更新 |
| `test/features/ai/infrastructure/preset_providers_test.dart` | `all.length` 4→5；加 GLM preset 配置断言 + `requiresApiKey` 断言（TDD RED→GREEN） |
| `lib/features/ai/presentation/provider_management_page_layout.dart` | **修复溢出 bug**：第 5 个 preset 卡片导致左面板 Column 底部溢出 78px（600px 宽断点）。把预设卡片+自定义包进 `Expanded(SingleChildScrollView(Column))`，与"已配置"区同样可滚动，预设增多不再溢出 |

## Design Decision

- **GLM preset 复用 `AiProviderType.openai`**（不加新枚举值）。GLM 暴露 OpenAI 兼容端点，journey_container.dart 真实 API harness 已用此 wiring 全测试通过。加 `glm` 枚举值会触动 JSON 序列化/适配器路由/UI 选择器，disproportionate。
- preset 配置（baseUrl/model/type）与 Task #1 真实 API 验证用的 journey 配置**逐字一致** → preset 正确性已被真实 GLM API 调用证明。

## UI Wiring（无需改）

`provider_management_page_layout._buildLeftPanel` 已 `presets.map` 渲染所有 preset 卡片 + `_fillFromPreset` 回填 name/baseUrl/model → 加进 `all` 即自动出现在 provider 管理页和 onboarding 向导，用户只需补 API key。

## TDD

- RED: 改测试后跑（preset-glm 不存在 → count=4 非 5、getById 返回 null），3 失败符合预期
- GREEN: 加 GLM preset → preset_providers_test 15/15 全过
- analyze: No issues found

## Verification

- `flutter test test/features/ai/infrastructure/preset_providers_test.dart` → **15/15 passed** (+2 GLM)
- `flutter test test/features/ai/presentation/provider_management_responsive_test.dart` → **2/2 passed**（修复后；修复前 600px 断点溢出失败）
- 全 AI 目录回归 `test/features/ai/` → **+311 -2**，零新增失败（详见下方预存遗留）
- `flutter analyze`（3 个改动文件）→ No issues found

## 预存遗留（NOT 引入，记录在案）

`openai_adapter_test.dart` 2 个 client caching 测试（reuse / dispose-old）失败，**clean HEAD 上即红**（git stash 对照确认），与本次改动无关：
- 实战已证成：Task #1 真实 GLM journey 测试连写 30 章（大量 createStream 复用）全过，证明客户端缓存在真实场景正常工作
- 判定为测试断言层面预存遗留（非真实 bug），按"一次只改一个关注点"原则不混入本次提交，留后续单独 quick 任务处理

## 真实 API 验证证据（Task #1）

用临时 BigModel key（GLM-4-flash）跑通 3 个 journey 集成测试：
- fragment_synthesis：碎片创建 + PromptPipeline + **真实流式合成 501 字** + 知识注入 ✅
- opening_guide：3 种开篇风格（场景/人物/悬念切入）真实生成 + 风格差异化 ✅
- serial_generation：**30 章连写 13395 字**（均 446）+ 知识注入跨章一致 + Skill guardian **71 条真实剧情偏差告警**（练气期违规使用火系法术/神识/筑基/御剑飞行）+ token 审计（30 调用，输入 17268 + 输出 9905）+ D-11 截断守卫 ✅
