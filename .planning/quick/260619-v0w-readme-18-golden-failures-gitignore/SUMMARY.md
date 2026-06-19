---
quick_id: 260619-v0w
slug: readme-18-golden-failures-gitignore
date: 2026-06-19
status: complete
commits: [ce7cae9, 4fdfeef]
---

# README #18 报告详情真实 golden + failures/ gitignore 修复

## 交付

继续 rs-series golden 截图迁移第 4 张：README #18「报告详情」→
`token_cost_report_page.dart`（Token 消耗分析 + 50万字长篇推算 + 按操作类型饼图）。
附带修复 flutter_test golden 失败产物 `failures/` 未 gitignore 的工作树泄漏。

## 实现

- 新建 `test/readme_screenshots/token_cost_report_test.dart`，镜像 rs1 harness：
  FontLoader 通用子集 + 1440×1000 + `tokenCostReportProvider.overrideWith` 单 provider
  override 喂 seed TokenCostReport（绕过 audit/chapter repository 链）+ matchesGoldenFile
  直指 docs/18（golden 即产物，零搬运）。
- seed 诚实反映 shipped report 形态：输入 62400/输出 31200/调用 128/实际 1万字，
  costByType {synthesis:42000, polish:31600, deviationDetect:20000}（合 93600=输入+输出），
  projection 50× → estInput 3.12M + estOutput 1.56M = 4.68M（与 mockup #18「预估 Token 4.68M」
  精确吻合，非编造）。2 条优化建议。
- universal 子集（rs3 成果 2.9MB GB2312 全集）已 0-missing 覆盖该页 46 CJK 字符 →
  无需重子集化，rs3「永不漂移」设计验证生效。

## 侦察纠正（PUA 先诊断后行动，避免假 bug）

1. **mockup 亦暗色**：首跑 PIL 见 95.2% dark surface 误判 18「已是真实渲染」；
   实则 `generate_readme_screenshots.mjs:70` mockup 背景 `#111218` 本就暗色。git ls-files
   确认 18 tracked + git status unmodified = 测试 FAIL 未达 matchesGoldenFile → 未覆写，
   committed 文件仍是 mockup。纠正：PIL 暗色 surface 不能区分暗色 mockup vs 真实暗色渲染，
   须字节/内容/回归综合判。
2. **find.text 计数踩坑 ×2**（核心教训，golden 测试断言须先核真实计数）：
   - `优化建议` findsOneWidget FAIL：ListView 懒构建，1440×1000 下内容 ~1048px，
     `优化建议` 在 fold 下未 build（真实用户滚动前所见同此）→ 只断言 fold 上内容。
   - `输入 Token` findsOneWidget FAIL（Actual: 2）：StatsSummaryCard title(14pt) +
     CostProjectionChart legend(12pt) 双来源，**合法重复非 bug**（图例正常渲染反证图表工作）。
   断言最终收敛到 fold 上且唯一计数的 `Token 消耗分析`×2（AppBar+headline）+
   `50万字长篇推算`×1（唯一 section title）。

## 验证（证据驱动，五重）

- ✅ token_cost_report_test GREEN（assertions + golden 全过）
- ✅ Golden 生成：docs/18-report-details.png 134153B(mockup) → **66565B(真实渲染)** 确认覆写
- ✅ PIL 真实渲染：1440×1000 / **1249 distinct colors**（富内容非空白）/ 97.3% dark surface /
  2.3% light text（文字入树）= 真实暗色 Flutter UI 非 SVG mockup
- ✅ 回归全目录无 --update-goldens：**+4 All tests passed!**（01/17/18/21 四张确定性匹配）
- ✅ analyze 0（test 文件 + page 零 issue）

## Part B — failures/ gitignore 泄漏

- `.gitignore` 加 `test/readme_screenshots/failures/`（flutter_test golden 失败 master/test/diff
  产物，永不 tracked 永可再生）。
- 删除陈旧残留（01/21 的 18:58 中间产物，rs3 universal subset 重基线时生成未清）。
- 验证：git status 不再显示 failures/，未来 golden 失败不再污染工作树。

## README 披露对称更新（zh/en × framework/footer = 4 处）

- README.md line 39/170 + README.en.md line 39/170：真实渲染清单加「报告详情（18）/
  Report details (18)」。

## 教训

1. **golden 测试 find.text 断言须先核真实 widget 计数**：ListView 懒构建（fold 下不 build）
   + 同文案多来源（card title + chart legend）= 两个 findsOneWidget 假失败。断言选 fold 上、
   唯一计数的文案；或改用 findsNWidgets(明确数)。
2. **暗色 mockup 伪装成真实渲染**：PIL dark-surface% 无法区分暗色 mockup vs 真实暗色渲染，
   须 git status（是否覆写）+ 字节大小（mockup~134KB vs 真实~66KB）+ 回归确定性综合判。
3. **rs3 universal 子集兑现「永不漂移」**：第 4 张迁移零重子集化、零既有 golden 漂移，
   后续页同模式增量迁移（剩余 17 张）。
4. golden 即产物（matchesGoldenFile 直指 docs 路径，测试生成=部署截图，零搬运）+
   override AsyncNotifierProvider 喂 seed 绕过 repository 链 = widget 截图最简形态。

## 剩余（后续 quick 任务，非本范围）

剩余 17 张 README 截图迁移：纯展示低悬（15 写作统计/16 Token审计/19 设置/20 AI模型管理）→
中等（02 捕捉/06-09 知识/18已done/12-14 结构导出）→ 中重（10/11 伏笔剧情/03 AI整理）→
极重（04 章节编辑器 appflowy / 05 编辑器AI工具栏 12-middleware）。harness 零模式改动可复用。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
