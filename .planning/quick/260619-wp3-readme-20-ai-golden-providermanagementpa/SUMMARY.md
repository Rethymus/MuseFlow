---
quick_id: 260619-wp3
slug: readme-20-ai-golden-providermanagementpa
date: 2026-06-19
status: complete
commits: [cdc15a6]
---

# README #20 AI 模型管理真实 golden — 交付

第 8 张真实截图：README #20「AI 模型管理」→ ProviderManagementPage。**配置簇完整闭合**
（15/16/17/18/19/20 全真实）。master/detail 布局（左 provider 列表+预设 / 右选中详情）。

## 实现

- build path watch providerManagementProvider（state）+ presetProvidersProvider（**纯
  Provider 返回 PresetProviders.all，无依赖，不需 override**）。仅 override
  providerManagementProvider 喂 seed state：3 真实配置 provider（GLM-4-Flash active /
  DeepSeek / Ollama 本地），isLoading=false（默认 true 会显示 spinner），selected=active。
  无真实 key（demo baseUrl）。
- ConsumerStatefulWidget 但 build 仅 watch 2 provider；CRUD action 内 ref.read 不触发。
- 断言用 findsAtLeastNWidgets(1) 规避 master/detail 同名双显（list+detail）计数风险。

## 验证（五重）

- ✅ 首跑 GREEN（findsAtLeastNWidgets 预防 + presetProviders 纯 provider 无需 override）
- ✅ golden 124184B→100727B
- ✅ PIL 1591色（迄今最富—master/detail 表单+图标+卡片）/95.7%dark/0.7%text
- ✅ 回归 +8 All tests passed!（01/15/16/17/18/19/20/21）
- ✅ analyze 0

## 教训

- **纯 Provider（无依赖）不需 override**：presetProvidersProvider 返回静态 PresetProviders.all，
  无 ref.watch 别的 provider → 直接用真实值，只 override 有状态/有依赖的 provider。
- **master/detail 同名计数**：选中项名字同时出现在左 list + 右 detail → find.text 用
  findsAtLeastNWidgets(1) 而非 findsOneWidget。

## 进度

已迁 **8/21**：01 / 15 / 16 / 17 / 18 / 19 / 20 / 21。**配置簇 + stats 簇全闭合**。
剩余 13 张（中复杂度：02 捕捉 / 06-09 知识模板 / 10-14 结构 / 03 AI整理 / 04-05 editor 极重）。

相关 [[golden-screenshot-migration-harness]]
