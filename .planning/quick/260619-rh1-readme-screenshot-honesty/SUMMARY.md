---
quick_id: 260619-rh1
slug: readme-screenshot-honesty
date: 2026-06-19
status: complete
commits: [17ac897]
---

# README 截图诚实化（fabricated SVG mockup → 显式标注设计示意图）

## 触发

PUA 穷尽侦察（grep 验证非 wishlist 幻影）定位 P1 诚信缺口：README 21 张「可复现 UI 功能截图」
实为**伪造 SVG mockup**——`generate_readme_screenshots.mjs:47-103` 纯 `<rect>`/`<text>` 硬编码 →
`:117 magick SVG→PNG`，零 Flutter 调用；README 却以「UI 取证流程」「扮演作者…逐步完成」「使用
离线演示数据」叙事口吻暗示真实 app 截图，mockup 还硬编码伪数据（500,000 字目标 / 126,480 总字数 /
fake-model）。对核心卖点=「让读者看不出AI的痕迹」（反欺骗）的 v0.1.1 项目，伪造截图冒充真实输出
是真实诚信债。违反系统指令「Report outcomes faithfully」。

关键发现：mockup 自身已留诚实面包屑（`:100-101` FakeAdapter / 截图由可复现脚本生成）——作者本意
诚实，是 README prose 漂移 oversell。本增量**恢复作者本意**，非推翻重做。

## 方案

真实截图需 Windows/Android 设备（Phase 00/14 uat_gap human_needed，沙箱外）→ 保留 mockup 作概念
示意，彻底诚实标注三处：

1. **脚本**：加 header doc comment（mockup 性质 + 生成方式）+ svg() 持久 bottom disclosure line
   「设计示意图 · 脚本生成 · 非应用真实截图（非运行时渲染）」（脱离 README 语境的单图也不可误读）
2. **README.md**：标题「一条真实创作旅程」→「创作旅程与界面示意」；框架段 + footer 段显式「界面
   设计示意图，程序化生成，非应用运行时真实截图，待设备 UAT 后替换」
3. **README.en.md**：mirror（A Real User Journey → User Journey & UI Mockups + 同样显式标注）

## 验证（证据）

| 项 | 结果 |
|----|------|
| 21 图 regen | ✅ node 脚本 exit 0，magick 7.1.2，内置 size≥20KB 检查通过 |
| 图类型 | ✅ PNG 1440x1000 RGBA（file 确认） |
| disclosure 注入 | ✅ 21/21 SVG 含 disclosure 文本（→PNG） |
| disclosure 可见性 | ✅ PIL 像素验证：3 样本图（含最高碰撞风险 editor 04）disclosure 带 `#9a94a5` 像素=310 一致渲染，与 editor 918 底行无碰撞 |
| 旧误导措辞清除 | ✅ grep「UI 取证流程/可复现 UI 功能截图/UI evidence flow/A Real User Journey/一条真实创作旅程」0 命中（zh+en） |
| 新诚实措辞在位 | ✅ zh/en 各 2 行含「非真实截图 / not live screenshots」 |

## 独立审查（omc code-reviewer，no-self-approval）

**APPROVE-after-fix**：0 BLOCKER / 1 MAJOR（已修）/ 3 MINOR。

- **MAJOR（HIGH，已修）**：README.md:148「Web…用于快速验证 README 功能旅程」与诚实化自相矛盾（暗示 21 图是 Web UAT 真实产物）→ 改为「Web 测试/构建验证目标（完整 UAT 需 Win/Android，尚未覆盖）」+ README.en.md mirror。grep 复验旧误导短语 0 命中。
- **MINOR 3（已修）**：line 101 既有「截图由可复现脚本生成」措辞含糊 → 统一为「示意图由脚本绘制」。
- **MINOR 1（记后续，非阻塞）**：disclosure 坐标 y=968 硬编码依赖 `height=1000` 固定布局——当前 21 图稳定，未来加更高卡片需注意；可改 `height - 32` 自适应。
- **MINOR 2（记后续，非阻塞）**：单行 muted disclosure 在「单图被裁切底边/缩略图压缩」边缘场景可能丢失——正常阅读场景 prose+图内双重标注已足够；可后续加 corner MOCK badge 增强。
- **正向**：诚实分层（prose + 图内持久 disclosure）覆盖 README 语境 + 单图转载两路径；header doc 指向 STATE Phase 00/14 uat_gap 可追溯；v1.3 截图性质正确区分未误伤。

## 教训

- 反 AI 味/反欺骗 ethos 先对内：产品 mockup 漂移成「截图」是诚信债，release-prep 必还
- 「可复现」(reproducible) 不足以澄清 mockup vs 真实渲染——必须显式「非真实截图」
- in-image disclosure 比 prose 更不可逃避（单图转载场景）；PIL 像素验证比外部 vision MCP 可靠
  （zai/bigmodel MCP 401/code:1000 已知失效，见 memory `bigmodel-mcp-auth-failure-pattern`）
