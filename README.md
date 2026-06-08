# MuseFlow 灵韵

> 想象力为骨，AI 为翼。

MuseFlow 灵韵是一个人机协作、去流水线化、轻量跨平台的小说创作辅助工具。它不是替代作者写故事的“一键生成器”，而是帮助创作者理顺思绪、打磨文字、维护设定一致性的“磨刀石”。

**核心价值：让 AI 帮你写好故事，但让读者看不出 AI 的痕迹。**

## v1.3 用户旅程成果站

v1.3 以真实用户视角验证完整创作链路：从修仙世界观搭建、碎片捕捉、AI 整理、开篇引导、章节生成、故事结构守护、格式清洗，到导出和分析报告。

- [打开 v1.3 静态成果站](docs/v1.3-user-journey/index.html)
- [阅读《剑道苍穹》百章修仙验证样例](docs/v1.3-user-journey/xianxia-100-chapter-sample.html)
- [查看 v1.3 用户旅程验证报告](docs/v1.3-user-journey/validation-report.html)
- [查看章节 JSON 数据](docs/v1.3-user-journey/data/chapters.json)

> 说明：GitHub 代码视图会以源码方式展示 HTML；如需完整视觉效果，请 clone 仓库后在浏览器中打开 `docs/v1.3-user-journey/index.html`。

## 当前成果

- ✅ **v1.0 MVP**：碎片捕捉、AI 整理、沉浸式编辑器、知识库、Skill 设定守护、故事结构、导出。
- ✅ **v1.1 创作体验升级**：预设世界观模板库、开篇引导、写作数据统计、故事弧可视化。
- ✅ **v1.2 多文稿架构**：文稿库、章节管理、章节级自动保存、章节感知导出。
- ✅ **v1.3 用户视角全流程验证**：Token 审计、自动化测试框架、百章修仙用户旅程、分析报告中心。

## 技术栈

- Flutter / Dart
- Riverpod
- Hive CE 本地存储
- super_editor 富文本编辑
- OpenAI / Claude / DeepSeek / Ollama 多模型适配
- Windows / Android 跨平台目标

## 验证状态

当前主线已通过：

```bash
flutter analyze
flutter test
```

最近一次完整验证结果：`flutter analyze` 无问题，`flutter test` 全部通过；缺少外部 API Key 的真实模型测试按预期跳过。

## 项目理念

MuseFlow 面向“有故事但拙于表达”的创作者，强调：

1. 作者主导，AI 辅助。
2. 强制分段交互，不提供“一键生成全书”。
3. 本地优先，配置与文稿保存在本地。
4. 通过知识库、角色卡、Skill 设定守护和故事结构层，降低长篇创作中的人设崩塌与逻辑漂移。
5. 将“反 AI 味”作为产品灵魂，而不是附加功能。

## 开发入口

```bash
flutter pub get
flutter analyze
flutter test
```

更多项目规划与阶段记录见 `.planning/`。
