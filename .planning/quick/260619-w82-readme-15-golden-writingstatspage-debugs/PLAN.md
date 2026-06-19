---
quick_id: 260619-w82
slug: readme-15-golden-writingstatspage-debugs
date: 2026-06-19
status: complete
---

# README #15 写作统计真实 golden 截图

## 触发

vr3 迁 #16 后继续第 6 张：README #15「写作统计」→ `writing_stats_page.dart`。
延续 stats 主题簇（15/16/18）。该页有 3 个子系统（writing stats / token summary /
achievement badges），比前几张复杂——采用 debugSnapshot + tokenAudit override 混合形态。

## 侦察

- **debugSnapshot 构造函数**：`WritingStatsPage({this.debugSnapshot})` 短路
  writingStatsNotifierProvider，但 `_TokenSummarySection`（子 ConsumerWidget）仍 watch
  tokenAuditNotifierProvider（loading/error→SizedBox.shrink）；`AchievementBadgeSection`
  debug 模式 debugBadges=[] 渲染空态提示。
- **混合形态**：WritingStatsPage(debugSnapshot: statsSeed) + ProviderScope override
  tokenAuditNotifierProvider 喂 seed（让 token 卡片真实渲染，faithful 而非空态）。
- **import 陷阱 ×2**（踩到，记后续）：① providers_stats.dart 是 `part of providers.dart`
  → 须 import 父库 providers.dart 非 providers_stats.dart（否则 TokenAuditNotifier/
  AsyncNotifierProvider 全 Undefined）② TokenAuditNotifier 类在
  features/stats/application/token_audit_notifier.dart（非 providers 文件）→ subclass
  须单独 import（否则 Type not found）。
- **3 图表确定性**：DailyWordsBarChart/SpeedTrendLineChart/AIUsagePieChart grep 零动画零随机；
  charts 不解析 dateKey（用 list index），格式无关。
- **seed 内部一致（诚实）**：StatsSnapshot totals 从 14 天 daily 列表 fold 计算
  （humanUnits/aiUnits/editSeconds），aiAssistRatio≈22.5%（aiUnits/totalUnits）；
  token seed 6 records fold 算 totals。
- **断言首核计数**：'写作统计' AppBar+headline=2，'每日字数' 唯一 chart title=1（fold 上）。

## 验证（五重）

- ✅ GREEN（import 修复后）
- ✅ golden 131471B(mockup)→67447B(真实)
- ✅ PIL 1440×1000 / 759 colors / 97.3% dark / 2.0% text = 真实暗色 UI
- ✅ 回归 +6 All tests passed!（01/15/16/17/18/21 六张确定性）
- ✅ analyze 0

## 教训（新增，补 harness 记忆）

**迁移含子 ConsumerWidget 的页**：父页 debugSnapshot 只短路父 provider，子 widget 若
watch 别的 provider 仍需 override（或接受其 loading/error 空态）。**import part-file 陷阱**：
core/presentation/providers_*.dart 都是 `part of providers.dart`，消费方 import providers.dart
父库；notifier 类常在 features/.../application/ 需单独 import 才能 subclass。

相关 [[golden-screenshot-migration-harness]]
