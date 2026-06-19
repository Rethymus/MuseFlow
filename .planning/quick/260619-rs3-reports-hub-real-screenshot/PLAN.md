---
quick_id: 260619-rs3
slug: reports-hub-real-screenshot
date: 2026-06-19
status: complete
commits: [97e4d2b]
---

# 分析报告（17）真实截图迁移 + 通用子集根治 golden 漂移

## 触发

rs2 后逐页迁移第 3 张：分析报告（17）——百章创作验证四维分析入口。
reports_hub_page 是纯静态 StatelessWidget（0 provider），迁移最简形态。迁移过程中
触发并根治一个关键工程问题：**pyftsubset 每次子集化（不同字符集）产生字形栅格化
微差 → golden 漂移**。

## 侦察

- **reports_hub_page 纯静态**：`extends StatelessWidget`，0 ref.watch，5 个 ReportCard
  硬编码 title/description/icon，onTap 静态渲染不触发。迁移最简：直接 pump，无
  ProviderScope/override/seed。
- **漂移发现（PUA 诊断）**：为 reports-hub 扩充合并子集（library+banned 154 → +reports-hub
  232 glyphs）后，library/banned golden 失败。单独跑 banned/library 也失败（排除全目录
  FontLoader 隔离问题）→ 锁定**子集漂移**。根因=pyftsubset 输出依赖输入字符集，232 字体
  的字形轮廓（复合字形分解/轮廓优化）与 154 微差 → 既有 golden 像素漂移。rs2 时 97→154
  巧合未漂移，154→232 暴露。每次精准扩充子集都漂移既有 golden，需重基线——不可持续。

## 方案（根治：固定通用子集）

1. 生成覆盖 **GB2312 全集（一级+二级 ~6763）+ ASCII + CJK 标点 + 全角**的固定通用子集
   （7161 chars / 2.9MB），替换精准页面子集。覆盖几乎所有中文 UI → 后续迁移不再重
   子集化 → 永不漂移。
2. reports-hub 测试：FontLoader + MaterialApp(home: ReportsHubPage()) + matchesGoldenFile
   直指 docs/17（StatelessWidget 无需 ProviderScope）。
3. --update-goldens 全目录重基线 3 golden（通用子集下）+ 回归确认全 GREEN。
4. FONT_NOTICE 更新（通用子集描述 + regenerate 命令）。README zh/en 加 17。

## 验证

见 SUMMARY.md。
