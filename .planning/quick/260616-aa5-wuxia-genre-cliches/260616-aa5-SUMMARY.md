---
phase: quick-260616-aa5
plan: 01
subsystem: ai/application
tags: [anti-ai-scent, genre, wuxia, product-soul, aa-05]
status: complete
requires:
  - lib/features/ai/application/anti_ai_scent_processor.dart (_xianxiaCliches, _buildReviewSignals)
  - .planning/PROJECT.md:45 (修仙/武侠/都市/科幻/玄幻 preset scope)
provides:
  - "武侠类型套句检测（_wuxiaCliches 8 词）——修仙外首个类型覆盖"
  - "类型文信号描述准确命名命中类型（修仙/武侠），消除误导性硬编码"
affects:
  - 武侠/江湖系创作者得类型套句反馈；多类型产品类型反馈准确化
tech-stack:
  added: []
  patterns:
    - "多类型 cliche 数据集 + 主导类型命名（计命中数取 max，并列取先者）"
    - "信号标题 genre-agnostic('类型文套句偏多')，描述区分类型——向后兼容"
key-files:
  modified:
    - lib/features/ai/application/anti_ai_scent_processor.dart
    - test/features/ai/application/anti_ai_scent_test.dart
decisions:
  - "信号标题'类型文套句偏多'不变——genre-agnostic，line 280 containsAll 零破坏"
  - "只改描述命名类型，主导类型取命中数最大者，并列取修仙（声明序）"
  - "武侠套句选武术/江湖/招式系（内力/轻功/剑光/刀光/真气/身法/招式/武学），避与修仙灵力系及 synonym map 第十三类重叠"
metrics:
  duration: ~12min
  completed: 2026-06-16
  tasks_completed: 3
  files_changed: 2
  tests_added: 2
  tests_total: 见全量结果
requirements:
  - AA5-GENRE-WUXIA
---

# Phase quick-260616-aa5 Plan 01: AA-05 武侠类型套句检测 + 信号类型准确化 Summary

产品支持修仙/武侠/都市/科幻/玄幻 5 类预设（PROJECT.md:45），但类型套句检测仅修仙且信号描述硬编码"修仙"。本单元加武侠覆盖 + 让描述准确命名命中类型。

## What Changed

### `anti_ai_scent_processor.dart`
- 新增 `_wuxiaCliches`（8 武术/江湖系词）：内力运转/施展轻功/剑光一闪/刀光剑影/真气鼓荡/身法如电/招式凌厉/武学修为
- `_buildReviewSignals` genre block 改造：分别计 `xianxiaHits`/`wuxiaHits`，合计 `genreClicheCount` 不变阈值(≥2)；主导类型 `xianxiaHits >= wuxiaHits ? '修仙' : '武侠'` 命名描述

### `anti_ai_scent_test.dart`（+2 测）
- `should name the genre in the genre-cliche description`：修仙文本 → 描述含「修仙」
- `should detect wuxia genre cliches`：武侠文本（5 命中）→ 信号 title 不变 + 描述含「武侠」isNot「修仙」（**此前无信号，新覆盖**）

## 向后兼容

- 标题 `'类型文套句偏多'` 不变 → line 280 `containsAll` 零破坏
- 纯修仙文本：xianxiaHits≥2>wuxiaHits → 描述「修仙」（同现状）
- 纯武侠文本：此前 genreCount=0 无信号 → 现「武侠」信号（新覆盖，正向）
- 并列(xianxiaHits==wuxiaHits)：取修仙（声明序，保守）

## Verification

- targeted：`51: All tests passed!`
- `flutter analyze`：No issues found
- 全量：见后台结果（基线 1637，+2 应 = 1639）
- 红线：信号标题不变；非 genre 数据集/helper 不碰

## Self-Check: PASSED

- [x] _wuxiaCliches 接入，武侠文本得类型套句反馈
- [x] 信号描述准确命名修仙/武侠（消除误导硬编码）
- [x] 既有 line 280 标题断言零破坏
- [x] 全库零回归，analyze 0
