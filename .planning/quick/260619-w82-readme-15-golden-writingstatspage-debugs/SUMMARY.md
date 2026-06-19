---
quick_id: 260619-w82
slug: readme-15-golden-writingstatspage-debugs
date: 2026-06-19
status: complete
commits: [9e4d8cc]
---

# README #15 写作统计真实 golden — 交付

第 6 张真实截图：README #15「写作统计」。含 3 子系统的复杂页，用混合形态：
debugSnapshot（短路 writingStats provider）+ tokenAudit override（让 token 卡片真实渲染）。

## 验证（五重）

- ✅ GREEN（import 修复后首过）
- ✅ golden 131471B→67447B
- ✅ PIL 759色/97.3%dark/2.0%text 真实暗色 UI
- ✅ 回归 +6 All tests passed!（01/15/16/17/18/21）
- ✅ analyze 0

## 新教训（补 harness 记忆）

1. **含子 ConsumerWidget 的页**：父 debugSnapshot 只短路父 provider；子 widget 若 watch
   别的 provider 仍需 override（或接受其 loading/error→SizedBox.shrink 空态）。
2. **import part-file 陷阱**：core/presentation/providers_*.dart 都是 `part of providers.dart`
   → 消费方 import providers.dart 父库（非 providers_stats.dart，否则 Undefined）；
   notifier 类常在 features/.../application/ 需单独 import 才能 subclass。

## 进度

已迁 6/21：01 文稿库 / 15 写作统计 / 16 Token审计 / 17 分析报告 / 18 报告详情 / 21 AI用语过滤。
stats 簇（15/16/18）完整闭合。剩余 15 张。

相关 [[golden-screenshot-migration-harness]]
