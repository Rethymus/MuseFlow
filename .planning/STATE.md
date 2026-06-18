---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: milestone
status: v1.4 shipped (24 phases, 1717 tests), MC-02 章节摘要回路+触发面全闭合，待真实API验证
stopped_at: context exhaustion at 82% (2026-06-18)
last_updated: "2026-06-18T12:10:00.000Z"
last_activity: 2026-06-18 — quick-260618-rlo test MC-02 refresh 写侧链路真实 GLM API 集成测试（闭合「待真实API验证: refresh 触发链」headless 缺口）。真实 GLM-4-flash 下 T1 首次刷新→summarize→put+读回一致 / T2 幂等不烧 quota。深挖根因=setUpHiveTest 的 ensureInitialized 装 flutter_test HTTP mock 拦截真实调用（400）→ 改 journey_container 模式直接 Hive.init 修复。全仓 analyze 0 + manuscript 61 GREEN 零回归
progress:
  total_phases: 8
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-12)

**Core value:** 让AI帮你写好故事，但让读者看不出AI的痕迹。
**Current focus:** v1.5 真实创作验证与体验打磨

## Current Position

Phase: Pre-25 of 32 (v1.5 — 真实创作验证与体验打磨) 🟡 PLANNING
Status: v1.4 shipped (24 phases, 1717 tests), MC-02 章节摘要回路+触发面全闭合，服务层全链路真实 GLM 已验证（260618-rlo），UI wiring 待真机 UAT
Last activity: 2026-06-18 — quick-260618-rlo test MC-02 refresh 写侧链路真实 GLM API 集成测试（闭合「待真实API验证: refresh 触发链」headless）。真实 GLM-4-flash 下 T1 首次刷新→summarize→put+读回一致 / T2 幂等不烧 quota。深挖根因=setUpHiveTest 的 ensureInitialized 装 flutter_test HTTP mock 拦截真实调用→改 journey_container 模式修复。全仓 analyze 0 + manuscript 61 GREEN 零回归

Progress: [░░░░░░░░░░░░░░░░░░░░] 0%

## v1.4 Implementation Status

| Phase | Status | Implemented | Missing |
|-------|--------|-------------|---------|
| 17. Author Style Fingerprint | ✅ Complete | All 10 files + 2 tests + routing + AI integration | — |
| 18. Anti-AI-Scent Deepening | ✅ Complete | 258 synonyms, 20 categories, review signals on original text | Management UI, validation with real prose samples |
| 19. Style Deviation + Thermometer | ✅ Complete | 5-dimension deviation detector (13 tests), AI-scent score 0-100, thermometer dashboard + inline card in editor | — |
| 20. Smart Knowledge Injection | ✅ Complete | FuzzyMatcher (28 tests), AliasExtractor (15 tests), PronounResolver (13 tests), 3-phase middleware (5 tests) | — |
| 21. Relationship Graph + Foreshadowing | ✅ Complete | Relationship domain (8 types, 8 tests), repository (16 tests), notifier (5 tests), foreshadowing reminder widget, editor sidebar integration, relationship management UI, knowledge injection with relationship context | — |
| 22. Long-form Context + Guided Writing | ✅ Complete | 3-chapter context chain (220/150/80), multi-turn (5 turns), 3 plot directions | — |
| 23. Editor AI Operations + Undo | ✅ Complete | 7 operations, operation prompts, 20-step undo, entries accessor, version comparison A/B dialog with side-by-side text, reverse-chronological order | — |
| 24. Web Responsive + Dashboard | ✅ Complete | Responsive editor (LayoutBuilder, drawer for narrow), writing heatmap, progress dashboard (word count progress, AI ratio, streak, pace, consistency), `/stats/progress` route | — |

## Performance Metrics

**Velocity:**

- Total plans completed: 76 (v1.0: 25, v1.1: 17, v1.2: 6, v1.3: 27 + quick/gap-closure tasks)
- Total phases: 24 (0-16 complete, 17-24 planned for v1.4)

**By Phase (v1.3):**

| Phase | Plans | Status |
|-------|-------|--------|
| 12. Token Audit | 3 | Complete |
| 13. Automation Test Harness | 4 | Complete |
| 14. World-Building & 30 Chapters | 10 | Complete |
| 15. Full Manuscript & Story Structure | 7 | Complete |
| 16. Analysis & Reports | 3 | Complete |

*Updated after v1.4 roadmap creation, 2026-06-11*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions from v1.4 roadmap:

- **D-17-ROADMAP**: v1.4 phases derived from 18 requirements across 5 categories, 8 phases (standard granularity)
- **D-17-DEPS**: Phases 17 and 18 are independent starting points; Phase 19 depends on both; Phase 21 depends on Phase 20; Phase 23 depends on Phase 17

### Pending Todos

None.

### Blockers/Concerns

- Human UAT still needed on physical Windows/Android devices for IME composition, startup/lifecycle behavior
- Anti-AI-scent banned phrase lists should be validated with broader real Chinese prose samples before release sign-off — ✅ CLOSED 260618-vm1 (real GLM prose → detector fires: highlights=2/reviewSignals=1; env-gated real-API validation test added; remaining: human-prose false-positive direction needs real samples)
- Phase 7 bundled template prose needs human literary review before release sign-off

Last activity: 2026-06-14 - P2 深化连发 5 项：260614-gmg（AA-02 对比减法 CoPA + AA-03 创意度→温度，ECC APPROVE）+ 260614-aa4（AA-04 句子级AI味）+ 260614-mc1（🔴P0 MC-01 动态知识库陈旧度 KbStalenessChecker+lastVerifiedChapter）+ 260614-ci1（CI-01 PATHs 对话行为 DialogueActClassifier）；1611 tests 累计 +61 零回归 analyze 0

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260613-q8x | 修复 Claude token 审计 bug（MessageStartEvent 两事件捕获） | 2026-06-13 | 58632e7 | [260613-q8x-fix-claude-usage-tokens](./quick/260613-q8x-fix-claude-usage-tokens/) |
| 260613-dev-opt | 偏差检测可选化（默认关闭，消除编辑器 AI 操作隐藏 2x token 成本） | 2026-06-13 | dfe3198 | [260613-dev-optional-deviation](./quick/260613-dev-optional-deviation/) |
| 260613-edreview | 编辑评审团（CritiCS 4维 LLM 评审：情节/人物/文笔/节奏，单次审计调用，容错JSON解析） | 2026-06-13 | 4519e8f | [260613-editorial-review](./quick/260613-editorial-review/) |
| 260614-0rz | 修复 analyzer 技术债（integration_test 导出签名回归 + 10 测试文件 warning；analyze 11→0，1524 tests 无回归） | 2026-06-14 | 6fce67a | [260614-0rz-analyzer-integration-test-error-10-warni](./quick/260614-0rz-analyzer-integration-test-error-10-warni/) |
| 260614-1tp | P2 Author Writing Sheet 词汇签名（CJK n-gram 抽取作者特征词注入生成 prompt，"自然融入"措辞；IJCNLP 2025 背书；1548 tests +24） | 2026-06-14 | baac2cc | [260614-1tp-p2-author-writing-sheet-prompt](./quick/260614-1tp-p2-author-writing-sheet-prompt/) |
| 260614-gmg | P2 反AI味生成侧深化（AA-02 对比减法 CoPA 4模式 prompt + AA-03 创意度三档→温度 TempParaphraser；ContrastiveSubtractionMiddleware 接入两 pipeline + 设置页 SegmentedButton；1571 tests +21 零回归） | 2026-06-14 | 81e8738 | [260614-gmg-p2-contrastive-creativity](./quick/260614-gmg-p2-contrastive-creativity/) |
| 260614-aa4 | P2 AA-04 句子级 AI 味标记（SentenceAiScentAnalyzer 4 句局部信号：机械过渡词起句/AI套式/虚词占比过高/超长无断句；逐句 0-100 评分，worst/hasNotable；与 Phase 19 整体 detector 正交；1581 tests +9 零回归） | 2026-06-14 | 6233af5 | [260614-aa4-sentence-ai-scent](./quick/260614-aa4-sentence-ai-scent/) |
| 260614-mc1 | P2 🔴P0 MC-01 动态知识库陈旧度追踪（KbStalenessChecker fresh<10/stale≥10/veryStale≥20 + null旧条目→fresh 向后兼容；CharacterCard+WorldSetting 加 lastVerifiedChapter 字段全套向后兼容；checker 与实体解耦；1602 tests +21 零回归） | 2026-06-14 | 31e9c30 | [260614-mc1-kb-staleness](./quick/260614-mc1-kb-staleness/) |
| 260614-ci1 | P2 CI-01 PATHs 对话行为识别（DialogueAct 5行为枚举 + DialogueActClassifier 关键词信号分类纯逻辑，默认followUp，置信度/匹配词可解释；响应策略wiring留后续；1611 tests +9 零回归） | 2026-06-14 | 0525a9e | [260614-ci1-paths-dialogue-act](./quick/260614-ci1-paths-dialogue-act/) |
| 260616-hd9 | 🔴P0 MC-01 UI wiring 收尾（KbStalenessChecker 接入 _CharacterCardTile/_WorldSettingTile：stale amber/veryStale red 徽章 + 「标记为已验证」PopupMenu 动作→save(copyWith(lastVerifiedChapter:count))；_StalenessBadge 组件；7 widget 测试三态+动作；1618 tests +7 零回归 analyze 0；红线仅触 presentation 2 文件） | 2026-06-16 | 643406a | [260616-hd9-mc-01-ui-wiring](./quick/260616-hd9-mc-01-ui-wiring/) |
| 260616-ht9 | AA-04 句子级 AI 痕迹面板（反AI味产品灵魂）：StyleDeviationResult 加 text 字段贯通→StyleThermometerDashboard 加「最可疑的句子」section（SentenceAiScentAnalyzer 取 top3 句子+分数徽章+reasons，hasNotable 才渲染避免噪音）；3 widget 测试（AI套式句渲染/fresh不渲染/空文本不渲染）；1621 tests +3 零回归 analyze 0；红线守住 sentence_analyzer 本体） | 2026-06-16 | fe53b0d | [260616-ht9-aa-04-ai-wiring](./quick/260616-ht9-aa-04-ai-wiring/) |
| 260616-ci2 | CI-01 PATHs 响应策略路由 wiring（收尾 260614-ci1 纯逻辑）：新建 DialogueActMiddleware 接入 prompt pipeline——读 additionalInstruction→DialogueActClassifier 分类→按 4 actionable 行为（风格调整/内容探索/意图修订/内容注入）注入中文响应策略系统消息（merge 进 messages[0]，与 PersonaInjection/BannedList 约定一致）；followUp/无信号/confidence0 三态 no-op 避免噪音；管线注册紧随 SystemPromptMiddleware；11 测试（4 注入+5 no-op+2 集成）；1632 tests +11 零回归 analyze 0；红线守住 classifier/dialogue_act/synthesis_notifier | 2026-06-16 | (本提交) | [260616-ci2-dialogue-act-middleware](./quick/260616-ci2-dialogue-act-middleware/) |
| 260616-sy1 | SY-01 synthesis 反AI味作者反馈对称（闭合核心流程缺口）：SynthesisState 加 reviewSignals 字段（与 editor_ai_state 对称）+_postProcess 复制 result.reviewSignals（此前被丢弃，仅 editor 流程接入）；synthesis_panel 加「AI修改复查」摘要条 _SynthesisReviewSummary（sev→color 淡色容器+Tooltip，非空才渲染避免噪音）；诊断纠错——processor 非死代码（经 antiAIScentProcessorProvider 被 synthesis_notifier:315 消费），真缺口是 synthesis 流程丢弃 reviewSignals；5 测试（3 notifier 含端到端转场套话触发+2 panel widget）；1637 tests +5 零回归 analyze 0；红线守住 anti_ai_scent_processor/editor_ai_notifier/status_bar | 2026-06-16 | (本提交) | [260616-sy1-synthesis-review-signals](./quick/260616-sy1-synthesis-review-signals/) |
| 260616-aa5 | AA-05 武侠类型套句检测（多类型产品类型反馈准确化）：产品支持修仙/武侠/都市/科幻/玄幻 5 类(PROJECT.md:45)但类型套句仅修仙且描述硬编码"修仙"；新增 _wuxiaCliches（8 武术/江湖系词）+_buildReviewSignals genre block 改造（分别计 xianxia/wuxia 命中，主导类型命名描述，阈值不变）；信号标题'类型文套句偏多'保持不变（genre-agnostic，line 280 containsAll 零破坏）；2 测试（修仙描述准确+武侠新覆盖）；1639 tests +2 零回归 analyze 0 | 2026-06-16 | (本提交) | [260616-aa5-wuxia-genre-cliches](./quick/260616-aa5-wuxia-genre-cliches/) |
| 260616-aa5b | AA-05 续 都市/科幻类型套句（5 类型预设覆盖到 4/5）+ genre 命名泛化（二元→N 类型 map+reduce 取主导命中，插入序平局优先级 修仙>武侠>都市>科幻）；新增 _urbanCliches/_scifiCliches 各 8 词（零重叠 synonym map 20 类）；信号标题'类型文套句偏多'不变；2 测试（都市/科幻各一）；1641 tests +2 零回归 analyze 0 | 2026-06-16 | (本提交) | [260616-aa5b-urban-scifi-cliches](./quick/260616-aa5b-urban-scifi-cliches/) |
| 260616-px1 | AA-05c 玄幻类型套句（5/5 预设闭合）：新增 _xuanhuanCliches 8 词（西方魔法/异界/血脉契约寄存器：魔法元素/吟唱咒语/血脉觉醒/签订契约/召唤魔兽/魔法学院/圣域/异界大陆，与修仙灵力寄存器零重叠，化解 AA-05b"高度重叠"推迟理由）；genreHits map 末位加玄幻（优先级链 修仙>武侠>都市>科幻>玄幻，平局保守）；2 测试（玄幻检测+命名 / 平局优先级锁定）；1643 tests +2 零回归 analyze 0；红线守住标题 genre-agnostic 与既有 4 类 | 2026-06-16 | (本提交) | [260616-px1-aa-05c-xuanhuan-genre-cliches-5-5-covera](./quick/260616-px1-aa-05c-xuanhuan-genre-cliches-5-5-covera/) |
| 260616-qc5 | AA-06 叠词/程度副词堆砌信号（反AI味信号矩阵补分布性寄存器维度）：新增第 8 个 review signal——_mannerAdverbStems 10 裸词干（缓缓/微微/淡淡/轻轻/深深/默默/静静/渐渐/隐隐/悄悄）+ _buildReviewSignals count 信号（≥5 fire / ≥8 high）；与 synonym map 正交（固定短语 vs 裸词干跨任意动词的分布性过度依赖，不同失败模式）；阈值校准于 process() progressText 段落粒度；2 测试（6词干密集触发+medium / 1词干稀疏不触发精度负向）；1645 tests +2 零回归 analyze 0；红线守住既有 7 信号 | 2026-06-16 | (本提交) | [260616-qc5-aa-06-manner-adverb-stem-overuse-signal-](./quick/260616-qc5-aa-06-manner-adverb-stem-overuse-signal-/) |
| 260616-qmq | AA-04b 句子级空洞强调词堆砌信号（SentenceAiScentAnalyzer 第 5 信号）：emptyIntensifiers Set（12 词：真是/简直/十分/非常/尤其/格外/颇为/相当/无比/极其/尤为/极为）+ _score 信号5（句内 ≥3 hit → +30，reason '空洞强调词堆砌'）；正交性已验证——强调词非 functionChars 故信号3结构性漏检（'她真是非常十分开心' ratio 2/8<0.4），4 既有信号全漏唯独新信号能捕；喂「最可疑的句子」面板；与 AA-06 整体叠词正交（不同词族/粒度/消费者）；2 测试（3词触发+notable / 1词不触发精度负向）；1647 tests +2 零回归 analyze 0；红线守住既有 4 信号与 hasNotable 人工文本测试 | 2026-06-16 | (本提交) | [260616-qmq-aa-04b-sentence-level-empty-intensifier-](./quick/260616-qmq-aa-04b-sentence-level-empty-intensifier-/) |
| 260616-qxe | refactor 抽取 anti_ai_scent_processor 数据表到 part 文件（消除 03-flutter-standards.md 800 行红线违规）：主文件 1091→555 行；13 个 static const/final 词库表（_synonymMap 20类~300词 / _highlightOnlyPhrases / _structuralPatterns 12正则 / 5 类 _xCliches xianxia·wuxia·urban·scifi·xuanhuan / _mannerAdverbStems / _formulaicEndings / _emotionalCliches / _descriptionFormulas）转同库顶级私有常量搬入新建 anti_ai_scent_lexicon.dart（part of anti_ai_scent_processor.dart）；part/part of 同库机制保证零行为变更零调用点改动（方法体裸名引用自动解析到顶级私有常量，Dart _ 为库级私有非文件级）；2 枚举+3 值类+AntiAIScentProcessor 类+synonymKeys getter 留主文件，8+ 消费方（editor_ai_state/status_bar/synthesis_panel/synthesis_notifier/banned_phrase_settings/intent_preservation_analyzer/providers）导入路径与公共类型导出零变更；analyze 0 / anti_ai_scent_test 57 测试全绿 / git diff 仅 2 文件 | 2026-06-16 | f204855 | [260616-qxe-anti-ai-scent-processor-dart-part-anti-a](./quick/260616-qxe-anti-ai-scent-processor-dart-part-anti-a/) |
| 260616-rj4 | refactor 拆分 providers.dart 为 feature 分组 part 文件（消除 03-flutter-standards.md 800 红线）：主文件 856→103 行（仅留 ~50 import + library; + 5 part 指令）；~45 provider 声明 + 2 Notifier 类（AutoDeviationCheck/CreativityLevel）按域分入 5 part——providers_core(101)/providers_ai(199)/providers_knowledge(174)/providers_structure(254)/providers_stats(59)，各首行 part of 'providers.dart'; 且零 import（part 不能有 import 的 Dart 规则，所有 import 留主库文件）；part/part of 同库机制保 provider 间相互引用（activeAdapterProvider 读 openai/claudeAdapter）与裸名解析不变；114 消费方 import 路径与 provider 导出零变更；flutter analyze 全仓 0 issues（编译全部 114 消费方证零破坏，机械重构零逻辑改动，能编译即行为等价；全量 test 因 context 收紧以 analyze-0 替代）| 2026-06-16 | 3a6a13f | [260616-rj4-providers-dart-feature-part](./quick/260616-rj4-providers-dart-feature-part/) |
| 260616-uho | refactor 拆分 editor_with_sidebar.dart 为 part 文件（qxe/rj4 800 红线消除战役收尾，拆后全仓零文件超 800）：主文件 887→640 行；Dart 无 partial class 故用同库私有 extension _EditorWithSidebarStateLayout 承载 4 个 layout 辅助方法（_buildDesktopLayout/_buildMobileLayout/_buildEditorArea/_getMenuPosition，build() 内裸调用经 extension-on-this 解析零改动）+ editor_with_sidebar_intents.dart part（7 个 _XxxIntent 类 + _SelectionLeadersLayerBuilder + _buildManuscriptStylesheet 函数）；part/part of 同库机制零行为变更，2 消费方（app.dart + editor_with_sidebar_test）零改动；analyze 0 / 1647 tests 零回归 | 2026-06-16 | 159d58a | [260616-uho-refactor-editor-with-sidebar-dart-part-s](./quick/260616-uho-refactor-editor-with-sidebar-dart-part-s/) |
| 260616-vdw | refactor 拆分 provider_management_page.dart（uho 模式复刻，全仓最大文件 737→329 行，达 200-400 推荐区）：单 part 文件 provider_management_page_layout.dart 用同库私有 extension _ProviderManagementPageStateLayout 承载 3 个 build 辅助方法（_buildMobileSwitcher/_buildLeftPanel/_buildRightPanel，Dart 无 partial class，build() 裸调用经 extension-on-this 解析零改动）；part/part of 同库机制零行为变更，消费方零改动；analyze 0 / 1647 tests 零回归 | 2026-06-16 | afc9e23 | [260616-vdw-refactor-provider-management-page-dart-p](./quick/260616-vdw-refactor-provider-management-page-dart-p/) |
| 260616-wao | refactor 抽取 app.dart 路由表到 part 文件（800 红线战役末块，复刻 uho/vdw 模式）：210 行 _createRouter GoRouter 路由表搬入新建 app_routes.dart（part of 'app.dart' + extension _MuseFlowAppRoutes on MuseFlowApp 承载 createRouter()；关键差异：MuseFlowApp 是 ConsumerWidget 无 State 类，extension 直接 on MuseFlowApp 本身而非 _State）；主文件加 library; + part 指令，build() _createRouter()→createRouter()（extension-on-this 裸调用解析），_handleRedirect 留主文件经同库 part 可见性被 redirect 引用；35 import 全留主文件（part 文件禁止 import 的 Dart 规则）；app.dart 307→98 行；零行为变更零消费方改动（main.dart/token_audit_route_test 透明）；analyze 0 / 1647 tests 零回归 | 2026-06-16 | 1fb0e19 | [260616-wao-extract-app-routes-partfile](./quick/260616-wao-extract-app-routes-partfile/) |
| 260617-05c | fix 修复 style_deviation_detector 情感词双计 bug：_countPositive/NegativeSentiment 用 const List 含重复词条（positives 喜悦×2；negatives 痛苦/愤怒/恐惧 各×2），计数循环 for(word in list) count+=word.allMatches(text).length 把重复词命中算两次，虚高 positive/negative 计数扭曲 warmth/intensity→_classifyTone 与偏差检测（lines 317-347）；两 List 改 const Set 字面量+移除 4 dup（与 sentiment_lexicon.dart Set 先例一致，结构杜绝复发，for-in 计数等价）；私有方法局部作用域无外部引用；analyze 0 / detector 13 测试全绿 | 2026-06-17 | 9122b01 | [260617-05c-fix-sentiment-double-count](./quick/260617-05c-fix-sentiment-double-count/) |
| 260617-140 | refactor 拆分 format_cleaner.dart 为 part 文件（800 红线战役末块复刻 uho/vdw/wao 模式，全仓最大手写文件 680→71 行）：3 part 文件按 4 section 注释横幅切分——format_cleaner_punctuation.dart(249/11 方法)/format_cleaner_markdown.dart(278/7 方法)/format_cleaner_whitespace.dart(97/whitespace+段落 3 方法)，各首行 part of 'format_cleaner.dart'; + extension _FormatCleanerPunctuation|Markdown|Whitespace on FormatCleaner 承载私有实例方法（普通 const 类非 Widget/State，与 wao ConsumerWidget 同理）；主文件加 library; 首行 + 3 part 指令，clean() 编排顺序(空白→标点→markdown→段落 load-bearing 不变)裸调用经 extension-on-this 解析零改动；唯一消费方 format_clean_preview_dialog.dart:38 仅用 const FormatCleaner()+clean() 零改动；零行为变更；analyze 0 / 38 targeted(format_cleaner_test 21+format_cleaning journey 17) + 全量 1647 零回归 | 2026-06-17 | cf0d69c | [260617-140-lib-features-story-structure-application](./quick/260617-140-lib-features-story-structure-application/) |
| 260617-1uk | fix 修复 style_deviation_detector 情感词裸单字子串过计 bug（260617-05c 同族延续）：_countPositive/NegativeSentiment 内联 Set 含裸单字 '爱'(pos)/'恨'(neg)，被 String.allMatches 当子串匹配——'恨' 命中 '恨不得'(急切想，正面)极性反转 + '爱' 命中 可爱/爱好/爱情/爱不释手 过计，扭曲 warmth/intensity→emotionalTone 维度偏差分（产品灵魂反AI味）；移除裸 '爱'/'恨' 两行（与共享 SentimentLexicon 刻意不收录裸单字设计一致；application→infrastructure 架构禁止反向依赖故就地修内联词表而非 import）+ 加设计注释 + 2 回归测试（公开 analyze() 断言 textValue<0.6，fixture 3×恨不得/3×可爱·爱好·爱情 强制 pre-fix RED）；TDD RED→GREEN；零行为变更；analyze 0 / 15 targeted(13+2) + 全量 1649 tests +2 零回归 | 2026-06-17 | 4a004d0 | [260617-1uk-fix-sentiment-bare-char-overcount](./quick/260617-1uk-fix-sentiment-bare-char-overcount/) |
| 260617-f7l | refactor 根治 style_deviation_detector 情感基调双量尺漂移（闭合 05c/1uk 同族 bug 链根因）：detector._computeEmotionalTone 自带 42 词内联表+自创 warmth/intensity/classifyTone 公式，与 profile 构建权威方 StyleAnalyzer 用 SentimentLexicon（~240 词 indexOf 安全计数+ratio/density 公式）不一致——两套量尺比较→emotionalTone 维度偏差分系统扭曲（反AI味核心信号）；改为镜像 style_analyzer.dart:254-272 全部委托 SentimentLexicon.countPositive/countNegative/warmthScore/intensityScore/classifyTone（indexOf 循环从结构上杜绝裸单字子串过计）；删除 _countPositiveSentiment(22词)/_countNegativeSentiment(20词)/_classifyTone(5类自创) 三私有方法+内联 Set 字面量+自创公式（共 ~95 行，net -48）；application→infrastructure 依赖先例同 style_analyzer.dart:19（纯 Dart const 数据类非真 infra 副作用）；isFlat 边界从 0.35-0.65 中性带改为 <0.3 适配新公式语义（无情感词→intensity 0 而非旧 0.5，与 classifyTone <0.3→平静/冷静 截止一致）；2 RED→GREEN 回归测试（T1 123 CJK 命中 23 lexicon 独有词 0 内联→post intensity 1.0 vs pre 0.5，门槛 >0.6 强制 RED；T2 公式同源 closeTo(intensityScore,1e-9) 精确相等）；flat-emotion fixture 重写 117 CJK 零 lexicon 命中（pre-fix 83 CJK 含 '阳光' 不再触发 isFlat）；TDD RED(2a4c340)→GREEN(49dc61c)；analyze 0 / 17 detector + 287 editor feature 全量零回归 | 2026-06-17 | 49dc61c | [260617-f7l-styledeviationdetector-sentimentlexicon](./quick/260617-f7l-styledeviationdetector-sentimentlexicon/) |
| 260617-hnl | fix 根治 style_deviation_detector rhythm 维度双量尺门槛 bug（双量尺消除战役第 5 维，与 260617-f7l emotionalTone 同族同源）：detector._computeRhythmScore 最低句数门槛 < 3 对齐到基线方 StyleAnalyzer._computeRhythmScore 的 < 5——rhythm 公式（avg/variance/stdDev/cv/`(1.0-(cv-0.3)/0.5).clamp`）两文件原本完全一致，唯一差异即此门槛；pre-fix < 3 让 3-4 句 AI 文本用稀薄数据算真实节奏方差分（4 句均匀→cv≈0→rhythm≈1.0），去对比 analyzer 用 5+ 句稳健数据构建的 profile.rhythmScore——稀薄测量 vs 稳健基线，rhythm 维度偏差分失真（反AI味核心信号）；单行修复 + 8 行注释（260617-f7l 同源原理：测量 ruler 必须 == 基线 ruler）；2 RED→GREEN 回归测试（T1 4 句均匀长度断言 rhythmDev.textValue==0.5，pre-fix 实际 1.0 强制 RED；T2 6 句均匀断言 >0.7 护栏确认 ≥5 句路径未破坏）；0 个既有 fixture 需扩写（全用 ≥5 句或不强断 rhythm textValue）；TDD RED(ff06779)→GREEN(10fbae5)；analyze 0 / 19 detector + 289 editor feature 全量零回归 | 2026-06-17 | 10fbae5 | [260617-hnl-style-deviation-detector-rhythm-bug-anal](./quick/260617-hnl-style-deviation-detector-rhythm-bug-anal/) |
| 260617-j0z | fix 根治 style_deviation_detector vocabulary 维度双量尺门槛 bug（双量尺消除战役第 6 维，与 hnl rhythm/f7l emotionalTone 同族同源）：detector._analyzeVocabulary 最低字数门槛 < 20 对齐到基线方 StyleAnalyzer._computeVocabularyRichness 的 < 50——vocabulary 公式（unique CJK type-token ratio 经 ((ratio-0.25)/0.30).clamp 归一化）两文件原本完全一致，唯一差异即此门槛；pre-fix < 20 让 20-49 字 AI 文本用稀薄样本算真实词汇丰富度（30 全异字→ratio 1.0→richness 1.0），对比 analyzer 50+ 字稳健基线→vocabulary 偏差分失真（反AI味核心信号）；单行修复 + 注释（测量 ruler == 基线 ruler）；2 RED→GREEN（T1 30 全异字断言 textValue==0.5 pre-fix 实际 1.0 强制 RED / T2 60+ 字 >0.6 护栏）；0 fixture 扩写；TDD RED(19797a4)→GREEN(84e7c27)；analyze 0 / 21 detector + 291 editor feature 全量零回归 | 2026-06-17 | 84e7c27 | [260617-j0z-style-deviation-detector-vocabulary-bug](./quick/260617-j0z-style-deviation-detector-vocabulary-bug/) |
| 260617-wma | fix 真实 GLM API 暴露的可靠性双缺口（闭合 STATE #1 blocker 后的优化）：真实 BigModel key E2E journey 第 6 章 AIStreamException 杀死整批，探针同窗口 8 连发全过→确诊瞬时错误非限流；修①AIException 基类加 toString()=>`$rt: $msg` 解诊断黑箱 ②OpenAIAdapter 抽 static retryStream(factory,{maxRetries=3,backoff}) async*——零 token 早失败且可重试(AIRateLimit/AINetwork/AIStream)退避重试(100/200/400ms)，发射过 token/AIAuth 透传，createStream 委托→9 调用方+journey 单一咽喉全受益；TDD 7 确定性测试全绿/analyze 0 | 2026-06-17 | b9347bd | [260617-wma-fix-aiexception-tostring-and-adapter-tra](./quick/260617-wma-fix-aiexception-tostring-and-adapter-tra/) |
| 260618-0ae | fix 偏差检测过滤合规确认假警报（真实 GLM key 暴露）：真实 key 复验 wma 重试修复时 30 章 journey 偏差阶段跑在真实 GLM 文本上，Ch1 全部 11 条"clear"警告都是"符合/并未违反…设定"合规陈述、零真实违背→假警报淹没信号；根因 _buildPrompt 未禁报合规项 + _parseResult 只过滤 severity==low 不识别合规语义；双保险修：①prompt 显式禁报合规（保留"只报告 medium 或 clear"子串零破坏）②parser _isComplianceNoise 兜底过滤（合规标记 符合\|未违反\|并未违反\|没有违反\|未违背 且不含真违规 违背\|违反了；"违反了"带"了"肯定句≠"未违反"否定式精准区分）；TDD 2 RED→GREEN / analyze 0 / deviation service+6 widget+5 零回归 | 2026-06-18 | 4b452d3 | [260618-0ae-fix-deviation-compliance-false-positive](./quick/260618-0ae-fix-deviation-compliance-false-positive/) |
| 260618-1g3 | feat 补 GLM/BigModel preset provider + 修复 preset 暴露的左面板溢出 bug：用临时 BigModel key（GLM-4-flash）真实 API 跑通 3 个 journey 集成测试（fragment 合成 501 字 / 3 种开篇风格 / 30 章连写 13395 字 + Skill guardian 71 条真实剧情偏差告警 + token 审计 30 调用）兑现 STATE "待真实API验证"；preset_providers.dart 加 preset-glm（复用 AiProviderType.openai OpenAI 兼容适配器，与 journey wiring 同源，配置逐字一致→真实调用已证）；第 5 个 preset 卡片致左面板 Column 底部溢出 78px→Expanded(SingleChildScrollView) 根治可滚动；TDD RED→GREEN / preset 15 + responsive 2 全过 / analyze 0；零新增回归（openai_adapter 2 缓存测试 clean HEAD 预存遗留，已记录非本次引入） | 2026-06-18 | d5db5e0 | [260618-1g3-add-glm-preset](./quick/260618-1g3-add-glm-preset/) |
| 260618-1g4 | fix 修复 openai_adapter client caching 测试回归（闭合 1g3 遗留）：wma 可靠性重构把 createStream 的 _attemptStream 包进 retryStream(()=>...) 闭包，OpenAIClient 创建延迟到首次流订阅（async* 惰性），fire-and-forget createStream 不订阅时 _client 恒 null→isActive=false，2 caching 测试 clean HEAD 即红；根因修复（非改测试打补丁）：createStream 里 _validateBaseUrl 后 eager _getOrCreateClient 还原回归前行为，retryStream factory 经 _attemptStream 幂等 _getOrCreateClient 复用缓存 client，retry 语义不变；openai_adapter+resilience 30/30、全 AI 目录 313/313（311 -2→313 -0 闭合预存遗留）、analyze 0；真实 GLM journey 此前已证实战复用正常 | 2026-06-18 | ce1512b | [260618-1g4-fix-openai-adapter-caching](./quick/260618-1g4-fix-openai-adapter-caching/) |
| 260618-h4h | feat MC-02 slice 2 章节摘要持久化+注入闭环：ChapterSummaryStalenessChecker（isStale 增长绝对≥50且相对≥20%，对称 KbStalenessChecker，AND 避免误报）+ ChapterSummaryRepository（CRUD key=chapterId 1:1 upsert）+ ChapterSummaryAdapter（HiveTypeIds.chapterSummary=11）+ main 注册 + EditorChapterMemoryContextBuilder 注入（优先 fresh stored AI summary，缺失/stale/无 repository fallback 截断原文向后兼容；_warning 对 stored 跳过截断警告）+ providers wiring（chapterSummaryRepositoryProvider + builder 注入）；TDD 14 新测试 GREEN（staleness 6+repository 5+builder 注入 3）+ manuscript 75 回归零回归 + analyze 0；slice 1 真实 GLM 已证 summarize（34字/300字源） | 2026-06-18 | (本提交) | [260618-h4h-mc02-slice2-summary-persist-inject](./quick/260618-h4h-mc02-slice2-summary-persist-inject/) |
| 260618-jn6 | feat MC-02 slice 3 WRITE SIDE 闭合死循环：ChapterSummaryRefreshService（refreshIfNeeded 决策树+refresh force 变体+_summarizeAndPut 编排）+ RefreshOutcome 值类 + chapterSummarizationServiceProvider/chapterSummaryRefreshServiceProvider 两 provider 链（null-safe，activeProviderProvider+activeApiKeyProvider+activeAdapterProvider 镜像 editor_ai_notifier）+ ChapterNotifier.save unawaited fire-and-forget 触发（try/catch+debugPrint 隔离，wma/0ae posture：service SURFACES，trigger SWALLOWS）；前 slice 1+2 留 summarize() ZERO production callers 死循环（EditorChapterMemoryContextBuilder 永远 fallback 截断原文）→ 现闭合为 write→persist→read 活循环；minSummaryChars=20 跳过 stub；T6 GREEN 验证 AIException 透传无 partial put；TDD RED(d0d9c6c)→GREEN(a656136)→Wiring(4173b4d) 三原子提交；6 新测试 GREEN / manuscript/application 55 / manuscript 全量 141 / analyze 0 零回归 | 2026-06-18 | 4173b4d | [260618-jn6-mc-02-chaptersummaryrefreshservice-decis](./quick/260618-jn6-mc-02-chaptersummaryrefreshservice-decis/) |
| 260618-s4 | feat MC-02 slice 4 触发面收尾（闭合 jn6 遗留：仅 save 触发，split/merge/delete/add/duplicate 未接）。两真问题：① splitChapter 正确性 bug——原章内容替换为 beforeContent（子集，更短），旧"整章摘要"因 growth 负被 staleness 判 fresh → 注入描述整章但章节只剩前半的错误摘要；② delete/merge 留孤儿摘要被 getByManuscriptId 返回。修：ChapterSummaryRefreshService.deleteSummary(chapterId)（委托 repository.delete，rethrow StateError，T7/T8 RED→GREEN）；ChapterNotifier 全面接线——add/duplicate 捕获 repository.add 返回的真实 id 章节（原来丢弃返回值！）触发 refreshIfNeeded；splitChapter/mergeChapters 用 force=true 走 service.refresh 绕过 staleness（内容被替换非增长）；delete(id)+mergeChapters(chapter2) 调 _deleteSummary 孤儿清理；_maybeRefreshSummary 加 {force} 参数+_deleteSummary 辅助，皆 fire-and-forget try/catch+debugPrint 不杀主流程（wma/0ae posture 延续）；3 wiring 测试用 _RecordingRefreshService（implements 绕过真实 ctor）override 验证 split 2×force-refresh / merge 1×force+1×delete / delete 1×deleteSummary；TDD 三原子提交(baab7b9/edf0497/f14d775)；manuscript 全量 146 GREEN / analyze 0 零回归 | 2026-06-18 | f14d775 | [260618-s4-mc02-trigger-surface-completion](./quick/260618-s4-mc02-trigger-surface-completion/) |
| 260618-rlo | test MC-02 refresh 写侧链路真实 GLM API 集成测试（闭合 STATE「待真实API验证: refresh 触发链」headless 缺口）：新增 chapter_summary_refresh_service_real_glm_test.dart 镜像 slice1（GLM_API_KEY env 门控无 key skip CI 安全）；真实 GLM-4-flash 下 T1 首次 refreshIfNeeded→summarize→put 持久化+content-faithful(含林风)+bounded+compressed+repository 读回一致(52字/300字源) / T2 幂等二次调用 refreshed==false 返回 stored 不烧 quota；深挖 30min HTTP 400 根因=setUpHiveTest 的 TestWidgetsFlutterBinding.ensureInitialized 装 HttpOverrides mock 拦截所有真实 HTTP（slice1/opening_guide/curl 不调均 200）→ setUp 改 journey_container 模式直接 Hive.init(显式tempPath) 不调 ensureInitialized 修复；教训：真实 API 测试禁用 setUpHiveTest；次要观察 openai_dart ApiException.body 对 GLM 400 为 null 黑箱待评估；全仓 analyze 0 + manuscript application 61 GREEN 零回归 | 2026-06-18 | (本提交) | [260618-rlo-mc-02-refresh-glm-api-api](./quick/260618-rlo-mc-02-refresh-glm-api-api/) |
| 260618-vfo | test(infra) 硬化 hive_test_helper 防 flutter_test HTTP-mock 陷阱（260618-rlo 暴露+根因的可复现陷阱）：setUpHiveTest 调 ensureInitialized→flutter_test 装 HttpOverrides.global mock→所有真实 HTTP 返 400 静默拦截真实 API 调用伪装 provider 错误（30min 诊断成本）→ setUpHiveTest 加醒目 ⚠ 警告 + 新增 setUpHiveForNetworkTest()（Hive.init 显式 tempPath 不调 ensureInitialized）+ tearDownHiveTest 通用；MC-02 real 测试 dogfood 新 helper 替内联 init（吃自己狗粮+作 helper 活文档）；全仓 analyze 0 + 真实 GLM 经新 helper +2 GREEN + setUpHiveTest 用户(repository/editor memory/foreshadowing 25 测试)零回归（纯新增+doc 不破坏既有） | 2026-06-18 | c1dc778 | [260618-vfo-hive-test-helper-flutter-test-http-mock-](./quick/260618-vfo-hive-test-helper-flutter-test-http-mock-/) |
| 260618-vm1 | test(aa) 反AI味词库真实GLM散文验证（闭合 STATE release blocker: banned phrase lists 应以真实中文散文验证）：反AI味是产品灵魂，既有57个canned测试用静态fixture从未对真实LLM产出验证；新增 anti_ai_scent_real_glm_test.dart 镜像slice1 env门控，显式AI风格prompt(叠词/程度副词/华丽结构，烟测证GLM-4-flash可靠诱发淡淡/微微/格外/颇为/仿佛/宛如)→真实生成→AntiAIScentProcessor.process(bannedPhrases:[] 纯测内部词库)；断言规范产出+检测器fire(highlights/reviewSignals非空，鲁棒)+severity合法+debugPrint信号明细；真实GLM 88字散文→highlights=2/reviewSignals=1([medium]句长节奏过于整齐76%)词库确实fire；全仓analyze 0 + 既有57测试零回归(纯新增) | 2026-06-18 | 1eb9f0d | [260618-vm1-glm-ai-state-release-blocker-banned-phra](./quick/260618-vm1-glm-ai-state-release-blocker-banned-phra/) |
| 260618-wjh | fix(ai) OpenAI/GLM 连接测试 timeout 修复（真实 GLM key 跑 Phase 25 E2E 时代码审计发现）：_testOpenAIConnection 用 OpenAIClient.withApiKey（不暴露 timeout）→ 落 OpenAIConfig 默认 timeout Duration(minutes:10)，用户点"测试连接"遇死/慢 baseUrl 等 10 分钟（_testClaudeConnection 显式 30s）；GLM preset 走 openai 类型直接受影响。修：testConnection 三层加可注入 timeout（默认 30s 对齐 Claude）+ OpenAI 路径改 OpenAIConfig(timeout:) 替 withApiKey 工厂 + 连接测试客户端 RetryPolicy(maxRetries:0)（测试连接本就该单次探测非退避重试4次，兼让超时确定性可测）+ Claude 路径用注入 timeout 替硬编码30s（默认不变行为等价）；新增 provider_service_timeout_test.dart 黑盒 ServerSocket（accept 不响应）+ 1s 注入 timeout 验证 1s 内抛 AINetworkException 非10min默认，用 setUpHiveForNetworkTest 避 flutter_test HTTP-mock 拦截 localhost 真实连接；analyze 0 + 新测试 GREEN + 全量 provider_service_test 14/14 零回归；顺带解锁验证 Phase 25 真实 GLM E2E（smoke/synthesis/opening/100章导出/30章+guardian/deviation 真实输出触发）；附带发现 journey 三重型真实GLM测试并发饱和致 serial_generation 30章撞 20min 超时（测试基础设施，非产品bug）→ 真实API journey 宜 --concurrency=1 | 2026-06-18 | (本提交) | [260618-wjh-openai-glm-connection-test-timeout-fix](./quick/260618-wjh-openai-glm-connection-test-timeout-fix/) |

## Deferred Items

Items acknowledged and deferred from v1.3:

| Category | Item | Status |
|----------|------|--------|
| uat_gap | Phase 00: Windows IME testing | human_needed |
| uat_gap | Phase 14: Chinese IME composition | human_needed |
| tech_debt | Phase 11: 4 non-critical items | deferred |

## Session Continuity

Last session: 2026-06-18T09:26:22.382Z
Stopped at: context exhaustion at 82% (2026-06-18)
Next step: adapter 瞬断重试（零 token 早失败退避重试，9 调用方单一咽喉）+ AIException.toString 诊断黑箱修复（当前错误日志全 "Instance of..."）——真实 key 暴露、合成测试永远抓不到的可靠性缺口。验证用确定性 fake（失败 N-1 次后成功）+ 真实 smoke 回归，不烧 quota 等随机瞬断。
Next step: ✅✅ MC-02 章节摘要回路+触发面全闭合（260618-jn6 slice3 write-side + 260618-s4 slice4 trigger-surface：save/add/dup/split/merge 触发刷新 + delete/merge 孤儿清理）。新候选：① 真实 GLM 端到端验证 refresh 触发链（save→summarize→store→下次 builder 读 fresh，需用户浏览器/真机）② 视觉 UAT（需 Windows 真机或用户浏览器连 kimi-webbridge——daemon 活跃但 list_tabs 空，扩展未连，自主会话不可用）③ 其他 v1.5 体验打磨项。注：双量尺战役全闭合；AA-05 类型套句 5/5 闭合；全量 1717 tests 零回归。
