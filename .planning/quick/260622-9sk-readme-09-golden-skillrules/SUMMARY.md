---
quick_id: 260622-9sk
slug: readme-09-golden-skillrules
date: 2026-06-22
status: complete
commits: []
---

# README #09 Skill 规则真实 golden — 交付

第 12 张真实截图：README #09「Skill 规则」→ SkillListPage（AppBar「世界观模板」+ 4 skill 卡
（图标+名+描述/sections+isActive Switch+删除按钮）+ FAB）。**ConsumerWidget + 单 provider**——
迄今最简形态。

## 实现

- SkillListPage 是 ConsumerWidget，自带 Scaffold，watch **单一** skillListNotifierProvider
  （`AsyncNotifierProvider<SkillListNotifier, List<SkillDocument>>`）。_SkillTile 无其他 provider
  依赖（无 chapterNotifier staleness）→ 仅 override 一个 provider。
- seed 4 修仙 skill：修仙境界体系（**isActive=true** 展示开关激活态真实）、门派势力图谱、
  力量规则与禁制、禁忌与术语表。每个 SkillSections 填一个 section 字段（powerHierarchy/
  factionRelations/rules/taboos+terminology）反映真实结构。
- 踩坑：SkillSections **非 const 构造** → `const SkillSections(...)` 编译失败，去 const。
- 固定 DateTime createdAt（#02 习惯）。

## 验证（六重）

- ✅ analyze 0（修 SkillSections 非 const + doc comment 尖括号）
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（确定性）
- ✅ golden 129102B(mockup)→68413B(真实)
- ✅ PIL 794 色 / 98.7%dark / 0.5%text（Switch+图标+卡片，find.text 三重断言证入树）
- ✅ full-suite +12 All tests passed!
- ✅ README 双语 disclosure 4 处加入「Skill 规则(9)/Skill rules(9)」

## 教训

- **ConsumerWidget + 单 provider 是最简迁移形态**：无嵌套 provider、无 Scaffold 宿主问题、
  无 tab 交互——override 一个 provider 直接 pump。
- **domain ctor 未必 const**：SkillSections 非 const，seed 字面量不可加 const；遇 const_with_non_const
  编译错即去 const。
- **doc comment 跨行 backtick 内尖括号仍触发 lint**：`<X, Y>` 泛型须单行 backtick 或删除泛型注解。

## 进度

已迁 **12/21**：01 / 02 / 06 / 07 / **09** / 15 / 16 / 17 / 18 / 19 / 20 / 21。
知识库簇 06/07/09 闭合（08 模板库因 WorldTemplate 重模型 deferred）。剩余 9 张：
03 AI整理 / 08 模板 / 10 伏笔 / 11 时间线 / 12 故事弧 / 13 逻辑守护 / 14 导出 / 04-05 editor。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
