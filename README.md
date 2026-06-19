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

下面的图片展示各功能模块。其中**文稿库**（第 1 张）、**分析报告**（第 17 张）与 **AI 用语过滤**（第 21 张）为应用真实 widget 渲染截图，由 `test/readme_screenshots/` 下的 golden 测试确定性生成（bundled Noto Sans CJK SC 子集渲染中文，跨平台一致，离线示例数据）；其余为 `scripts/generate_readme_screenshots.mjs` 程序化绘制的设计示意图（SVG → PNG，非运行时渲染）。我们以一名修仙长篇作者的创作旅程为线索，逐一展示灵感捕捉、文稿管理、章节写作、知识库维护、结构守护、数据分析和模型配置。所有图片均使用离线示例数据，不读取任何真实密钥；真实截图正由 golden 测试逐页从示意图迁移。

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
flutter analyze
flutter test
flutter build web --release
```

本 README 的产品展示素材中，**文稿库**（01）、**分析报告**（17）与 **AI 用语过滤**（21）为真实 widget 渲染（由 golden 测试生成），其余为 `scripts/generate_readme_screenshots.mjs` 程序化绘制的设计示意图。所有图片使用离线示例数据，不读取真实密钥；真实截图正由 golden 测试逐页迁移。

## v1.3 用户旅程成果站

v1.3 以「百章修仙小说用户旅程验证」为核心，把分散在测试代码与日志里的验证结果整理成可直接阅读的成果。下方为成果站的视觉预览与关键结论；完整可交互版（深色主题、章节目录导航、实时数据）可 clone 仓库后在浏览器打开 [`index.html`](docs/v1.3-user-journey/index.html)。

### 成果站首页

![v1.3 成果站首页](docs/v1.3-user-journey/screenshots/index.png)

**关键指标**　章节规模 **100**　·　验证阶段 **Phase 12–16**　·　自动化测试 **1169+**　·　状态 **已通过**

### 验证链路

代入「有故事但拙于表达」的用户视角，MuseFlow 完成从世界观到百章导出的完整创作闭环：

```mermaid
flowchart LR
    A["世界观搭建<br/>修仙模板 · 角色卡 · Skill 守护"] --> B["碎片捕捉与整理<br/>PromptPipeline"]
    B --> C["开篇引导<br/>场景 / 人物 / 悬念"]
    C --> D["百章章节流<br/>300–500 字边界"]
    D --> E["故事结构与导出<br/>伏笔生命周期 · MD/TXT/JSON"]
    E --> F["分析报告<br/>Token · 痛点 · 反 AI 味 · 一致性"]
```

### 验证结果

![v1.3 验证报告](docs/v1.3-user-journey/screenshots/validation-report.png)

- ✅ `flutter analyze` 无问题
- ✅ `flutter test` 全套通过（`All tests passed!`）
- ✅ 确定性用户旅程测试完成 100 章流程
- ⚠️ 缺少 `GLM_API_KEY` / `OPENAI_API_KEY` 时，真实外部模型测试按预期跳过

### 《剑道苍穹》百章样例预览

![百章修仙样例](docs/v1.3-user-journey/screenshots/xianxia-sample.png)

样例展示凡人入门 → 筑基 → 金丹 → 元婴 → 飞升的 100 章确定性大纲，用于验证链路闭环与输出边界。它是**效果参考与验收材料，不代表最终文学出版稿**。

### 完整交互版与证据源

- 可交互页面：[成果首页](docs/v1.3-user-journey/index.html) · [百章样例](docs/v1.3-user-journey/xianxia-100-chapter-sample.html) · [验证报告](docs/v1.3-user-journey/validation-report.html)
- [章节 JSON 数据](docs/v1.3-user-journey/data/chapters.json)（来源：`test/journey/helpers/story_outline.dart`）
- 测试证据：[`full_journey_test.dart`](test/journey/full_journey_test.dart) · [`automated_ui_evidence_test.dart`](test/journey/automated_ui_evidence_test.dart)

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
