---
quick_id: 260619-rs2
slug: banned-phrases-real-screenshot
date: 2026-06-19
status: complete
commits: [4c94486]
---

# AI 用语过滤（21）真实截图迁移（rs1 harness 复用，逐页迁移第 2 张）

## 闭环

rs1 迁移门面（文稿库 01）后逐页迁移第 2 张：AI 用语过滤（21）——反AI味灵魂页，可视化产品
核心价值的禁词表。双重收益：灵魂页变真实渲染 + 验证 rs1 harness 可复用 + 解除字体子集多页
阻塞（合并子集）。

## 方案（复用 rs1 harness）

1. **合并子集**：pyftsubset 把 library(97 glyphs) + banned(66) 两页字符合并子集化（154 unique /
   48KB），替换 rs1 子集。library 字符保留为超集 → 字形栅格化不变 → rs1 golden 不破坏。
2. **banned 测试**：FontLoader 同一子集 + override `bannedPhrasesProvider` 喂 8 真实 lexicon
   禁词（`AntiAIScentProcessor.synonymKeys` 默认子集，跨总结/强调/逻辑三类诚实反映默认过滤表）
   + inline dark theme（镜像 rs1 `_screenshotTheme`）+ 1440×1000 + matchesGoldenFile 直指
   `docs/21-banned-phrases.png`（golden 即回归断言又即部署产物）+ find.text 4 断言证数据真渲染。
3. **部署 + README**：21.png golden 直接替换 mockup；README zh/en × framework+footer 把 01+21
   标为真实渲染、其余示意图。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter test banned --update-goldens`（生成 golden + 编译 + find.text） | ✅ `All tests passed!`——find.text 4 断言（AI 用语过滤/综上所述/值得注意的是/众所周知）`findsOneWidget` 全通过（数据真渲染进树） |
| `flutter test banned`（无 --update-goldens，回归断言） | ✅ GREEN——golden 与磁盘产物确定性匹配 |
| `flutter test library`（合并子集超集，确认 rs1 golden 不破坏） | ✅ GREEN——字形栅格化不变（超集只多未用 glyph），替换子集安全 |
| PIL 像素分析 `21-banned-phrases.png` | ✅ 1440×1000 / **698 distinct colors**（列表页较「素」合理，非空白退化）/ 浅色文字 1481px 渲染 / 深色 surface 1424035px 主导 / indigo_accent=0（列表页无卡片 accent，是 banned 页 UI 特性非失败）→ 真实 Flutter 暗色 UI，非 SVG mockup |
| 字节确认 | HEAD 129410（旧 SVG mockup）→ 磁盘 41859（真实渲染），确认替换发生 |
| 合并子集覆盖验证 | ✅ 154 glyphs / 48KB，library + banned 全字符 **NONE missing — 两页全覆盖**（fonttools cmap 验证） |
| `flutter analyze test/readme_screenshots/` | ✅ 0 issues |

**CJK 字形栅格化正确性**：FontLoader 加载成功（测试 GREEN）+ cmap 全字在位（fonttools 验证 NONE
missing）+ find.text 通过（文字入树可定位）+ Flutter 确定性字体机制共同保证（与 rs1 同论证链；
视觉通道穷尽无独立像素复核，诚实承认）。

## 教训

- **harness 复用验证**：rs1 的 FontLoader + override-provider 模式直接扩展到第 2 页，零模式
  改动——证明「harness 一次建好，逐页迁移成本低」成立。剩余页可同模式增量迁移。
- **合并子集解除字体阻塞**：rs1 的「子集化到单页字符」在多页迁移时增量失灵；改用「合并多页
  字符」一次子集化，library 字符保留为超集不破坏既有 golden（字形栅格化与未用 glyph 无关）。
  后续迁移每加一页只需把其字符并入合并子集。
- **灵魂页 seed 诚实**：banned 页默认列表 = lexicon synonymKeys，seed 用真实 lexicon 禁词
  （而非编造 demo），与产品「反AI味」核心价值对齐。
- **indigo_accent=0 不是失败**：PIL 像素验证要区分「页面 UI 特性」（列表页本无卡片 accent）
  vs「渲染失败」（空白/tofu）——distinct colors + 文字像素 + find.text 断言共同判真实渲染。
