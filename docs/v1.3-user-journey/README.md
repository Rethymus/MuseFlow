# MuseFlow 灵韵 v1.3 用户旅程成果站

> 想象力为骨，AI 为翼。

本目录收纳 v1.3「用户视角全流程验证 — 百章修仙小说」的可浏览成果。它把原本分散在测试代码、日志和 GSD 文档中的验证结果，整理成可以直接打开的静态展示页。

## 入口

- [成果首页](index.html)
- [《剑道苍穹》百章修仙验证样例](xianxia-100-chapter-sample.html)
- [v1.3 用户旅程验证报告](validation-report.html)
- [章节 JSON 数据](data/chapters.json)

## 数据来源

- `test/journey/helpers/story_outline.dart` — 100 章确定性修仙样例
- `test/journey/full_journey_test.dart` — 世界观到 100 章的端到端旅程测试
- `test/journey/automated_ui_evidence_test.dart` — 自动化旅程证据测试
- `.planning/phases/16-analysis-reports/` — Phase 16 分析报告阶段产物

## 说明

这些页面不依赖构建工具，可直接用浏览器打开。若从 GitHub 代码视图进入，HTML 会以源码形式展示；如需完整视觉效果，可将仓库 clone 到本地后打开 `docs/v1.3-user-journey/index.html`。
