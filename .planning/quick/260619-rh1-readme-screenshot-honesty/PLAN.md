---
quick_id: 260619-rh1
slug: readme-screenshot-honesty
date: 2026-06-19
status: complete
---

# README 截图诚实化（fabricated SVG mockup → 明确标注为设计示意图）

## 触发（grep 验证非 wishlist 幻影，PUA 穷尽侦察定位）

PUA 穷尽侦察定位 P1 诚实性缺口：README 21 张「可复现 UI 功能截图」实为**伪造 SVG mockup**。
`scripts/generate_readme_screenshots.mjs:47-103` 纯 `<rect>`/`<text>` 硬编码构造（侧栏 nav、metric 卡、
行、editor 特殊布局全部手画）→ `:117 magick SVG→PNG` 转换，**零 Flutter 调用**。而 README 自称
「UI 取证流程」「扮演修仙作者…逐步完成文稿管理、章节写作」「使用离线演示数据」——叙事口吻强烈暗示
真实 app 交互截图；mockup 还硬编码伪数据（500,000 字目标 / 126,480 总字数 / 738/500,000 字 /
fake-model）。对一个核心卖点是「让读者看不出AI的痕迹」（反欺骗）的 v0.1.1 项目，用伪造截图配伪造
指标冒充真实产品输出是真实诚信问题。违反系统指令「Report outcomes faithfully」。

**关键**：mockup 自身已留诚实面包屑（`:100-101` FakeAdapter / 截图由可复现脚本生成 / 不访问真实
API 密钥）——作者本意诚实，是 README prose 漂移 oversell。本增量**恢复作者本意**：把 prose 对齐到
既有 in-image 诚实，并强化 in-image disclosure。

## 方案（恢复作者本意，非推翻重做——质疑需求 + 删除优先）

真实截图需 Windows 桌面/Android 设备（Phase 00/14 uat_gap human_needed，沙箱外）——保留 mockup
作概念示意，但彻底标注诚实：

1. **README prose 诚实化**（zh + en）：reframe「UI 取证流程」→ 明确「界面设计示意图，程序化生成，
   非应用运行时真实截图」；footer 段同改；section 标题「一条真实创作旅程」→「创作旅程与界面示意」。
2. **in-image disclosure 强化**：脚本 svg() 加一条持久 bottom 内容区 disclosure line
   「设计示意图 · 脚本生成 · 非应用真实截图」，让脱离 README 语境的单图也不可误读。
3. **脚本 header doc comment**：文档化 mockup 性质 + 生成方式（SVG→ImageMagick），便于维护者理解。

## 验证（证据，非嘴说）

- 21 张图 regen 成功（magick 已装 ImageMagick 7.1.2）；脚本内置 size ≥20KB 合理性检查
- `file` 确认 PNG 1440x1000；抽样视觉确认 disclosure 可见
- README zh/en prose 读起来诚实无歧义
- 独立 code-reviewer 审查（no-self-approval 规则）

## 教训

- 反 AI 味/反欺骗 ethos 要先对内：产品 mockup 漂移成「截图」是诚信债，release-prep 必须还
- 「可复现」(reproducible) 一词不足以澄清 mockup vs 真实渲染——必须显式「非真实截图」
- in-image disclosure 比 prose 更不可逃避（单图传播场景）
