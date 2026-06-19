---
quick_id: 260619-v0w
slug: readme-18-golden-failures-gitignore
date: 2026-06-19
status: in-progress
---

# README #18 报告详情真实 golden 截图 + failures/ gitignore 泄漏修复

## 触发

rs1/rs2/rs3 已迁 3 张灵魂/枢纽页（01 文稿库 / 21 AI用语过滤 / 17 分析报告）。
继续逐页迁移第 4 张：README #18「报告详情」→ `token_cost_report_page.dart`
（Token 消耗分析 + 50万字长篇推算 + 优化建议）。附带 owner 清理 golden 测试
`failures/` 产物未 gitignore 的工作树泄漏。

## 侦察（已用证据验证，PUA 先诊断后行动）

- **目标页**：`lib/features/reports/presentation/token_cost_report_page.dart` —
  `ConsumerWidget`，watch 单一 `tokenCostReportProvider`
  （`AsyncNotifierProvider<TokenCostReportNotifier, TokenCostReport>`），ref=1。
  渲染：4 StatsSummaryCard（输入/输出Token/调用次数/实际字数）+ OperationTypePieChart
  （按操作类型分布）+ CostProjectionChart（50万字推算）+ 优化建议 ListTile。
- **provider 可 override**：`TokenCostReportNotifier extends AsyncNotifier<TokenCostReport>`
  手写非生成式 → 镜像 rs1 `_SeededManuscriptNotifier` 模式，子类化 build() 返回固定 seed。
- **域 TokenCostReport** 全 required 字段：totalInputTokens/totalOutputTokens/totalCalls/
  actualWordCount/costByType(Map<AuditOperationType,int>)/costByChapter/projection/
  optimizationSuggestions。projection 同构（target/multiplier/est×4/low/high）。
- **子集已覆盖**（rs3 通用 GB2312 子集 2.9MB）：token_cost_report_page 46 CJK 字符 0 missing
  → 无需重子集化，rs3「永不漂移」设计生效。两图表零动画零随机（grep 确认无
  AnimationController/Tween/Random/DateTime.now）→ golden 确定性。
- **README #18 映射验证**：mockup 内容「预估 Token 4.68M / 50万字长篇推算 / 优化建议 /
  导出动作」精确对应 token_cost_report_page（reports_hub 的 Token 成本详情页）。

## 方案

### Part A — README #18 真实 golden

1. 新建 `test/readme_screenshots/token_cost_report_test.dart`，镜像 rs1 harness：
   - setUpAll FontLoader 注册 `test_assets/noto_sans_sc_subset.ttf`（通用子集）
   - tester.view 1440×1000 @ DPR1
   - ProviderScope override `tokenCostReportProvider.overrideWith(() => _Seeded(seed))`
   - MaterialApp(home: TokenCostReportPage(), theme: _screenshotTheme() 复用 rs1 内联暗色)
   - find.text 断言（'Token 消耗分析' / '50万字长篇推算' / '优化建议'）证数据真入树
   - matchesGoldenFile('../../docs/readme/screenshots/18-report-details.png')
   - 内联 `_SeededTokenCostReportNotifier extends TokenCostReportNotifier`
2. **seed（诚实反映 shipped report，与 mockup #18 4.68M 一致）**：
   - 输入 62400 / 输出 31200 / 调用 128 / 实际字数 10000.0
   - costByType: {synthesis:42000, polish:31600, deviationDetect:20000}（合 93600=输入+输出，镜像 mockup #16 真实分布）
   - costByChapter: {}（报告页不渲染此字段，留空合法）
   - projection: target 500000 / multiplier 50 / estInput 3120000 / estOutput 1560000 /
     estCalls 6400 / low 40 / high 60 → 预估总 (3.12M+1.56M)=4.68M ✓ 吻合 mockup
   - optimizationSuggestions: ['批量合并 AI 操作以减少调用次数。', '精简知识库注入上下文，降低输入 token 消耗。']
3. `flutter test test/readme_screenshots/token_cost_report_test.dart --update-goldens`
   生成 docs/18 golden。
4. 回归：无 --update-goldens 重跑确认确定性匹配 GREEN。
5. 验证三重：find.text GREEN / PIL 像素（真实暗色 UI 非空白非退化）/ 字节（mockup~123KB→真实）。
6. README.md + README.en.md：18 行披露更新（真实渲染 + 其余示意图，对称 zh/en）。

### Part B — failures/ gitignore 泄漏修复

7. `.gitignore` 加 `test/readme_screenshots/failures/`（flutter_test golden 失败产物）。
8. 删除当前陈旧残留 `test/readme_screenshots/failures/`（01/21 的 18:58 中间产物）。

## 提交

原子提交（GSD 规范）：
- commit 1 (test+feat): token_cost_report_test.dart + docs/18 golden + README zh/en 披露
- commit 2 (chore): .gitignore + 删 failures 残留
- commit 3 (docs): PLAN + SUMMARY + STATE

## 验证门槛（证据驱动）

- [x] flutter analyze 0（基线已确认）
- [ ] token_cost_report_test --update-goldens GREEN + 生成 18 golden
- [ ] 回归（无 --update-goldens）全 readme_screenshots 目录 GREEN（01/17/18/21 四张）
- [ ] PIL 18 真实渲染（distinct colors 合理 + 暗色 surface + 文字像素，非空白）
- [ ] 字节 18 < 100KB（真实渲染非 mockup~123KB）
- [ ] README zh/en 披露对称更新
- [ ] .gitignore 含 failures/，残留已删
- [ ] 全项目 analyze 0 零回归
