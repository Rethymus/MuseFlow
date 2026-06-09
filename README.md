# MuseFlow 灵韵

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

## 一条真实创作旅程

下面的截图来自 README 专用的可复现 UI 取证流程。我们扮演一名修仙长篇作者，从灵感捕捉开始，逐步完成文稿管理、章节写作、知识库维护、结构守护、数据分析和模型配置。截图使用离线演示数据，不展示真实 API 密钥。

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
- **轻量跨平台**：Flutter 实现，本地优先存储；Android、Linux 已通过本地 release build smoke，Windows 由 GitHub Actions 验证。

## 技术栈

- Flutter / Dart
- Riverpod
- Hive CE 本地存储
- super_editor 富文本编辑
- go_router 路由
- fl_chart / graphview 可视化
- OpenAI / Claude / DeepSeek / Ollama 多模型适配
- Android / Linux 本地构建验证，Windows GitHub Actions 构建目标

## 运行与验证

```bash
flutter pub get
flutter analyze
flutter test
```

本 README 使用 `docs/readme/screenshots/` 下的 21 张可复现 UI 功能截图作为产品展示素材。截图由 `scripts/generate_readme_screenshots.mjs` 生成，使用离线演示数据，不读取真实密钥。

## v1.3 用户旅程成果站

- [打开 v1.3 静态成果站](docs/v1.3-user-journey/index.html)
- [阅读《剑道苍穹》百章修仙验证样例](docs/v1.3-user-journey/xianxia-100-chapter-sample.html)
- [查看 v1.3 用户旅程验证报告](docs/v1.3-user-journey/validation-report.html)
- [查看章节 JSON 数据](docs/v1.3-user-journey/data/chapters.json)

GitHub 代码视图会以源码方式展示 HTML；如需完整视觉效果，请 clone 仓库后在浏览器中打开 `docs/v1.3-user-journey/index.html`。

## 愿景

MuseFlow 灵韵想成为小说作者案头长期可用的 AI 辅助利器：不制造快餐文学，不稀释作者表达，而是在每一次灵感落地、每一次结构复盘、每一次文字打磨中，把“人的温度”留在故事里。
