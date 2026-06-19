---
quick_id: 260619-rs3
slug: reports-hub-real-screenshot
date: 2026-06-19
status: complete
commits: [97e4d2b]
---

# 分析报告（17）真实截图迁移 + 通用子集根治 golden 漂移

## 闭环

逐页迁移第 3 张分析报告（17）。reports_hub_page 纯静态（0 provider）。迁移中触发并
根治关键工程问题：**pyftsubset 子集化漂移**。

## 关键发现：pyftsubset 子集化漂移（rs3 触发，根治）

为 reports-hub 扩充合并子集（library+banned 154 → +reports-hub 232 glyphs）后，library/
banned golden 失败。**单独跑也失败**（排除全目录 FontLoader 隔离问题）→ 锁定子集漂移。
根因：**pyftsubset 输出依赖输入字符集**——232 字体的字形轮廓（复合字形分解/轮廓优化）
与 154 微差 → 既有 golden 像素漂移。rs2 时 97→154 巧合未漂移，154→232 暴露。

每次精准扩充子集都漂移既有 golden，需重基线——对剩余 18 张迁移是不可持续的维护负担。

## 方案：固定通用 GB2312 子集（根治）

生成覆盖 **GB2312 全集（一级+二级 ~6763）+ ASCII + CJK 标点 + 全角**的固定通用子集
（7161 chars / 2.9MB），替换精准页面子集：

- 覆盖几乎所有中文 UI 文本 → 后续任何迁移的字符都已在子集 → **不再重子集化 → 永不漂移**。
- 体积 2.9MB（vs 33KB 精准），但测试资产不进 release build，可接受；换取免维护。
- reports-hub 测试：FontLoader + MaterialApp(home: ReportsHubPage()) + golden 直指 docs/17
  （StatelessWidget 无 ProviderScope/override，最简形态）。
- --update-goldens 全目录重基线 3 golden（通用子集下）+ 回归确认全 GREEN。

## 验证（证据）

| 项 | 结果 |
|----|------|
| reports-hub --update-goldens | ✅ GREEN（find.text：分析报告 findsNWidgets(2) + Token成本分析/用户痛点报告/编辑评审团 findsOneWidget）|
| 全目录 --update-goldens 重基线 | ✅ +3 GREEN（library/banned/reports-hub 在通用子集下重新基线）|
| 全目录回归（无 update-goldens） | ✅ +3 GREEN（通用子集下 3 golden 确定性匹配）|
| PIL 3 张真实渲染 | ✅ 01:1317色 / 21:698色 / 17:531色 distinct + light_text(3951/1481/4129) + dark_surface（通用子集微差但真实，非退化）|
| 字节确认 17 | HEAD 123591（旧 SVG mockup）→ 72084（真实渲染）|
| 通用子集覆盖 | ✅ 7161 chars / 2.9MB / 三页+未来中文 **NONE missing** |
| `flutter analyze test/readme_screenshots/` | ✅ 0 issues |

## 教训（重要）

- **pyftsubset 子集化漂移**：每次子集化（不同字符集输入）产生字形轮廓微差 → golden 像素
  漂移。精准页面子集在多页迁移时不可持续（每次扩充漂移既有，需全量重基线）。
- **根治=固定通用子集**：覆盖 GB2312 全集的固定子集，后续不重子集化 → 永不漂移。牺牲体积
  （33KB→2.9MB）换免维护，对多页迁移是正确权衡。
- **纯静态页迁移最简**：StatelessWidget 0 provider，直接 pump 无 override/seed（reports-hub）。
- **回归根因诊断**：单独跑 vs 全目录跑区分隔离问题 vs 子集漂移；单文件失败锁定子集漂移
  （非 FontLoader 隔离），避免误修方向。
