---
quick_id: 260619-rs2
slug: banned-phrases-real-screenshot
date: 2026-06-19
status: complete
commits: [4c94486]
---

# AI 用语过滤（21）真实截图迁移（rs1 harness 复用，逐页迁移第 2 张）

## 触发

rs1（260619-rs1）建好 golden 截图 harness 并迁移门面（文稿库 01）后，PLAN 明言「harness
一次建好为逐页迁移其余 20 张铺路」。本增量迁移第 2 张：**AI 用语过滤（21）**——反AI味灵魂页，
直接可视化产品核心价值「让 AI 帮你写好故事，但让读者看不出 AI 痕迹」的禁词表。

双重目的：①把产品灵魂页变成真实渲染（边际价值最高的下一张）；②验证 rs1 harness 可复用
扩展到多页 + 解除字体子集阻塞（合并子集覆盖多页），为剩余迁移降本。

## 侦察 + 解阻塞（PUA 穷尽一切）

- **可行性**：`BannedPhraseSettingsPage extends ConsumerWidget`，渲染路径仅
  `ref.watch(bannedPhrasesProvider)`（单一 `NotifierProvider<_, AsyncValue<List<String>>>`），
  与 rs1 library 完全同构——override 喂 seed 即绕过 settingsRepository/Hive 持久化链。
- **seed 诚实性**：真实默认 banned list = `AntiAIScentProcessor.synonymKeys`（lexicon Map keys）。
  从 `anti_ai_scent_lexicon.dart` 选 8 个跨三类（总结/强调/逻辑）真实禁词（综上所述/总而言之/
  值得注意的是/需要指出的是/毫无疑问/不可否认/众所周知/换言之）——是真实默认子集，非编造。
- **CJK 阻塞升级**（PUA 揪头发）：rs1 子集仅 97 glyphs（针对 library 页字符），banned 页关键
  字符（'A','I','用','语','过','滤'...）几乎全缺。rs1 的「FONT_NOTICE 子集化到页面字符」设计
  在多页迁移时暴露增量问题。**解阻塞**：pyftsubset 生成 **library + banned 两页合并子集**
  （154 glyphs / 48KB），library 字符保留为**超集**（字形栅格化不变 → rs1 golden 不破坏），
  banned 字符新增覆盖。源字体 `/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc` 系统已装
  （fc-list 确认，font-number=2 = SC 对齐 rs1）。

## 方案

1. `test_assets/noto_sans_sc_subset.ttf`：pyftsubset 重生合并子集（library 97 + banned 66 →
   154 unique glyphs），替换 rs1 子集。
2. `test/readme_screenshots/banned_phrase_settings_test.dart`：FontLoader 同一子集 +
   override `bannedPhrasesProvider` 喂 8 真实禁词 + inline dark theme（镜像 rs1）+
   1440×1000 + matchesGoldenFile 直指 `docs/21-banned-phrases.png` + find.text 4 断言。
3. `docs/readme/screenshots/21-banned-phrases.png`：golden 生成 → 直接替换 mockup。
4. README.md/en.md：framework + footer 段诚实化——01 + 21 真实渲染 + 其余示意图。

## 验证

见 SUMMARY.md。
