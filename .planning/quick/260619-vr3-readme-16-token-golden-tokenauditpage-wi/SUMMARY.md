---
quick_id: 260619-vr3
slug: readme-16-token-golden-tokenauditpage-wi
date: 2026-06-19
status: complete
commits: [92b44c3]
---

# README #16 Token 审计真实 golden — 交付

## 结果

第 5 张真实截图迁移：README #16「Token 审计」→ `token_audit_page.dart`。
**首跑即 GREEN**（v0w「断言首核真实计数」教训兑现，零迭代）。

## 关键发现：最简迁移形态

`TokenAuditPage` 有测试专用构造函数 `TokenAuditPage.withSnapshot(snapshot)`
（debugSnapshot 字段短路 provider 链）→ 无需 ProviderScope override，比 v0w
（override 单 provider）更简。**迁移前先 grep 探测 withSnapshot/debug/factory**。

## seed 诚实性升级

不凭空写 totals（mockup 编造 62400/31200/128），而是构造 15 条 TokenAuditRecord
（3 章节 × 5 操作类型 × 7 天），totals 从 records **fold 计算**得出 → summary cards
与 3 charts 数据自洽，反映真实 TokenAuditRepository 聚合。timestamp 用固定偏移
保证 trend chart 点间距确定。

## 验证（五重证据）

- ✅ 首跑 --update-goldens GREEN（零迭代，断言首核计数正确）
- ✅ golden 125258B(mockup)→67080B(真实)
- ✅ PIL 1440×1000 / 1210 colors / 96.7% dark / 2.7% text = 真实暗色 Flutter UI
- ✅ 回归 +5 All tests passed!（01/16/17/18/21 五张确定性匹配，新页不破坏既有）
- ✅ analyze 0

## 教训

页面若有测试构造函数优先用（withSnapshot/debugSnapshot）→ 比 provider override 更简，
免 ProviderScope。seed 从数据计算 totals > 凭空写数（summary+charts 自洽，诚实反映真实聚合）。

## 进度

已迁 5/21：01 文稿库 / 16 Token 审计 / 17 分析报告 / 18 报告详情 / 21 AI 用语过滤。
剩余 16 张分级见 [[golden-screenshot-migration-harness]]。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
