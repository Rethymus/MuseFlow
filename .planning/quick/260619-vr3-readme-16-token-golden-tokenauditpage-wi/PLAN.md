---
quick_id: 260619-vr3
slug: readme-16-token-golden-tokenauditpage-wi
date: 2026-06-19
status: complete
---

# README #16 Token 审计真实 golden 截图

## 触发

v0w 迁 #18 后继续 golden 截图迁移第 5 张：README #16「Token 审计」→
`token_audit_page.dart`。这是 v0w 同主题延续（Token 成本故事），且发现比 v0w
更简的迁移形态。

## 侦察（v0w 教训前置应用，零迭代）

- **最简形态发现**：`TokenAuditPage` 有专门的 **`TokenAuditPage.withSnapshot(snapshot)`
  测试构造函数**（debugSnapshot 字段短路 provider 链）→ 无需 ProviderScope override，
  比 v0w（override 单 provider）更简，接近 reports-hub 的直接 pump。
- **3 图表确定性**：grep 确认 ChapterTokenBarChart / OperationTypePieChart /
  TokenTrendLineChart 零 AnimationController/Tween/Random/DateTime.now → golden 稳定。
- **seed 内部一致（诚实）**：不像 mockup 凭空写 62400/31200/128，而是构造 15 条
  TokenAuditRecord（3 章节 × 5 操作类型 × 7 天），totals 从 records **计算**得出
  （fold 求和 + length）→ summary cards 与 charts 数据自洽，反映真实 snapshot 聚合。
- **timestamp 确定性**：用 now.subtract(Duration(days:N, hours:i)) 固定偏移，
  trend chart 点间距确定不随壁钟漂移。
- **断言首核计数（v0w 教训）**：'Token 消耗总览' AppBar+headline=2（findsNWidgets），
  '每章 Token 分布' 唯一 chart title=1（findsOneWidget，fold 上）；fold 下 2/3 chart 不断言。
- **子集覆盖**：universal 子集覆盖该页 42 CJK 字符 0-missing（pyftsubset 验证）。

## 方案

1. 新建 `test/readme_screenshots/token_audit_test.dart`：FontLoader 通用子集 + 1440×1000
   + `TokenAuditPage.withSnapshot(_buildSeedSnapshot())` + matchesGoldenFile docs/16。
2. `_buildSeedSnapshot()` 构造 15 records（spec 元组驱动）+ fold 算 totals。
3. --update-goldens 生成 + 回归确认 + PIL + 字节 + README zh/en 4 处披露。

## 验证（首跑即 GREEN，v0w 教训兑现）

- ✅ 首跑 --update-goldens GREEN（零迭代，断言首核计数正确）
- ✅ golden 生成：16-token-audit.png 125258B(mockup)→67080B(真实)
- ✅ PIL：1440×1000 / 1210 colors / 96.7% dark / 2.7% text = 真实暗色 UI
- ✅ 回归 +5 All tests passed!（01/16/17/18/21 五张确定性）
- ✅ analyze 0

## 教训

- **页面若有测试构造函数优先用**（withSnapshot/debugSnapshot）→ 比 provider override
  更简，免 ProviderScope。迁移前先 grep `withSnapshot`/`debug`/`factory` 探测。
- **seed 从数据计算 totals > 凭空写数**（诚实）：records 驱动 summary+charts 自洽，
  反映真实聚合而非 mockup 编造。
- v0w「断言首核真实计数」教训兑现：本次零迭代首跑 GREEN。

## 相关
[[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
