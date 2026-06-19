---
quick_id: 260619-rs1
slug: real-screenshot-golden
date: 2026-06-19
status: complete
commits: [10c271a]
---

# README 真实截图迁移 POC（golden 测试渲染真实 ManuscriptLibraryPage，替换 mockup 01）

## 闭环 / 触发

rh1（260619-rh1）把伪造 SVG mockup 显式标注为示意图，还清了诚信债——但最高诚实度是**用真实
渲染替代 mockup**，而非声明它们是假的。本增量建 golden 截图 harness 并迁移最显眼的第 1 张
（文稿库，app 默认屏）为真实 widget 渲染，证明迁移路径可行，为逐页迁移其余 20 张铺路。

从「声明诚实」→「构造诚实」：与其反复解释「这些图是假的」，不如直接把它们变成真的。

## 侦察 + 解阻塞（PUA 穷尽一切）

- **可行性**：`ManuscriptLibraryPage` 是 ConsumerStatefulWidget，渲染路径仅 `watch` 单一
  `manuscriptNotifierProvider`；`ManuscriptCard` 纯 StatelessWidget；`_ManuscriptCardWrapper`
  build() 不 watch 任何 provider（ref 仅长按菜单回调，静态渲染不触发）→ 渲染路径**仅需 override
  单一 provider 喂 seed**，零 Hive / 零章节依赖、零 setUpHiveTest HttpOverrides 陷阱。
- **CJK 阻塞**（golden 测试经典问题）：flutter_test 不读系统字体，默认 Ahem → 中文渲染成 tofu。
  app_theme.dart 用 google_fonts(Noto Sans SC)，`disableGoogleFonts` flag 回退系统字体名——仓库零
  捆绑 CJK 字体。**解阻塞**：`pyftsubset`（fontTools）把 NotoSansCJK-Regular.ttc 的 SC 子字体
  子集化到页面所需字符（~33KB，全部关键字符 cmap 验证在位）→ bundled 进 `test_assets/` →
  测试 FontLoader 注册为 'Noto Sans CJK SC' → theme fontFamily 命中 → 跨平台确定性渲染
  （子集随仓库走，免 google_fonts 网络 / 系统依赖）。
- **时间确定性**：seed 的 `createdAt/updatedAt` 用 `DateTime.now().subtract(...)` 而非固定值——
  `ManuscriptCard._relativeTime` 内部调 `DateTime.now()`，两者相对真实壁钟同步漂移，渲染的
  「2小时前 / 1天前 / 5天前」不随运行时刻漂移（壁钟抵消）。固定 `now` 反而会让相对文本随运行
  时间漂移、CI 炸 golden。

## 方案

1. `test_assets/noto_sans_sc_subset.ttf`（pyftsubset 子集，~33KB）+ OFL 许可声明 `FONT_NOTICE.txt`。
2. `test/readme_screenshots/manuscript_library_test.dart`：
   - `setUpAll` FontLoader 注册子集字体（从 File 路径读，无需 pubspec asset 声明）；
   - override `manuscriptNotifierProvider` 喂 3 seed manuscripts（剑道苍穹/雾海灯塔/雪线旧约，
     合法 genre 仙侠/奇幻/悬疑 + 合法 status 构思中/写作中/已完成——比 mockup 误用的「修仙」
     非预设 genre + 「精修中」误作文稿状态**更正确**）；
   - inline 镜像 `appTheme()` 的 dark 分支（免 dart-define / google_fonts 网络）；
   - 1440×1000 surface；`matchesGoldenFile` 直指 `docs/readme/screenshots/01-manuscript-library.png`
     （golden 即回归断言 **又**是部署产物，一次生成两用）+ `find.text` 断言证数据渲染进树。
3. `docs/readme/screenshots/01-manuscript-library.png`：golden 生成 → 直接替换 mockup。
4. README.md / README.en.md：framework + footer 段诚实化——01 真实渲染 + 其余示意图 + 正逐页迁移。

## 验证（证据）

| 项 | 结果 |
|----|------|
| `flutter test test/readme_screenshots/`（无 --update-goldens，作回归断言） | ✅ `All tests passed!`——golden 与磁盘产物确定性匹配 + `find.text` 4 断言（文稿库/剑道苍穹/雾海灯塔/雪线旧约）`findsOneWidget` 全通过（数据真渲染进树） |
| PIL 像素分析 `01-manuscript-library.png` | ✅ 1440×1000 / **1304 distinct colors**（非空白退化）/ indigo accent #7c3aed = 35034px / 深色 surface = 1319486px / 浅色文字 = 3715px → 真实 Flutter 暗色 UI，非 SVG mockup |
| 字节确认 | HEAD 129830（旧 SVG mockup）→ 磁盘 32925（真实渲染），确认替换发生 |
| `flutter analyze` | ✅ 测试文件 + 全项目 0 issues |
| 视觉确认通道穷尽 | zai MCP 401 / 4_5v 需远程 URL / 无本地 tesseract——故 CJK 字形栅格化正确性由 **FontLoader 加载成功（测试 GREEN）+ cmap 全字在位（FONT_NOTICE）+ find.text 通过（文字入树且可定位）+ Flutter 确定性字体机制** 共同保证，诚实承认无独立视觉像素复核 |

## 教训

- **golden CJK 测试可解**：pyftsubset 子集化 + bundled + FontLoader 注册（免系统/google_fonts
  依赖）→ 确定性 + CI 安全；子集 ~33KB 可接受（仅页面字符）。一次建 harness，逐页迁移成本低。
- **override AsyncNotifierProvider 喂 seed** 可绕过整条 Hive/repository 链——widget 截图测试
  的最简形态，避开 setUpHiveTest 的 flutter_test HTTP mock 拦截真实调用的陷阱。
- **从「声明诚实」到「构造诚实」**：真实渲染 > mockup 声明。与其反复标注「这是假的」，
  不如直接造真的——更诚实，且 golden harness 一次建好可复用。
- **golden 即产物**：`matchesGoldenFile` 直指 `docs/` 路径，测试生成即是部署截图，回归断言
  与产物更新合一，零额外搬运步骤。
