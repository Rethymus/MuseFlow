# MuseFlow 灵韵

[![CI](https://github.com/Rethymus/MuseFlow/actions/workflows/ci.yml/badge.svg)](https://github.com/Rethymus/MuseFlow/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-0.1.4-blue?style=flat-square)](https://github.com/Rethymus/MuseFlow/releases)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows%20%7C%20Web-lightgrey?style=flat-square)](#技术栈)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)](CONTRIBUTING.md)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-FF5C7C?style=flat-square)
![Hive CE](https://img.shields.io/badge/Hive_CE-EEB33B?style=flat-square)
![super_editor](https://img.shields.io/badge/super__editor-4B5563?style=flat-square)
![OpenAI](https://img.shields.io/badge/OpenAI-111111?style=flat-square&logo=openai&logoColor=white)
![Claude](https://img.shields.io/badge/Claude-D97757?style=flat-square)
![DeepSeek](https://img.shields.io/badge/DeepSeek-4D6BFE?style=flat-square)
![Ollama](https://img.shields.io/badge/Ollama-111827?style=flat-square)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white)

[English](README.en.md) | 中文

> 想象力为骨，AI 为翼。

MuseFlow 灵韵是一款面向长篇小说作者的 AI 协作创作工具。它不承诺“一键写完一本书”，也不把作者降级成提示词输入员；它更像创作者案头的磨刀石：帮你收拢灵感、理顺设定、守住伏笔、打磨文字，让 AI 成为想象力的翼，而不是替代想象力的流水线。

## 为什么是 MuseFlow

当平台开始严格清理粗制滥造的 AI 内容，真正的问题并不是“要不要 AI”，而是“谁在主导故事”。MuseFlow 的答案很明确：故事必须属于作者。AI 只负责听懂你的素材，把脑海中散乱的画面整理成可继续书写的文本；人物、世界观、伏笔和取舍，仍然由作者掌控。

中文名“灵韵”取“灵感之神韵”，强调保留原始想法的灵魂，再补上文字的节奏。英文名 MuseFlow 则来自 Muse 与 Flow，意味着创作者借助工具进入稳定心流。

## 为谁而生

- **有故事的“拙”笔**：脑洞很大、世界观很满，却常被开篇、遣词和段落衔接卡住。
- **追求效率的构思者**：不想要千篇一律的 AI 套话，只想让工具帮助管理角色、设定、伏笔和章节节奏。
- **长篇连载作者**：需要在几十章、上百章之后仍然记得每一条暗线、每一次承诺和每个角色的边界。

## 创作旅程与界面示意

下面的图片展示各功能模块。其中**文稿库**（第 1 张）、**灵感捕捉**（第 2 张）、**AI 整理**（第 3 张）、**角色卡**（第 6 张）、**世界观**（第 7 张）、**模板库**（第 8 张）、**Skill 规则**（第 9 张）、**伏笔管理**（第 10 张）、**剧情线**（第 11 张）、**逻辑守护**（第 13 张）、**整理与导出**（第 14 张）、**写作统计**（第 15 张）、**Token 审计**（第 16 张）、**分析报告**（第 17 张）、**报告详情**（第 18 张）、**设置**（第 19 张）、**AI 模型管理**（第 20 张）与 **AI 用语过滤**（第 21 张）为应用真实 widget 渲染截图，由 `test/readme_screenshots/` 下的 golden 测试确定性生成（bundled Noto Sans CJK SC 子集渲染中文，跨平台一致，离线示例数据）；其余为 `scripts/generate_readme_screenshots.mjs` 程序化绘制的设计示意图（SVG → PNG，非运行时渲染）。我们以一名修仙长篇作者的创作旅程为线索，逐一展示灵感捕捉、文稿管理、章节写作、知识库维护、结构守护、数据分析和模型配置。所有图片均使用离线示例数据，不读取任何真实密钥；真实截图正由 golden 测试逐页从示意图迁移。

### 1. 从文稿库开始管理作品

文稿库承载多作品并行创作。作者可以同时维护《剑道苍穹》和其他构思，快速查看题材、目标字数、状态和最近编辑时间。

![文稿库](docs/readme/screenshots/01-manuscript-library.png)

### 2. 捕捉碎片，而不是丢失灵感

灵感捕捉器适合记录突然出现的画面、台词、人物冲突和伏笔种子。标签筛选让碎片在进入正文前先形成可检索的素材池。

![灵感捕捉](docs/readme/screenshots/02-capture-inbox.png)

### 3. 从碎片整理到章节写作

AI 整理把选中的灵感碎片组织成可继续书写的结构化草稿；作者负责接受、修改或重试。

![AI 整理](docs/readme/screenshots/03-ai-organization.png)

章节编辑器提供章节侧栏、正文编辑、工具栏、自动保存和字数统计。AI 在这里是辅助修改与整理的能力，不是接管创作的按钮。

![章节编辑器](docs/readme/screenshots/04-chapter-editor.png)

编辑器 AI 工具栏支持语气改写、段落润色和自由指令，并把结果留给作者确认。

![编辑器 AI 工具栏](docs/readme/screenshots/05-editor-ai-toolbar.png)

### 4. 让角色和世界观成为 AI 的记忆

角色卡保存人物性格、外貌、别名和背景，让 AI 在润色与扩写时知道“林风是谁”“苏雪晴不能怎样说话”。

![角色卡](docs/readme/screenshots/06-knowledge-characters.png)

世界观卡保存规则、势力、地理与技术层级。对修仙、奇幻、科幻这类强设定作品，它是防止逻辑漂移的底座。

![世界观](docs/readme/screenshots/07-knowledge-world.png)

### 5. 用模板快速搭起大世界

模板库把常见类型文的世界搭建经验沉淀为可复用框架。作者不是照抄模板，而是用它缩短从“一个脑洞”到“可写设定集”的距离。

![模板库](docs/readme/screenshots/08-template-gallery.png)

Skill 规则文档进一步约束 AI：境界体系、势力关系、禁忌术语、反 AI 味文风，都可以变成启用中的写作规则。

![Skill 规则](docs/readme/screenshots/09-skill-rules.png)

### 6. 伏笔、剧情线和故事弧一起守住长篇结构

伏笔管理记录“何处埋下、何时回收、当前状态如何”。当连载推进到几十章后，它能提醒作者别忘了早期承诺。

![伏笔管理](docs/readme/screenshots/10-foreshadowing.png)

剧情线以章节为轴组织关键节点，帮助作者看到事件因果、参与角色、写作状态与关联伏笔。

![剧情线](docs/readme/screenshots/11-plot-timeline.png)

故事弧图把节点结构可视化，适合检查起承转合、高潮位置和长线铺垫是否集中或断裂。

![故事弧图](docs/readme/screenshots/12-story-arc.png)

逻辑守护面板关注一致性风险：角色是否越界、设定是否冲突、伏笔是否被遗忘。

![逻辑守护](docs/readme/screenshots/13-logic-guardian.png)

整理与导出负责最终交付前的格式清洗、文稿打包和导出检查。

![整理与导出](docs/readme/screenshots/14-export-cleanup.png)

### 7. 写作过程可以被度量

写作统计让作者看到每日字数、速度趋势、AI 辅助比例和会话数。MuseFlow 不鼓励无脑堆量，但会帮助作者理解自己的节奏。

![写作统计](docs/readme/screenshots/15-writing-stats.png)

Token 审计记录每次 AI 调用的输入、输出、模型和操作类型。对长篇项目而言，成本透明和可控同样重要。

![Token 审计](docs/readme/screenshots/16-token-audit.png)

分析报告中心把成本、痛点、反 AI 味和一致性检查集中在一起，帮助作者从“写完一章”走向“复盘一部作品”。

![分析报告](docs/readme/screenshots/17-reports-hub.png)

报告详情进一步推算短篇、长篇和连载规模下的实际消耗，让创作预算不再靠猜。

![报告详情](docs/readme/screenshots/18-report-details.png)

### 8. 模型与文风由作者掌控

设置页集中管理模型、本地数据和写作统计清理。

![设置](docs/readme/screenshots/19-settings.png)

AI 模型管理支持多供应商和 OpenAI 兼容接口，方便在 OpenAI、Claude、DeepSeek、Ollama 等不同方案间切换。

![AI 模型管理](docs/readme/screenshots/20-ai-providers.png)

AI 用语过滤让作者维护自己的“禁用词表”，持续压低模板化表达和机械总结句。

![AI 用语过滤](docs/readme/screenshots/21-banned-phrases.png)

## 核心能力

- **多文稿与章节管理**：文稿库、章节侧栏、章节级自动保存、章节排序与章节感知导出。
- **灵感捕捉与 AI 整理**：碎片记录、标签筛选、结构化提示管线、局部润色与改写。
- **知识库与规则守护**：角色卡、世界观、模板库、Skill 规则、实体匹配和上下文注入。
- **长篇结构管理**：伏笔生命周期、剧情节点、故事弧图、逻辑守护、格式清洗和导出。
- **数据与成本透明**：写作统计、Token 审计、成本报告、痛点报告、反 AI 味评估和一致性分析。
- **轻量跨平台**：Flutter 实现，本地优先存储；Android、Linux、Windows 是发布目标，Web 作为测试/构建验证目标（产品 UI 功能旅程的完整 UAT 需 Windows 桌面 / Android 设备，尚未覆盖）。

## 技术栈

- Flutter / Dart
- Riverpod
- Hive CE 本地存储
- super_editor 富文本编辑
- go_router 路由
- fl_chart / graphview 可视化
- OpenAI / Claude / DeepSeek / Ollama 多模型适配
- Android / Linux 本地构建验证，Windows GitHub Actions 构建目标，Web 测试构建目标

## 运行与验证

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/core/presentation/active_adapter_wiring_test.dart
flutter build web --release
scripts/check_readme_assets.sh
scripts/check_repo_hygiene.sh
scripts/check_shell_scripts.sh
scripts/check_ai_adapter_wiring.sh
scripts/check_editor_docs.sh
scripts/check_dependency_docs.sh
scripts/check_storage_architecture.sh
scripts/validate_platform_support.sh
```

本 README 的产品展示素材中，**文稿库**（01）、**灵感捕捉**（02）、**AI 整理**（03）、**角色卡**（06）、**世界观**（07）、**模板库**（08）、**Skill 规则**（09）、**伏笔管理**（10）、**剧情线**（11）、**逻辑守护**（13）、**整理与导出**（14）、**写作统计**（15）、**Token 审计**（16）、**分析报告**（17）、**报告详情**（18）、**设置**（19）、**AI 模型管理**（20）与 **AI 用语过滤**（21）为真实 widget 渲染（由 golden 测试生成），其余为 `scripts/generate_readme_screenshots.mjs` 程序化绘制的设计示意图。所有图片使用离线示例数据，不读取真实密钥；真实截图正由 golden 测试逐页迁移。

## 用户旅程实测（v0.1.5）

本节以一次**真实 GLM 百章小说生成**替换了旧版（v1.3）的 HTML 成果站——不再依赖无法在 GitHub 直观呈现的网页，而是用真实数据、精选摘录与可点的章节正文说话。每一章 7000–9000 中文字（不计标点），由产品全栈管线产出：`PromptPipeline` 禁用词注入 → 多段流式生成 → `AntiAIScentProcessor` 反 AI 味 → `DeviationDetectionService` Skill 守护 → `ChapterSummarizationService` 上下文链 → `ForeshadowingRepository` 伏笔生命周期 → `TokenAuditService` 计量。模型按「高性能＋低开销」混用：`glm-4-plus` 开篇 18 个关键章，`glm-4-flash` 承担其余开篇与全部续写、守护、摘要。

- **复现命令**：`GLM_API_KEY=... flutter test test/journey/long_novel_journey_test.dart --name "full run" --concurrency=1`（约 10 小时；缺 key 时该测试自动跳过，不影响 CI）。
- **证据源**：[`long_novel_journey_test.dart`](test/journey/long_novel_journey_test.dart) · 指标 [`metrics.json`](docs/novel-journey/metrics.json) · 伏笔 [`foreshadowing.json`](docs/novel-journey/foreshadowing.json) · 渲染脚本 [`scripts/render_novel_showcase.py`](scripts/render_novel_showcase.py)。
- **全本通读**：[`剑道苍穹-全本.md`](docs/novel-journey/剑道苍穹-全本.md)（100 章合集，GitHub 可整本阅读）；分章正文见下方目录。
- **Notion 托管**：正文当前以仓库 Markdown 呈现（GitHub 可直接阅读）；提供 Notion 凭据后，由 [`scripts/publish_novel_to_notion.py`](scripts/publish_novel_to_notion.py) 自动把每章发布为独立 Notion 页面，目录下追加跳转链接。

### 规模与字数
- **章节数**：100 章（全量真实 GLM 生成，于第 100 章飞升收束）
- **总字数（去标点 CJK）**：821,036 字 · 平均 8,210 字/章 · 区间 [6,972, 8,980]
- **规格合规**：每章 7000–9000 中文字（不计标点，允许 ±500）；补丁续写后 100/100 章落在 [6500, 9500]，其中 99/100 章达 7000+

### 耗时与成本
- **总耗时**：10h3m54s（平均 362.3 秒/章）
- **Token 消耗**：输入 2,983,607 · 输出 1,235,392 · 合计 4,218,999 （513 次 API 调用）
- **模型搭配**（高性能＋低开销混用）：`glm-4-plus` 用于 18 个关键章（开篇/高潮/收束）的开篇；`glm-4-flash` 承担其余开篇与全部续写、守护、摘要

| 模型 | 调用次数 | 输入 token | 输出 token | 单价(输入/输出,¥/百万) | 估算成本 |
|---|---:|---:|---:|---|---:|
| glm-4-flash | 495 | 2,962,728 | 1,190,712 | ¥0.10 / ¥0.10 | ¥0.42 |
| glm-4-plus | 18 | 20,879 | 44,680 | ¥50.00 / ¥50.00 | ¥3.28 |
| **合计** | **513** | **2,983,607** | **1,235,392** | — | **¥3.69** |

> 成本为按公开定价假设的估算（见脚本 `PRICING`），以智谱官方为准；权威指标为实测 Token 数。

### 反 AI 味 · 一致性守护 · 伏笔填坑
- **反 AI 味**：全册标记 8,368 处 AI 腔征兆，其中 8,032 处由同义词表自动净化，其余进入作者复核信号
  - 高频信号：转场套话偏多（94）、叠词/程度副词堆砌（91）、类型文套句偏多（83）、结尾悬念公式化（45）、结构化句式重复（36）
- **Skill 守护（设定一致性）**：全册触发 372 条偏离告警，由偏差检测在生成侧即时拦截
- **伏笔填坑**：埋设 12 条长线伏笔，回收 12 条，填坑率 100%，平均 50.1 章回收

### 精选章节摘录（文笔/高潮）

机器从叙事脊梁（开篇 / 各弧高潮 / 飞升）中各挑一段，完整正文见下方目录的仓库 Markdown 链接。

> **第1章 · 凡人少年**
>
> 山风呼啸，卷起枯叶打着旋儿掠过林风的脚踝。他抡起斧头，青筋在黝黑的手背上凸起，每一次落下都带着山野间特有的沉闷声响。木屑纷飞中，他的眼神却专注，仿佛那棵老槐树不是阻碍，而是值得尊重的对手。
> "吱呀——"槐树应声而倒，轰然倒地的声音惊起了几只林鸟。林风抹去额头的汗水，抬头望向青云山的方向。云雾缭绕间，若隐若现的飞檐斗角如同传说中仙人居住的地方。

> **第30章 · 筑基**
>
> 月光如水，洒在青云峰顶。林风盘膝而坐，手中托着一枚丹药，丹身流转着淡金色光芒，散发出若有若无的草木清香。这是他历经千辛万苦采集灵草，炼制而成的筑基丹。丹药入手温润，仿佛蕴藏着无尽的生命力。
> 夜风拂过，带着山顶特有的寒意，吹动林风的青衫。他将丹药放入口中。丹药入口即化，化作一股温热的气流顺着喉咙滑入丹田。起初只是微微发热，随即那热量开始迅速蔓延，如同点燃了体内的火种。

> **第50章 · 二次结丹**
>
> 丹田内，灵力如江河奔涌。林风盘膝而坐，闭目凝神，感受着体内经脉重塑后的全新状态。每一条经脉都宽阔了数倍，内壁光滑如镜，灵力在其中流淌，再无阻滞。金丹碎片悬浮在丹田中央，散发出柔和的金光，那是他第一次尝试结丹失败后留下的痕迹。
> "准备好了吗？"清虚真人的声音在洞府中响起，平静中带着一丝不易察觉的紧张。
> 林风睁开眼，眸中闪烁着坚定："师尊，弟子已准备就绪。"

> **第75章 · 血战南门**
>
> 血腥味在空气中弥漫，混合着硫磺与焦土的气息。林风的长剑泛着青光，剑尖滴落的鲜血在他脚边汇成细流。南大门的石阶上，躺着三具暗影门弟子的尸体，他们的眼睛圆睁，凝固着的惊骇。
> "林师弟，左翼不稳！"赵天磊的声音从远处传来，带着一丝喘息。他的长剑已经布满缺口，衣袍撕裂处露出几道血痕。
> 林风没有回头，元婴期的感知让他早已察觉战局变化。他身形一晃，剑如游龙，三名偷袭的暗影门弟子咽喉同时出现细线般的血痕。

> **第85章 · 破心魔**
>
> 林风站在幻境中心，四周是无穷无尽的黑暗。他能听见自己的心跳声，沉重而有力，像一面战鼓敲打在胸膛上。汗水从额头滑落，滴在石板上，发出微弱的声响。幻境中的空气黏稠得如同胶水，每一次呼吸都像是吞下了千斤重的铅块。
> "放弃吧。"一个声音在他身后响起，熟悉得让他心头发紧。那是父母的声音，温暖而带着叹息，"你永远无法超越自己的极限，何必执着于此？"
> 林风没有回头。他知道，这是心魔的把戏。他闭上眼睛，感受着指尖的触感——粗糙，真实，带着常年劳作留下的薄茧。这是他作为凡人的印记，也是他力量的源泉。

> **第100章 · 飞升**
>
> 青云峰顶，云海翻涌。
> 林风站在崖边，衣袂被山风吹得猎猎作响。脚下是万丈深渊，远处是连绵的山峦，被一层薄薄的晨雾笼罩。空气中弥漫着灵气与尘埃混合的味道，清冽而厚重。
> "准备好了吗？"苏雪晴的声音从身后传来，温柔如初。
> 林风点点头，目光落在身旁的天衡盘上。那枚古朴的玉盘在晨光中流转着淡蓝色的光晕，表面篆刻的符文仿佛活了过来，缓缓游动。清虚真人已经化作点点灵光，融入了这枚上古神器之中，完成了他千年的宿命。

### 章节目录与正文

每章正文以仓库 Markdown 呈现（GitHub 可直接阅读）；提供 Notion 凭据后，另以 Notion 页面托管。

| 章 | 标题 | 字数 | 正文 |
|---:|---|---:|---|
| 1 | 凡人少年 | 8,635 | [Markdown](docs/novel-journey/chapters/第001章-凡人少年.md) · [Notion](https://excessive-physician-8eb.notion.site/1-397600df78ee8168aeafeb38654b1883) |
| 2 | 山门试炼 | 7,122 | [Markdown](docs/novel-journey/chapters/第002章-山门试炼.md) · [Notion](https://excessive-physician-8eb.notion.site/2-397600df78ee81b99c79e03a5e53ae23) |
| 3 | 入门 | 8,704 | [Markdown](docs/novel-journey/chapters/第003章-入门.md) · [Notion](https://excessive-physician-8eb.notion.site/3-397600df78ee817e8598f6b4c60f0c59) |
| 4 | 灵气初感 | 8,803 | [Markdown](docs/novel-journey/chapters/第004章-灵气初感.md) · [Notion](https://excessive-physician-8eb.notion.site/4-397600df78ee81aaa20bf9da21b7dac9) |
| 5 | 藏经阁 | 8,170 | [Markdown](docs/novel-journey/chapters/第005章-藏经阁.md) · [Notion](https://excessive-physician-8eb.notion.site/5-397600df78ee8113aa35d3b6edb8ae6a) |
| 6 | 无名功法 | 8,741 | [Markdown](docs/novel-journey/chapters/第006章-无名功法.md) · [Notion](https://excessive-physician-8eb.notion.site/6-397600df78ee815b9808ec0b259aafd9) |
| 7 | 练气一层 | 8,737 | [Markdown](docs/novel-journey/chapters/第007章-练气一层.md) · [Notion](https://excessive-physician-8eb.notion.site/7-397600df78ee810c8ceecaba6f1b4b98) |
| 8 | 同门 | 8,407 | [Markdown](docs/novel-journey/chapters/第008章-同门.md) · [Notion](https://excessive-physician-8eb.notion.site/8-397600df78ee81bf8d0dc93aaa5980f3) |
| 9 | 丹房意外 | 8,591 | [Markdown](docs/novel-journey/chapters/第009章-丹房意外.md) · [Notion](https://excessive-physician-8eb.notion.site/9-397600df78ee81339476d652ecaffc74) |
| 10 | 练气三层 | 8,169 | [Markdown](docs/novel-journey/chapters/第010章-练气三层.md) · [Notion](https://excessive-physician-8eb.notion.site/10-397600df78ee811ba181edf471ac793e) |
| 11 | 外门比武 | 8,032 | [Markdown](docs/novel-journey/chapters/第011章-外门比武.md) · [Notion](https://excessive-physician-8eb.notion.site/11-397600df78ee8172b01cc040c80e3480) |
| 12 | 首胜 | 8,200 | [Markdown](docs/novel-journey/chapters/第012章-首胜.md) · [Notion](https://excessive-physician-8eb.notion.site/12-397600df78ee81c9a143f578f1db52a4) |
| 13 | 引起注意 | 7,969 | [Markdown](docs/novel-journey/chapters/第013章-引起注意.md) · [Notion](https://excessive-physician-8eb.notion.site/13-397600df78ee8178b5f8e9c1cace4360) |
| 14 | 秘传 | 8,610 | [Markdown](docs/novel-journey/chapters/第014章-秘传.md) · [Notion](https://excessive-physician-8eb.notion.site/14-397600df78ee8127b71be955c709404a) |
| 15 | 练气六层 | 8,190 | [Markdown](docs/novel-journey/chapters/第015章-练气六层.md) · [Notion](https://excessive-physician-8eb.notion.site/15-397600df78ee8118b675f93fc10da90f) |
| 16 | 灵兽谷 | 8,301 | [Markdown](docs/novel-journey/chapters/第016章-灵兽谷.md) · [Notion](https://excessive-physician-8eb.notion.site/16-397600df78ee815aad19fba8e41753bc) |
| 17 | 灵兽契约 | 8,758 | [Markdown](docs/novel-journey/chapters/第017章-灵兽契约.md) · [Notion](https://excessive-physician-8eb.notion.site/17-397600df78ee81dfb467fb3237883d09) |
| 18 | 内门考核 | 7,217 | [Markdown](docs/novel-journey/chapters/第018章-内门考核.md) · [Notion](https://excessive-physician-8eb.notion.site/18-397600df78ee81aab901d4b71572b2a5) |
| 19 | 第一关 | 8,714 | [Markdown](docs/novel-journey/chapters/第019章-第一关.md) · [Notion](https://excessive-physician-8eb.notion.site/19-397600df78ee816697f6dbe5ff88b884) |
| 20 | 第二关 | 8,506 | [Markdown](docs/novel-journey/chapters/第020章-第二关.md) · [Notion](https://excessive-physician-8eb.notion.site/20-397600df78ee81ae935cf98911e739f3) |
| 21 | 第三关 | 8,942 | [Markdown](docs/novel-journey/chapters/第021章-第三关.md) · [Notion](https://excessive-physician-8eb.notion.site/21-397600df78ee81808e73c1023166ef1d) |
| 22 | 晋升内门 | 8,287 | [Markdown](docs/novel-journey/chapters/第022章-晋升内门.md) · [Notion](https://excessive-physician-8eb.notion.site/22-397600df78ee817388e7c31aa696fa5c) |
| 23 | 内门风波 | 8,509 | [Markdown](docs/novel-journey/chapters/第023章-内门风波.md) · [Notion](https://excessive-physician-8eb.notion.site/23-397600df78ee817d9da6fed3ef37f3f0) |
| 24 | 斗法台 | 8,595 | [Markdown](docs/novel-journey/chapters/第024章-斗法台.md) · [Notion](https://excessive-physician-8eb.notion.site/24-397600df78ee81ff8928f29a94bba22b) |
| 25 | 练气九层 | 8,144 | [Markdown](docs/novel-journey/chapters/第025章-练气九层.md) · [Notion](https://excessive-physician-8eb.notion.site/25-397600df78ee8166868ef96690f22482) |
| 26 | 筑基灵材 | 8,790 | [Markdown](docs/novel-journey/chapters/第026章-筑基灵材.md) · [Notion](https://excessive-physician-8eb.notion.site/26-397600df78ee81209a7be704bb646eae) |
| 27 | 险境 | 8,553 | [Markdown](docs/novel-journey/chapters/第027章-险境.md) · [Notion](https://excessive-physician-8eb.notion.site/27-397600df78ee8143b4dae23d121a208a) |
| 28 | 脱困 | 8,225 | [Markdown](docs/novel-journey/chapters/第028章-脱困.md) · [Notion](https://excessive-physician-8eb.notion.site/28-397600df78ee81e68e3edd8d67d6d19b) |
| 29 | 筑基丹 | 8,468 | [Markdown](docs/novel-journey/chapters/第029章-筑基丹.md) · [Notion](https://excessive-physician-8eb.notion.site/29-397600df78ee819c8eced9d8e3bc2085) |
| 30 | 筑基 | 8,274 | [Markdown](docs/novel-journey/chapters/第030章-筑基.md) · [Notion](https://excessive-physician-8eb.notion.site/30-397600df78ee81939447c7f6e77e0ffd) |
| 31 | 筑基稳固 | 8,836 | [Markdown](docs/novel-journey/chapters/第031章-筑基稳固.md) · [Notion](https://excessive-physician-8eb.notion.site/31-397600df78ee81abb44bc6790f691aac) |
| 32 | 金丹功法 | 8,371 | [Markdown](docs/novel-journey/chapters/第032章-金丹功法.md) · [Notion](https://excessive-physician-8eb.notion.site/32-397600df78ee8179b467d147c176447a) |
| 33 | 王磊阴谋 | 8,514 | [Markdown](docs/novel-journey/chapters/第033章-王磊阴谋.md) · [Notion](https://excessive-physician-8eb.notion.site/33-397600df78ee812eb73eff5e31444169) |
| 34 | 灵矿历练 | 8,613 | [Markdown](docs/novel-journey/chapters/第034章-灵矿历练.md) · [Notion](https://excessive-physician-8eb.notion.site/34-397600df78ee8148a260cf7ebc7b7992) |
| 35 | 矿脉危机 | 7,412 | [Markdown](docs/novel-journey/chapters/第035章-矿脉危机.md) · [Notion](https://excessive-physician-8eb.notion.site/35-397600df78ee81e48a2be3ee8f229ab3) |
| 36 | 灵力凝聚 | 8,681 | [Markdown](docs/novel-journey/chapters/第036章-灵力凝聚.md) · [Notion](https://excessive-physician-8eb.notion.site/36-397600df78ee810b9133c7efa9dc082b) |
| 37 | 天才聚集 | 8,669 | [Markdown](docs/novel-journey/chapters/第037章-天才聚集.md) · [Notion](https://excessive-physician-8eb.notion.site/37-397600df78ee81e59baed3407910f4cf) |
| 38 | 论道争锋 | 8,685 | [Markdown](docs/novel-journey/chapters/第038章-论道争锋.md) · [Notion](https://excessive-physician-8eb.notion.site/38-397600df78ee816b8871c088da4a124d) |
| 39 | 长老质疑 | 8,349 | [Markdown](docs/novel-journey/chapters/第039章-长老质疑.md) · [Notion](https://excessive-physician-8eb.notion.site/39-397600df78ee8157b91af90d4c47cb2d) |
| 40 | 苏雪晴的秘密 | 8,439 | [Markdown](docs/novel-journey/chapters/第040章-苏雪晴的秘密.md) · [Notion](https://excessive-physician-8eb.notion.site/40-397600df78ee8141a53bcca961fe2051) |
| 41 | 结丹前夕 | 8,435 | [Markdown](docs/novel-journey/chapters/第041章-结丹前夕.md) · [Notion](https://excessive-physician-8eb.notion.site/41-397600df78ee811a91f0c0cf8c62de3b) |
| 42 | 凝丹初试 | 8,785 | [Markdown](docs/novel-journey/chapters/第042章-凝丹初试.md) · [Notion](https://excessive-physician-8eb.notion.site/42-397600df78ee81b59e21ebe8ab1d9af1) |
| 43 | 结丹失败 | 7,436 | [Markdown](docs/novel-journey/chapters/第043章-结丹失败.md) · [Notion](https://excessive-physician-8eb.notion.site/43-397600df78ee8138a7dad36e7d6ad41b) |
| 44 | 重伤昏迷 | 8,905 | [Markdown](docs/novel-journey/chapters/第044章-重伤昏迷.md) · [Notion](https://excessive-physician-8eb.notion.site/44-397600df78ee819ba7bfedc4c6748fdb) |
| 45 | 艰难恢复 | 7,023 | [Markdown](docs/novel-journey/chapters/第045章-艰难恢复.md) · [Notion](https://excessive-physician-8eb.notion.site/45-397600df78ee81a28b33e5427b6b7333) |
| 46 | 重塑经脉 | 8,850 | [Markdown](docs/novel-journey/chapters/第046章-重塑经脉.md) · [Notion](https://excessive-physician-8eb.notion.site/46-397600df78ee81aa91f4d4d75b1f6339) |
| 47 | 修为重聚 | 8,684 | [Markdown](docs/novel-journey/chapters/第047章-修为重聚.md) · [Notion](https://excessive-physician-8eb.notion.site/47-397600df78ee8128a936dc9c0afb7e3a) |
| 48 | 真相浮现 | 7,634 | [Markdown](docs/novel-journey/chapters/第048章-真相浮现.md) · [Notion](https://excessive-physician-8eb.notion.site/48-397600df78ee8191be36e472ad101a14) |
| 49 | 神秘共鸣 | 8,323 | [Markdown](docs/novel-journey/chapters/第049章-神秘共鸣.md) · [Notion](https://excessive-physician-8eb.notion.site/49-397600df78ee811b85d8d5c7e470fe8d) |
| 50 | 二次结丹 | 8,640 | [Markdown](docs/novel-journey/chapters/第050章-二次结丹.md) · [Notion](https://excessive-physician-8eb.notion.site/50-397600df78ee815b99c6cc7dae75be88) |
| 51 | 金丹初成 | 7,205 | [Markdown](docs/novel-journey/chapters/第051章-金丹初成.md) · [Notion](https://excessive-physician-8eb.notion.site/51-397600df78ee81ec892ad1842458f708) |
| 52 | 金丹威力 | 7,904 | [Markdown](docs/novel-journey/chapters/第052章-金丹威力.md) · [Notion](https://excessive-physician-8eb.notion.site/52-397600df78ee817da900dee6312d5f11) |
| 53 | 门派暗流 | 8,560 | [Markdown](docs/novel-journey/chapters/第053章-门派暗流.md) · [Notion](https://excessive-physician-8eb.notion.site/53-397600df78ee8191b255e6358a5c508c) |
| 54 | 禁地异动 | 8,694 | [Markdown](docs/novel-journey/chapters/第054章-禁地异动.md) · [Notion](https://excessive-physician-8eb.notion.site/54-397600df78ee814780a7ef91c8b01ec4) |
| 55 | 再结金丹 | 7,337 | [Markdown](docs/novel-journey/chapters/第055章-再结金丹.md) · [Notion](https://excessive-physician-8eb.notion.site/55-397600df78ee811dbc84e0263cbc1147) |
| 56 | 外敌入侵 | 8,591 | [Markdown](docs/novel-journey/chapters/第056章-外敌入侵.md) · [Notion](https://excessive-physician-8eb.notion.site/56-397600df78ee81ef83e8dbde4c3558a0) |
| 57 | 混乱之夜 | 7,634 | [Markdown](docs/novel-journey/chapters/第057章-混乱之夜.md) · [Notion](https://excessive-physician-8eb.notion.site/57-397600df78ee819299cde63fba90a6e2) |
| 58 | 追踪线索 | 7,586 | [Markdown](docs/novel-journey/chapters/第058章-追踪线索.md) · [Notion](https://excessive-physician-8eb.notion.site/58-397600df78ee81c3b3a1e5282a6a1a08) |
| 59 | 深入虎穴 | 7,428 | [Markdown](docs/novel-journey/chapters/第059章-深入虎穴.md) · [Notion](https://excessive-physician-8eb.notion.site/59-397600df78ee8178b50ce5d7019b989c) |
| 60 | 营救 | 8,655 | [Markdown](docs/novel-journey/chapters/第060章-营救.md) · [Notion](https://excessive-physician-8eb.notion.site/60-397600df78ee810f8cbed8d14fe8a2c3) |
| 61 | 劫后余生 | 8,238 | [Markdown](docs/novel-journey/chapters/第061章-劫后余生.md) · [Notion](https://excessive-physician-8eb.notion.site/61-397600df78ee81089713c3b637ed6c96) |
| 62 | 新境感悟 | 8,022 | [Markdown](docs/novel-journey/chapters/第062章-新境感悟.md) · [Notion](https://excessive-physician-8eb.notion.site/62-397600df78ee818d8039c43cf6a76b25) |
| 63 | 暗影门的图谋 | 7,512 | [Markdown](docs/novel-journey/chapters/第063章-暗影门的图谋.md) · [Notion](https://excessive-physician-8eb.notion.site/63-397600df78ee818b9935c0697c12f3fc) |
| 64 | 苏雪晴的秘密 | 7,399 | [Markdown](docs/novel-journey/chapters/第064章-苏雪晴的秘密.md) · [Notion](https://excessive-physician-8eb.notion.site/64-397600df78ee8135a54bd553353c69f3) |
| 65 | 王磊的下场 | 8,332 | [Markdown](docs/novel-journey/chapters/第065章-王磊的下场.md) · [Notion](https://excessive-physician-8eb.notion.site/65-397600df78ee81df98accbc4f6711535) |
| 66 | 禁地探秘 | 8,523 | [Markdown](docs/novel-journey/chapters/第066章-禁地探秘.md) · [Notion](https://excessive-physician-8eb.notion.site/66-397600df78ee8118bf3ee1fac7f8b75a) |
| 67 | 上古传承 | 7,786 | [Markdown](docs/novel-journey/chapters/第067章-上古传承.md) · [Notion](https://excessive-physician-8eb.notion.site/67-397600df78ee81e3b548c5fe8644ba2f) |
| 68 | 身世之谜 | 7,302 | [Markdown](docs/novel-journey/chapters/第068章-身世之谜.md) · [Notion](https://excessive-physician-8eb.notion.site/68-397600df78ee81e48b61e890d9b1ec02) |
| 69 | 元婴感悟 | 8,400 | [Markdown](docs/novel-journey/chapters/第069章-元婴感悟.md) · [Notion](https://excessive-physician-8eb.notion.site/69-397600df78ee8140b828cf74027afa02) |
| 70 | 禁地异变 | 8,734 | [Markdown](docs/novel-journey/chapters/第070章-禁地异变.md) · [Notion](https://excessive-physician-8eb.notion.site/70-397600df78ee813eb0c9c5220437c24a) |
| 71 | 风暴前夜 | 7,168 | [Markdown](docs/novel-journey/chapters/第071章-风暴前夜.md) · [Notion](https://excessive-physician-8eb.notion.site/71-397600df78ee81fc95fefd1f305ba20b) |
| 72 | 凝结元婴 | 8,903 | [Markdown](docs/novel-journey/chapters/第072章-凝结元婴.md) · [Notion](https://excessive-physician-8eb.notion.site/72-397600df78ee813f943df6dac7c9c954) |
| 73 | 元婴战力 | 8,570 | [Markdown](docs/novel-journey/chapters/第073章-元婴战力.md) · [Notion](https://excessive-physician-8eb.notion.site/73-397600df78ee81ac91b1de831152a763) |
| 74 | 战争爆发 | 8,980 | [Markdown](docs/novel-journey/chapters/第074章-战争爆发.md) · [Notion](https://excessive-physician-8eb.notion.site/74-397600df78ee81d0b360f7fa58e4c02a) |
| 75 | 血战南门 | 8,815 | [Markdown](docs/novel-journey/chapters/第075章-血战南门.md) · [Notion](https://excessive-physician-8eb.notion.site/75-397600df78ee8179874bf6361992a5e6) |
| 76 | 赵天磊的选择 | 8,620 | [Markdown](docs/novel-journey/chapters/第076章-赵天磊的选择.md) · [Notion](https://excessive-physician-8eb.notion.site/76-397600df78ee81f7b6a5fb045b0d5b90) |
| 77 | 友宗驰援 | 7,056 | [Markdown](docs/novel-journey/chapters/第077章-友宗驰援.md) · [Notion](https://excessive-physician-8eb.notion.site/77-397600df78ee81188641dd9345aaff7e) |
| 78 | 苏雪晴觉醒 | 8,592 | [Markdown](docs/novel-journey/chapters/第078章-苏雪晴觉醒.md) · [Notion](https://excessive-physician-8eb.notion.site/78-397600df78ee817eac63fe52c96886a7) |
| 79 | 古剑之威 | 8,324 | [Markdown](docs/novel-journey/chapters/第079章-古剑之威.md) · [Notion](https://excessive-physician-8eb.notion.site/79-397600df78ee811a8152c42b90d88b70) |
| 80 | 暗影撤退 | 8,506 | [Markdown](docs/novel-journey/chapters/第080章-暗影撤退.md) · [Notion](https://excessive-physician-8eb.notion.site/80-397600df78ee81ceb442c707c7375ce6) |
| 81 | 心魔初现 | 8,817 | [Markdown](docs/novel-journey/chapters/第081章-心魔初现.md) · [Notion](https://excessive-physician-8eb.notion.site/81-397600df78ee816eb5eec2fae9ea447e) |
| 82 | 心魔加深 | 7,212 | [Markdown](docs/novel-journey/chapters/第082章-心魔加深.md) · [Notion](https://excessive-physician-8eb.notion.site/82-397600df78ee810fb25be3c549652b74) |
| 83 | 心魔困境 | 7,148 | [Markdown](docs/novel-journey/chapters/第083章-心魔困境.md) · [Notion](https://excessive-physician-8eb.notion.site/83-397600df78ee811e8acae8fc48fd70c1) |
| 84 | 本心抉择 | 7,864 | [Markdown](docs/novel-journey/chapters/第084章-本心抉择.md) · [Notion](https://excessive-physician-8eb.notion.site/84-397600df78ee81c5a58dd8d24efb9a58) |
| 85 | 破心魔 | 7,119 | [Markdown](docs/novel-journey/chapters/第085章-破心魔.md) · [Notion](https://excessive-physician-8eb.notion.site/85-397600df78ee811f8d57fecdaf692ffc) |
| 86 | 心魔劫后 | 7,919 | [Markdown](docs/novel-journey/chapters/第086章-心魔劫后.md) · [Notion](https://excessive-physician-8eb.notion.site/86-397600df78ee810090c2eeaf0130e9b0) |
| 87 | 赵天磊和解 | 8,590 | [Markdown](docs/novel-journey/chapters/第087章-赵天磊和解.md) · [Notion](https://excessive-physician-8eb.notion.site/87-397600df78ee81ffa98ec7ecb71e89ba) |
| 88 | 禁地封印崩裂 | 8,755 | [Markdown](docs/novel-journey/chapters/第088章-禁地封印崩裂.md) · [Notion](https://excessive-physician-8eb.notion.site/88-397600df78ee81219540c533e46cdf02) |
| 89 | 清虚真人的使命 | 8,462 | [Markdown](docs/novel-journey/chapters/第089章-清虚真人的使命.md) · [Notion](https://excessive-physician-8eb.notion.site/89-397600df78ee81149f2bf3d761fc4bd6) |
| 90 | 神器现世 | 8,720 | [Markdown](docs/novel-journey/chapters/第090章-神器现世.md) · [Notion](https://excessive-physician-8eb.notion.site/90-397600df78ee81508f8ae294bdabe474) |
| 91 | 天衡碎片 | 8,743 | [Markdown](docs/novel-journey/chapters/第091章-天衡碎片.md) · [Notion](https://excessive-physician-8eb.notion.site/91-397600df78ee81fca7ebe33c0cc22fba) |
| 92 | 宿命之约 | 7,769 | [Markdown](docs/novel-journey/chapters/第092章-宿命之约.md) · [Notion](https://excessive-physician-8eb.notion.site/92-397600df78ee8195a73bf4a012d78180) |
| 93 | 最后的准备 | 7,525 | [Markdown](docs/novel-journey/chapters/第093章-最后的准备.md) · [Notion](https://excessive-physician-8eb.notion.site/93-397600df78ee81c6ab4dd22be77d289b) |
| 94 | 元婴巅峰 | 6,972 | [Markdown](docs/novel-journey/chapters/第094章-元婴巅峰.md) · [Notion](https://excessive-physician-8eb.notion.site/94-397600df78ee81f4b8c1c3238373dfed) |
| 95 | 身世最终揭秘 | 7,296 | [Markdown](docs/novel-journey/chapters/第095章-身世最终揭秘.md) · [Notion](https://excessive-physician-8eb.notion.site/95-397600df78ee81cf9986f45b2ce3314f) |
| 96 | 天劫降临 | 8,122 | [Markdown](docs/novel-journey/chapters/第096章-天劫降临.md) · [Notion](https://excessive-physician-8eb.notion.site/96-397600df78ee818e858dc66600955127) |
| 97 | 第九道天雷 | 8,690 | [Markdown](docs/novel-journey/chapters/第097章-第九道天雷.md) · [Notion](https://excessive-physician-8eb.notion.site/97-397600df78ee81e3bd73e91697de6e45) |
| 98 | 上界之战 | 8,787 | [Markdown](docs/novel-journey/chapters/第098章-上界之战.md) · [Notion](https://excessive-physician-8eb.notion.site/98-397600df78ee813a886df6a0ca8871d7) |
| 99 | 天衡重铸 | 7,104 | [Markdown](docs/novel-journey/chapters/第099章-天衡重铸.md) · [Notion](https://excessive-physician-8eb.notion.site/99-397600df78ee81008142f0e8dfd17141) |
| 100 | 飞升 | 7,399 | [Markdown](docs/novel-journey/chapters/第100章-飞升.md) · [Notion](https://excessive-physician-8eb.notion.site/100-397600df78ee81528227db55cb64b64f) |

## 当作家遇见 AI

反 AI 味是 MuseFlow 的产品灵魂，而非附加功能。这迫使我们直面一个真问题：当 AI 的写作能力不断进化，真正成熟的创作者会作何选择？答案并不统一。

作家**余华**对 GPT 的判断至今锋利：以当下的理解，它“大概能写出中庸的小说，却写不出充满了个性的小说——因为人脑总是要犯错误的，而这恰恰是人脑最可贵的地方”。

**郝景芳**（《北京折叠》作者，继《三体》之后又一位摘得雨果奖的中国作家）给出了另一种回答。她坦言今年新出的小说里，AI 写作的比重已占一半：“编辑还一个劲夸我今年写得好，读者也看不出来哪些部分是 AI 写的。”很长一段时间里，作家被“抓包”用 AI 往往矢口否认；敢于公开承认并引以为荣的，她算少见的一位。

**奥尔加·托卡尔丘克**（2018 年诺贝尔文学奖得主）走得更远。她购入了某款 AI 模型的高级版本，写作时会向它抛出各种问题：故事里的主人公会听什么样的歌？亲爱的，我们该如何把故事写得更精彩？她清楚 AI 在经济学等“硬数据”上会出现幻觉和事实错误，却坚信在文学创作中这项技术拥有“难以置信的优势”——这让不少读者知情后颇感“破防”。

**安东尼·霍洛维茨**（《喜鹊谋杀案》三部曲作者）更像一位谨慎的实用者。他坦言用 AI 写作“像在作弊”，同时也见识过它的笨拙：你问它土豆是什么形状，它答 *ellipsoid*（椭球体）；让它落笔成文，就成了“盘子里的土豆呈椭球体状”这种不伦不类的句子。

从质疑到拥抱，从破防到作弊感，作家们的态度正在分化。MuseFlow 不替作者站队，只守住一条底线：让 AI 听懂你的素材、理顺你的设定、打磨你的文字，而故事最终归属于作者——这恰是余华所说“人脑最可贵的地方”。

> 以上作家言论转引自小黑盒作者“山下热狗”的文章《当雨果奖&诺奖得主开始用AI写作，作为普通人你会坚守还是倒戈？》([原文链接](https://www.xiaoheihe.cn/app/bbs/link/2db772047c7c?h_camp=link&h_session_id=laQc8HhHmBTV48ud&h_src=YXBwX3NoYXJl))。

## 愿景

MuseFlow 灵韵想成为小说作者案头长期可用的 AI 辅助利器：不制造快餐文学，不稀释作者表达，而是在每一次灵感落地、每一次结构复盘、每一次文字打磨中，把“人的温度”留在故事里。
