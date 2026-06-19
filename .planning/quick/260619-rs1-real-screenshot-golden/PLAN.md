---
quick_id: 260619-rs1
slug: real-screenshot-golden
date: 2026-06-19
status: in-progress
---

# README 真实截图迁移 POC（golden 测试渲染真实 ManuscriptLibraryPage，替换 mockup 01）

## 触发（rh1 诚实化的进阶——从「诚实声明」到「诚实构造」）

rh1 把伪造 SVG mockup 显式标注为示意图，还清了诚信债。但最高诚实度是**用真实渲染替代
mockup**，而非声明它们是假的。本增量建 golden 截图 harness 并迁移最显眼的第 1 张（文稿库，
app 默认屏）为真实 widget 渲染，证明迁移路径可行，为逐页迁移其余 20 张铺路。

## 侦察 + 解阻塞（PUA 穷尽一切）

- 可行性：ManuscriptLibraryPage 是 ConsumerStatefulWidget 仅 watch `manuscriptNotifierProvider`；
  ManuscriptCard 纯 StatelessWidget；_ManuscriptCardWrapper build() 不 watch 任何 provider（ref 仅
  长按菜单回调，静态渲染不触发）→ 渲染路径**仅需 override 单一 provider 喂 seed**，零 Hive/零章节依赖。
- **CJK 阻塞**（golden 测试经典问题）：flutter_test 不读系统字体，默认 Ahem → 中文渲染成 tofu。
  app_theme.dart 用 google_fonts(Noto Sans SC)，`disableGoogleFonts` flag 回退系统字体名——仓库零
  捆绑 CJK 字体。**解阻塞**：`pyftsubset`（fontTools 4.62.1 可用）把 NotoSansCJK-Regular.ttc 的 SC
  子字体（索引 2）子集化到页面所需字符（~33KB，全部关键字符 cmap 验证在位）→ bundled 进
  test_assets/ → 测试 FontLoader 注册为 'Noto Sans CJK SC' → theme fontFamily 命中 → 跨平台确定性
  渲染（子集随仓库走，免 google_fonts 网络/系统 CJK 依赖）。

## 方案

1. `test_assets/noto_sans_sc_subset.ttf`（pyftsubset 子集，~33KB）+ OFL 许可证随附
2. `test/readme_screenshots/manuscript_library_test.dart`：FontLoader 注册子集字体；override
   manuscriptNotifierProvider 喂 3 seed manuscripts（剑道苍穹/雾海灯塔/雪线旧约，修仙 mockup 用了
   非预设 genre「修仙」+ 章状态「精修中」误作文稿状态——真实渲染改用合法 仙侠/奇幻/悬疑 + 构思中/
   写作中/已完成，更正确）；inline 镜像 appTheme() dark 分支（免 dart-define/google_fonts）；
   1440x1000；matchesGoldenFile + find.text 断言（证数据渲染进树）
3. 部署 staging golden → docs/readme/screenshots/01-manuscript-library.png 替换 mockup
4. README.md/en.md framework+footer 段诚实化：01 真实渲染 + 其余示意图 + 正逐页迁移

## 验证（证据）

- `flutter test ... --update-goldens`：+1 GREEN，生成 staging golden（1440x1000 PNG）
- 无 --update-goldens 重跑：+1 GREEN（find.text 断言通过 + golden 确定性匹配 = 回归断言成立）
- `flutter analyze` 测试文件 0 issues
- PIL：88 distinct colors + 紫色 accent #7c3aed + 深色 surface = 真实渲染 UI（非空白）
- 部署 01 size 121901→32925（确认非原 SVG mockup）
- 视觉确认通道穷尽（zai MCP 401 / 4_5v 需远程 URL / 无 tesseract / puppeteer 未内联返回图像）；
  CJK 字形栅格化正确性由 FontLoader 成功 + cmap 全字在位 + Flutter 确定性字体机制 + find.text 数据
  在树 共同保证

## 教训

- golden CJK 测试可解：pyftsubset 子集化 + bundled + FontLoader 注册（免系统/google_fonts 依赖）→
  确定性 + CI 安全；子集 ~33KB 可接受（仅页面字符）
- override AsyncNotifierProvider 喂 seed 可绕过整条 Hive/repository 链（无 setUpHiveTest HttpOverrides
  陷阱）——widget 截图测试的最简形态
- 从「声明诚实」到「构造诚实」：真实渲染 > mockup 声明；golden harness 一次建好，逐页迁移成本低
