---
slug: add-glm-preset
quick_id: 260618-1g3
status: in_progress
created: 2026-06-18
type: quick
---

# Add GLM/BigModel Preset Provider

## Background

真实 GLM API key（BigModel 智谱）已实测可用（journey 测试全过：fragment 合成 501 字、3 种开篇风格、30 章连写 13395 字 + Skill guardian 71 条偏差告警 + token 审计）。但 `preset_providers.dart` 只有 OpenAI/DeepSeek/Ollama/Claude 四个预设，**缺 GLM/BigModel**——而整个项目围绕 GLM 构建（journey 测试默认 GLM 端点，所有真实 API 验证都走 GLM）。用户每次配置 GLM 都要手填 baseUrl/model，这是真实体验缺口。

## Goal

新增 GLM/BigModel preset，用户一键预填（只需补 API key），与项目实际 AI 后端一致。

## Design Decision

- **GLM preset 复用 `AiProviderType.openai`**（不加新枚举值）。理由：
  1. GLM 暴露 OpenAI 兼容端点（journey_container.dart 已用 `AiProviderType.openai` 接 GLM 并全测试通过）
  2. 加 `glm` 枚举值会触动 JSON 序列化 / 适配器路由 / UI 类型选择器，disproportionate
  3. 与 DeepSeek 同理（DeepSeek 也是 OpenAI 兼容但独立枚举——DeepSeek 是历史既定；GLM 走 openai 更轻）
- baseUrl: `https://open.bigmodel.cn/api/paas/v4`（journey 测试默认值，实测端点）
- model: `glm-4-flash`（journey 默认，免费层稳定）

## Files

| File | Change |
|------|--------|
| `lib/features/ai/infrastructure/preset_providers.dart` | `PresetProviders.all` 末尾加 `preset-glm` 条目（type openai / GLM endpoint / glm-4-flash） |
| `test/features/ai/infrastructure/preset_providers_test.dart` | `all.length` 断言 4→5；加 GLM preset 配置断言 + `getById('preset-glm')` 断言 |

## UI Wiring (无需改)

- `provider_management_page_layout.dart:_buildLeftPanel` 已 `presets.map` 渲染所有 preset 卡片 + `_fillFromPreset` 回填——加进 `all` 即自动出现
- `provider_step_page.dart:58` onboarding 向导按 type 取 preset.firstOrNull，GLM 与 OpenAI 同 type 不冲突（OpenAI 在前）

## TDD Steps

1. **RED**: 更新测试（4→5 + GLM 断言块），跑测试预期失败（preset-glm 不存在 → firstWhere throws / count 仍 4）
2. **GREEN**: 加 GLM preset 到 `preset_providers.dart`
3. **VERIFY**: `flutter test test/features/ai/infrastructure/preset_providers_test.dart` + `flutter analyze`，零回归

## Verification Gates

- [ ] preset_providers_test.dart 全绿
- [ ] flutter analyze 零错误
- [ ] 无其他测试回归（preset 变更影响面仅 preset_providers_test）
