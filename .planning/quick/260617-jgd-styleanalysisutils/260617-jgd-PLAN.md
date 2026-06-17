---
phase: quick-260617-jgd
plan: 01
type: refactor
wave: 1
depends_on: []
files_modified:
  - lib/features/editor/application/style_analysis_utils.dart   # NEW
  - lib/features/editor/application/style_deviation_detector.dart
  - lib/features/editor/application/style_analyzer.dart
  - test/features/editor/application/style_analysis_utils_test.dart   # NEW
autonomous: true
requirements: [AA-CONSISTENCY, DRIFT-PREVENTION]
tags: [anti-ai-scent, style-deviation, dual-ruler, refactor, dedup, drift-prevention]
status: ready-to-execute
---

# quick-260617-jgd: 抽共享 StyleAnalysisUtils 根治双量尺漂移复发

## 背景（双量尺战役已闭合 3 维，本任务是结构性根治）

style_deviation_detector.dart（AI 文本测量方）与 style_analyzer.dart（profile 基线构建方）
**逐字重复了同一套维度计算逻辑**。过去一周（05c/1uk/f7l/hnl/j0z 五个 quick 任务）连续发现
因"两份副本单边改动"导致的双量尺漂移 bug（公式/门槛不一致→稀薄测量对比稳健基线→偏差分
扭曲，反AI味核心信号）。逐维补丁已穷尽（见 [[dual-ruler-campaign-all-dimensions-closed]]），
但**根因——代码重复——仍在**。本任务抽共享 util，从结构上消灭整类复发。

## 证据（orchestrator 已逐字确认重复）

两文件以下方法逻辑**逐字一致**（仅注释/`static` vs 实例/方法名差异）：

| 方法 | detector 位置 | analyzer 位置 | 状态 |
|------|--------------|--------------|------|
| `_extractCjkChars` | :508 | :380 | rune 范围 0x4E00-9FFF/0x3400-4DBF/0x3000-303F 逐位一致 |
| CJK 计数 | 内联 `_extractCjkChars().length` | `_cjkCharCount`(:377) | 等价 |
| `_extractSentenceLengths` | :391 | :102 | 正则 `[。！？；\n]+` 一致，map/where 一致 |
| `_computeRhythmScore` | :399(已对齐 `<5`) | :143(`<5`) | 公式 avg/var/cv/clamp 一致（hnl 刚统一门槛） |
| vocab richness | `_analyzeVocabulary` 内联(:237,已对齐 `<50`) | `_computeVocabularyRichness`(:165,`<50`) | 公式 `((ratio-0.25)/0.30).clamp` 一致（j0z 刚统一门槛） |

**非完全一致（本次不合并，留原处）**：
- `_computeEmotionalTone`：detector(f7l) 已全部委托 SentimentLexicon，analyzer 也是；逻辑
  已同源但结构差异大（detector 在 _analyzeEmotionalTone 内），合并收益低、风险高，**不动**。
- `_computeRhetoricHabits`：两文件此刻一致，但返回 RhetoricHabits 值对象、含分类启发式，
  合并需谨慎确认 100% 等价；**本任务先不合并**（列为后续可选）。
- `_computeSentenceStats`（仅 analyzer 有，detector 用 _analyzeSentenceLength 直接对比）：
  职责不同，不合并。

## 方案

新建 `lib/features/editor/application/style_analysis_utils.dart`（纯 Dart，application 层，
同 style_analyzer.dart:19 既有 application 内聚先例），抽出 4 个**已确认逐字一致**的纯函数为
`static` 方法（无状态、无副作用，适合 static 工具类）：

```dart
class StyleAnalysisUtils {
  /// CJK 统一表 + 扩展 A + CJK 符号范围。
  static List<String> extractCjkChars(String text) { ... }   // ← 逐字搬 analyzer:380
  static int cjkCharCount(String text) => extractCjkChars(text).length;
  static List<int> extractSentenceLengths(String text) { ... } // ← 逐字搬 analyzer:102
  static double computeRhythmScore(List<int> lengths) { ... }  // ← 逐字搬 analyzer:143（含 <5 门槛）
  static double computeVocabularyRichness(String text) { ... } // ← 逐字搬 analyzer:165（含 <50 门槛）
}
```

**改造两消费方**（零行为变更，机械委托）：
- `style_analyzer.dart`：5 处私有方法改为 `return StyleAnalysisUtils.xxx(...)` 一行委托
  （保留私有方法签名做向后兼容，或直接 inline 替换调用点——执行时择优，保 analyze 0 + 测试绿）。
- `style_deviation_detector.dart`：`_extractCjkChars`/`_extractSentenceLengths`/rhythm/vocab
  改委托 `StyleAnalysisUtils`。**detector 删自己的副本**（这正是结构根治——从此 detector 不
  再持有第二把尺子）。

**关键不变量**：抽取后 detector 与 analyzer 对 rhythm/vocab 的计算**必须来自同一函数**——
这是双量尺漂移的结构性终结。grep 应确认两文件不再各自定义 `_computeRhythmScore`/
`_computeVocabularyRichness`/`_extractCjkChars` 的独立实现。

## TDD（先写 util 单元测试，锁不变量）

新建 `style_analysis_utils_test.dart`，对 5 个 static 方法写针对性测试（CJK 抽取范围、
句长正则切分、rhythm CV→clamp、vocab ratio→clamp、各方法 sub-threshold 返回 0.5 的门槛）。
这些测试锁死**单一权威实现**的行为，未来任一消费方改动都无法绕过。

**回归门**（执行后必过，证零行为变更）：
- `flutter analyze` 0
- `flutter test test/features/editor/` 全量绿（detector 21 + analyzer 全量 + editor feature 291）

## 为什么是这个任务（PUA 主动出击 / 预防）

修 bug 不是终点（pua 铁律三）。05c→j0z 五个补丁都在治标（逐维对齐），本任务治本
（消灭重复源）。完成后双量尺漂移从"需要人盯每个维度"降级为"结构上不可能"（两方共用一函数）。

## 执行入口

`/gsd:quick resume styleanalysisutils` 或直接派发 gsd-executor。预期 commit：
- `refactor(quick-260617-jgd): 抽 StyleAnalysisUtils 共享 CJK/句长/rhythm/vocab 计算`
- `refactor(quick-260617-jgd): detector/analyzer 委托 StyleAnalysisUtils，删重复副本`
- `test(quick-260617-jgd): StyleAnalysisUtils 单元测试锁不变量`

## 状态

**诊断完成，待执行**。因主会话上下文 74%（临界），仅预派发 PLAN，留待新会话 resume 执行，
避免重构半途耗尽上下文导致重复逻辑两处不一致的悬空状态（比 bug 更难收拾）。
