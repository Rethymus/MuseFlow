---
status: partial
phase: 16-analysis-reports
source: [16-VERIFICATION.md]
started: 2026-06-08T16:38:27Z
updated: 2026-06-08T16:38:27Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. 报告中心四卡片导航人工验收
expected: 在运行中的 Flutter 应用中进入 `/stats/reports`，逐一打开 4 个报告卡片；四个详情页均可从报告中心进入，返回/导航无卡死，页面内容符合 UI 预期。
result: [pending]

### 2. 反AI味盲读交互人工验收
expected: 在已有章节内容的环境中打开“反AI味评估”，点击“开始盲读”，对若干段落选择“AI 生成 / 人写的 / 跳过”，段落逐条展示，进度推进正确，跳过不计入已判断数，完成后显示辨识率、正确数和解释文案。
result: [pending]

### 3. 真实 100 章知识库一致性报告人工验收
expected: 用真实 100 章修仙文稿和真实角色卡/设定集生成“知识库一致性分析”报告；整体一致性、每 10 章趋势、角色/设定检查和警报能帮助识别知识库衰减，误报/漏报在可接受范围。
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
