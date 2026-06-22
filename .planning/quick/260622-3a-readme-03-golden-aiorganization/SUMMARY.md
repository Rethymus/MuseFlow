---
quick_id: 260622-3a
slug: readme-03-golden-aiorganization
date: 2026-06-22
status: complete
commits: []
---

# README #03 AI 整理真实 golden — 交付

第 18 张真实截图：README #03「AI 整理」→ CapturePage + SynthesisPanel 叠加（AI 把碎片整理成
结构化草稿）。**核心产品流**——碎片→草稿的可视化。

## 实现

- CapturePage `showPanel = isStreaming || isEditing || error`。seed synthesisProvider 返回
  `SynthesisState(accumulatedText: <修仙草稿 3 段>, isEditing: true)` → showPanel=true →
  SynthesisPanel 作 Positioned 叠加渲染。
- SynthesisPanel `_buildContentArea`：`isEditing || accumulatedText非空` 分支 → 编辑 TextField
  显示草稿（_editController build 时同步 accumulatedText）。
- **风险评估过保守**（预判 AnimatedContainer+TextField 动画 flake）——实际 clean 连跑 **3 次**
  全 GREEN：①AnimatedContainer 首帧即终态（属性从无→有不经动画），pumpAndSettle 后确定
  ②TextField 无 autofocus→无闪烁光标→无光标 flake ③_editController.text 同步在 build() 确定。
- CapturePage body-only → 测试 `home: Scaffold(body: CapturePage())`（#02 教训兑现）。
- captureProvider 复用 #02 的 fragment seed（面板叠加其上，左侧碎片列表可见）。
- 固定 DateTime（#02 习惯）。

## 验证（六重 + 额外三跑）

- ✅ analyze 0（修 unused import + TextField 内容改 find.byType(TextField) 断言）
- ✅ 首跑 GREEN
- ✅ **clean 连跑 3 次 GREEN**（动画风险页加跑 1 次）— 确定性证实，AnimatedContainer+TextField flake 未发生
- ✅ golden 126077B（mockup → 真实，capture 页+面板叠加富草稿）
- ✅ PIL 1084 色 / 97.1%dark / **light_text 1.5%（迄今最高——面板内 3 段草稿文本）**
- ✅ full-suite +18 All tests passed!
- ✅ README 双语 disclosure 4 处加入「AI 整理(3)/AI organization(3)」

## 教训

- **TextField 内容 find.text 找不到**（v0w 教训兑现）：TextField 文本在 controller 非 Text widget，
  find.text 返回 0。改 find.byType(TextField) 断言编辑分支渲染；草稿文本由 golden 捕获（虽不可
  find.text 断言）。
- **动画 flake 风险须实证而非预判**：AnimatedContainer+TextField 预判高风险，实际 clean×3 确定性——
  AnimatedContainer 首帧终态 + 无 autofocus 光标。风险评估用 clean 多跑验证，别因预判跳过可做页。
- **NotifierProvider（sync）override**：synthesisProvider 是 NotifierProvider<SynthesisNotifier,
  SynthesisState>（build 同步返回），override build 返回 const SynthesisState。

## 进度

已迁 **18/21**：01 / 02 / **03** / 06 / 07 / 08 / 09 / 10 / 11 / 13 / 14 / 15 / 16 / 17 / 18 / 19 /
20 / 21。剩余 3 张：12 故事弧（自定义边缘渲染 viz，像素非确定风险——同 #03 须实证）/ 04-05 editor
（appflowy，记忆标注 WSL2 CanvasKit 渲染边界 + 需 Windows 真机 UAT）。

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
