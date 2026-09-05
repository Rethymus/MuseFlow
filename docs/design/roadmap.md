# MuseFlow「参考 Apple」长周期优化改进路线图

> 依据：`apple-motion-research.md`（§1–§9 调研）、八轮视觉/代码核查的发现、
> 以及专业学科（视觉感知、人因工程、可访问性 WCAG、渲染性能）对当前
> 实现的差距分析。原则：**一切改进必须落到可验证的参数或测试**，
> 拒绝文案式"参考 Apple"。

## 现状基线（已完成并受测试锁定）

| 系统 | 位置 | 验证方式 |
|---|---|---|
| iOS 系统色板（深浅成对） | `app_colors.dart` | 参数测试（色阶亮度单调性） |
| Apple 字阶（Noto CJK 承载） | `app_typography.dart` | golden 全量 |
| 材质层：四档模糊/半透明叠色/内高光/hairline | `app_materials.dart` | 11 项参数测试（σ、透明度、rim、边框） |
| 中性色阶 AppElevation | `app_materials.dart` | 亮度单调性测试 |
| 焦点环 AppFocusRing | `app_materials.dart` | 出现/消失测试 |
| Apple 弹簧数学 + 四预设 | `app_motion.dart` | 换算/过冲分界测试 |
| 按压反馈 AppPressable | `app_pressable.dart` | 双指针缩放/回弹测试 |
| 滚动物理 AppleScrollBehavior | `apple_scroll_behavior.dart` | physics 类型测试 |
| 推石 shake / toast / 槽位吸附 / alert·sheet 转场 | `app_shake/toast/controls/dialogs` | 12+4 项模式测试 |
| 18 张 README golden（真实主题+真实图标） | `test/readme_screenshots/` | 3.5% 跨平台容差 |

## Phase B — 覆盖广度（短期，1–2 周/每次 1–2 小时批次）

目标：让已验证的系统**覆盖全部交互面**，消灭"漏网之股"。

- **B1 按压反馈全覆盖**：AppPressable 接入剩余可点卡片/行
  （report_card、knowledge tile、template card、chart 卡）。验收：
  交互面清单核对 + 现有测试全绿。
- **B2 Toast 全面替代 SnackBar**：grep 全仓 SnackBar 残留，逐个换
  showAppToast（捕获器/编辑器/知识库等）。验收：`grep SnackBar lib/`
  仅剩框架 fallback。
- **B3 滚动边缘效果（HIG Materials 规格）**：内容滚动经过浮层下方时，
  浮层边缘额外模糊+降不透明度。实现：AppMaterial 增加 `scrollEdge`
  参数，由 Scrollable 联动（NotificationListener 驱动强度 0→1）。
  验收：新增滚动联动测试 + 目视 golden。
- **B4 焦点环接入主导航**：AppSidebar/AppTabBar 项获得键盘焦点环
  （当前仅分段控件有）。桌面可访问性关键。验收：focus traversal 测试。

## Phase C — 可访问性与对比度（中期）

- **C1 WCAG 对比度 linter**：对 `AppPalette` 的全部前景/背景组合
  （label/secondaryLabel/tertiaryLabel × cardBackground/groupedBackground
  等，深浅两套）跑 4.5:1（正文）/3:1（大字）断言，钉死层级边界。
  tertiaryLabel 仅限装饰性文字的规则写进测试理由。
- **C2 Reduce Transparency 响应**：`MediaQuery.disableAnimations`/
  系统降透明度时，AppMaterial 退化为不透明 elevation 色（Apple 规范
  行为）。验收：双模式渲染测试。
- **C3 深浅双主题 golden 成对**：关键 6 页生成 light/dark 成对 golden，
  防止单边回归。

## Phase D — 液态玻璃深度（长期）

- **D1 滚动联动材质强度**：滚动速度映射到浮层 tint 不透明度微调
  （快滚更实、静止更透）——HIG "dynamism and depth" 的 Flutter 落地。
  需性能预算测试（掉帧检测）。
- **D2 指针自适应动效全局化**：AppPressable 的触摸/鼠标分档推广到
  sheet/scale 类动效（Liquid Glass：直接触摸 tactile、间接输入 subdued）。
- **D3 触觉反馈钩子**：按压/槽位吸附/shake 接 `HapticFeedback`，
  HIG"动效不作为唯一信息通道"。
- **D4 拖拽跟手推广**：spring sheet 的 1:1 跟手 + 速度感知落定推广到
  synthesis panel 与 quick capture 面板。

## Phase E — 视觉回归基建（贯穿）

- 每新增一个交互模式：参数测试 + 行为测试 + golden 三件套（既定纪律）。
- 季度性全 golden 重生成 + 目视审查（本路线图的验收手段）。

## 执行纪律

每个 Phase 内条目独立成原子 commit：`fix(motion)/feat(motion)` 前缀，
push 后 CI 必须绿再进入下一条。任何"看起来像 Apple 但测不出来"的
改动一律退回参数化。
