---
quick_id: 260622-13g
slug: readme-13-golden-logicguardian
date: 2026-06-22
status: complete
commits: []
---

# README #13 逻辑守护真实 golden — 交付

第 15 张真实截图：README #13「逻辑守护」→ StoryStructurePage tab3 GuardianPanel。结构簇第 3 张。
GuardianPanel 是**状态机**（idle/checking/results/error），results 态 + 非空 annotations 渲染
findings 列表（_FindingCard 含 severity/kind chip + reason + suggestedFix）。

## 实现

- GuardianPanel watch `guardianNotifierProvider`（AsyncNotifierProvider<GuardianNotifier,
  GuardianCheckResult>）+ `activeApiKeyProvider`（hasApiKey bool）。
- override guardianNotifierProvider 返回 **results 态 + 4 findings**（混 characterConsistency/
  timelineContradiction/worldRuleConflict/unresolvedForeshadowing × high/medium/low，真实展示
  chip 多样性），绕过 repository/LLM check 链。
- override `activeApiKeyProvider` → 非 null（`overrideWith((ref) => 'demo-key')`）让 panel 渲染
  findings 列表而非「配置 API Key」提示（_buildContent: `!hasApiKey` 分支会拦截）。
- override foreshadowingNotifierProvider 保 tab0 初始帧干净（tab3 滑动期 tab0 短暂可见）。
- 切 tab3：tap '守护' + pumpAndSettle。
- findings 含 reason/suggestedFix/sourceText 富文本（修仙样例：林风性格矛盾/第八章时间线冲突/
  灵气规则不一致/古剑低鸣未回收），对齐 README 运行样本。
- 固定 DateTime createdAt。

## 验证（六重）

- ✅ analyze 0（doc comment 尖括号删泛型注解修 unintended_html）
- ✅ 首跑 GREEN
- ✅ clean 连跑 2 次 GREEN（**results 状态机 + findings 列表确定性**——无动画依赖）
- ✅ golden 117836B（mockup ~129KB → 真实，内容最富之一）
- ✅ PIL **1384 色**（迄今最富——findings 卡+severity/kind chip+suggestedFix 多样色彩）/98.1%dark/0.7%text
- ✅ full-suite +15 All tests passed!
- ✅ README 双语 disclosure 4 处加入「逻辑守护(13)/Logic guardian(13)」

## 教训

- **状态机页 seed 目标态**：GuardianPanel 按 GuardianCheckState 分支渲染，seed `results` 态 +
  非空 annotations 直达 findings 列表（避开 idle/checking/error UI）。
- **条件分支 provider 须 override 满足前置**：`!hasApiKey` 会拦截 findings 显示→override
  activeApiKeyProvider 非 null 让前置成立。
- **富文本 seed 提升截图信息密度**：findings 含 reason+suggestedFix+sourceText → 1384 色（迄今
  最富），真实反映守护功能价值。

## 进度

已迁 **15/21**：01 / 02 / 06 / 07 / 09 / 10 / **13** / 14 / 15 / 16 / 17 / 18 / 19 / 20 / 21。
结构簇 3/5（10/13/14）。剩余 6 张：03 AI整理（synthesis 动画）/ 08 模板（重模型）/ 11 时间线 /
12 故事弧（viz 自定义绘制风险）/ 04-05 editor（appflowy 极重）。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
