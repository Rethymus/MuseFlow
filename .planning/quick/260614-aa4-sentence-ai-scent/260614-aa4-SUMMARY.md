---
phase: quick-260614-aa4
plan: 01
subsystem: editor/anti-ai-scent
tags: [anti-ai-scent, nlp, style, detection]
requires: [Phase 19 style_deviation_detector]
provides:
  - SentenceAiScentAnalyzer (逐句 AI 味评分，句局部信号)
metrics:
  duration: ~20 min
  completed: 2026-06-14
  baseline_tests: 1572
  final_tests: 1581
  new_tests: 9
  regressions: 0
---

# Phase quick-260614-aa4: AA-04 句子级 AI 味标记 Summary

新增 `SentenceAiScentAnalyzer`——把 Phase 19 的整体 aiScentScore 下沉到**句子级**，告诉作者"哪句话最 AI"（SenDetEX EMNLP 2025 / LaTeCHCLfL 2026）。整体 detector（5 维）需要多句上下文（节奏/情感曲线），无法逐句；本分析器用**句局部信号**逐句评分 0-100：

| 信号 | 分值 | 触发 |
|------|------|------|
| 机械过渡词起句 | +35 | 然而/此外/综上所述/不仅/值得一提/与此同时/总的来说/换言之/毫无疑问/事实上/众所周知… |
| AI 套式句式 | +35 | 不仅…而且 / 既…又 / 在这个…的时代 / 值得一提的是 / 众所周知 / 毫无疑问 |
| 虚词占比过高 | +35 | 的/了/是/在/和… 功能词 > 40% CJK 字符（content-thin） |
| 超长无断句 | +30 | > 40 CJK 字符且无 、，； 内停顿 |

输出 `SentenceAiScentAnalysis`：按分数降序排列的句子列表 + `worst`（最 AI 句）+ `hasNotable`。`notableThreshold = 30`。

## 设计决策

- **纯逻辑、零副作用**：编辑器高亮 UI（把分数映射到文本 range）留待真机 UAT——本沙箱 super_editor 集成 + CanvasKit 限制下无法视觉验证，纯分析器已可被未来 UI / 报告消费。
- **与整体 detector 正交**：不替换 Phase 19 的 aiScentScore（整体温度计），而是补充"定位"能力——整体分告诉你"这段 AI 味重"，逐句分析告诉你"是这几句"。
- **信号独立可加**：4 个信号互不依赖，clamp [0,100]；一个句子命中多个信号叠加（如"然而，他不仅…而且…"可叠加过渡起句 + AI 套式）。
- **碎片过滤**：< 2 CJK 字符的片段跳过（标点/空白）。

## 验证

- `flutter analyze` → No issues found!
- `flutter test` → 1581 passed, 12 skipped, 0 failed（基线 1572 → +9，零回归）

9 测试覆盖：空文本、人类散文全低分且 hasNotable=false、机械过渡起句、AI 套式、虚词过高、降序排序、worst/null、maxSentences 截断、clamp [0,100]。

## 与 AA-02 协同

AA-02（对比减法）在 prompt 层要求 AI「减去机器味」（含避免机械过渡词/均匀句长）；AA-04 在检测层精确**定位**残留的机器味句子。生成侧（AA-02/03）+ 检测侧（Phase 19 整体 + AA-04 逐句）形成完整闭环。
