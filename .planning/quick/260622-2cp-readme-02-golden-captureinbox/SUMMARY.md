---
quick_id: 260622-2cp
slug: readme-02-golden-captureinbox
date: 2026-06-22
status: complete
commits: []
---

# README #02 灵感捕捉真实 golden — 交付

第 9 张真实截图：README #02「灵感捕捉」→ CapturePage（碎片捕捉工作区）。首个**创作页**
迁移（输入框 + 标签筛选 chip + 碎片列表 + "AI 整理"按钮）。剩余 12 张。

## 接手即跑 → 暴露两个真实 bug

`capture_test.dart` 由前会话写好但未跟踪、未跑通。接手首跑 **RED**，连环暴露两个根因：

### Bug 1（build RED）：No Material widget found

CapturePage 直接返回 `Stack → Column`，**无 Scaffold/Material 祖先**。TextField
(capture_page.dart:113) 与 FilterChip (:204) 需要 Material 祖先 → 7 个 build 异常 +
Column 溢出 499033px（TextField/FilterChip 退化成 error box 的下游假象，非真溢出）。

为何前 8 张不炸：ManuscriptLibraryPage 等内含**自己的** Scaffold；CapturePage 是
**body-only** widget，真实 app 由 AppShellScaffold 的 Scaffold 宿主
（`Scaffold(body: Row[sidebar, ..., Expanded(CapturePage)])`，无 AppBar）。

修：测试 `home:` 用 `Scaffold(body: CapturePage())` 镜像真实 shell 宿主
（与 #01-21 一致只渲页面本身不渲 sidebar，桌面布局无 AppBar）。

### Bug 2（golden flaky，第 2 次失败 L2）：时间戳绝对时间漂移

GREEN 后回归失败：`02-capture-inbox.png` 0.02% 250px diff，**run-to-run 非确定**
（重生也救不了——下次跑又差）。diff PIL 定位：全部集中在 **x[1402-1406]（碎片卡片
右边缘时间戳列）× 6 卡片 y[162-660]**，像素数每次变（250→286→~68）。

根因：FragmentCard `_formatTimestamp` 渲染**绝对时间** 'yyyy-MM-dd HH:mm'（非相对）。
seed 用 `DateTime.now().subtract(...)` → 每次测试运行 `now` 不同 → **分钟位变** → 时间戳
列像素漂移。#01 用相对时间 '2小时前'（now 抵消）规避了同类问题；capture 是绝对时间，
offset 不抵消。

修：seed 基准用**固定 DateTime(2026,6,22,22,40)**（非 wall clock），所有 createdAt 固定
→ 时间戳字符串每运行恒定。一行改动根治 flaky。

## 验证（六重）

- ✅ Bug1 修复后首跑 GREEN
- ✅ Bug2 修复后 **clean 连跑 2 次 GREEN**（solo）+ **full-suite clean 连跑 2 次 +9 GREEN**（确定性证明，非单跑侥幸）
- ✅ full-suite `--update-goldens` 重生：**其余 8 张 golden 字节完全不变**（Δ0），证实仅 capture 漂移、其余 8 张早已稳定
- ✅ golden 75502B(solo wall-clock)→75207B(固定时间戳)
- ✅ PIL 1013 色 / 98.5% dark（深色工作区）/ find.text 三重断言（'全部'/'AI 整理'/'林风在山门前听见古剑低鸣' findsOneWidget）
- ✅ analyze 0
- ✅ README 双语 disclosure 4 处加入「灵感捕捉(2)/Capture(2)」真实截图清单（双重诚实闭合）

## 教训

- **golden flaky 必跑 2 次以上**：run-to-run 非确定的 diff，单跑 GREEN 不算证据；
  `--update-goldens` 也救不了（重生后下次又差）。连跑 2 次 clean 才算确定性证明。
- **绝对时间 vs 相对时间**：渲染相对时间（'2小时前'）的组件，now-offset 抵消，wall-clock
  seed 安全；渲染绝对时间（'yyyy-MM-dd HH:mm'）的组件，必须用**固定 DateTime** seed。
  先 grep 渲染端 `_formatTimestamp`/`RelativeTime` 确认形态再选 seed 策略。
- **body-only 页面需测试侧补 Scaffold**：页面自身无 Scaffold 而依赖 shell 宿主时，测试
  `home:` 包一层 `Scaffold(body:)`（镜像真实 shell，无 AppBar），提供 Material 祖先。
- **大溢出数字是假象**：499033px 溢出 + 找不到文本 = 下游 build 异常的 error box，
  根因在上游（Material 缺失），不是布局。

## 进度

已迁 **9/21**：01 / **02** / 15 / 16 / 17 / 18 / 19 / 20 / 21。剩余 12 张：
- 中复杂度：03 AI整理 / 06-09 知识模板 / 10-14 结构守护
- 极重：04-05 editor（appflowy）

相关 [[golden-screenshot-migration-harness]]、[[readme-screenshot-mockup-honesty]]
