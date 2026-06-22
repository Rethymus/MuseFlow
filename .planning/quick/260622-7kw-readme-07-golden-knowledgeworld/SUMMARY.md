---
quick_id: 260622-7kw
slug: readme-07-golden-knowledgeworld
date: 2026-06-22
status: complete
commits: []
---

# README #07 世界观真实 golden — 交付

第 11 张真实截图：README #07「世界观」→ KnowledgeBasePage 世界观 tab（**复用 #06 同页**，
切到 tab 1）。知识库簇第 2 张，零模式改动验证 harness 跨 tab 复用成立。

## 实现

- 与 #06 同一 KnowledgeBasePage，自带 Scaffold。区别仅在：
  - override `worldSettingNotifierProvider`（非 characterCard）喂 4 世界观 seed
    （青云界/弃剑峰/雾海禁地/戒律堂，对齐 README 运行样本）。
  - **tab 切换**：默认 tab 0=角色卡，#07 需 tab 1=世界观 → `tester.tap(find.text('世界观'))`
    + `pumpAndSettle` 驱动 TabBarView 滑动动画到完成。
- `_WorldSettingTile` 同样嵌套 watch chapterNotifierProvider（staleness）→ override 空列表全 fresh。
- WorldSetting 字段：name/description/rules/factions/geography/techLevel，seed 用 4 字段（desc/rules/geography）。
- 固定 DateTime createdAt。

## 验证（六重）

- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（**tab-tap 动画确定性**——pumpAndSettle 完成滑动，2 次像素一致，无 #02 式 flake）
- ✅ golden 49758B
- ✅ PIL 771 色 / 98.7%dark / 0.3%text（与 #06 列表页同量级，find.text 四重断言证入树）
- ✅ full-suite +11 All tests passed!（含 #07）
- ✅ analyze 0
- ✅ README 双语 disclosure 4 处加入「世界观(7)/World settings(7)」

## 教训

- **TabBarView tab 切换可确定性截图**：tap tab label + pumpAndSettle，滑动动画完成后稳定
  （2 次 clean GREEN 像素一致）。tab 控制器内化于 State 无法注入 index，tap 是唯一外部驱动。
- **同页多 tab 复用 harness 零改动**：#06/#07 同 KnowledgeBasePage，仅 override 不同 provider +
  tab 选择差异，验证 harness 跨截图复用成立。

## 进度

已迁 **11/21**：01 / 02 / 06 / **07** / 15 / 16 / 17 / 18 / 19 / 20 / 21。**知识库簇 06/07 闭合**。
剩余 10 张：03 AI整理 / 08 模板 / 09 技能 / 10 伏笔 / 11 时间线 / 12 故事弧 / 13 逻辑守护 /
14 导出 / 04-05 editor（极重 appflowy）。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
