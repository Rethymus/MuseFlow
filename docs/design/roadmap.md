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

- **B1 按压反馈全覆盖** ✅（b88032e）：AppPressable 接入全部可点卡片。
- **B2 Toast 全面替代 SnackBar** ✅（784f5b3）：39 处 SnackBar 全部迁移。
- **B3 滚动边缘效果（HIG Materials 规格）** ✅（3b7833e + 本批次）：
  AppScrollEdge 联动 chrome tint（+25% 上限）。
- **B4 焦点环接入主导航** ✅：侧栏（6ca4ce9）+ tab 栏（本批次补齐）。

## Phase C — 可访问性与对比度（中期）✅ 本批次完成

- **C1 WCAG 对比度 linter** ✅：`test/shared/theme/app_contrast_test.dart`
  ——深浅两套全部 label×surface 组合 + 玻璃合成面 + accent UI 面，
  AA 4.5:1 / UI 3:1 断言。**真实发现**：Apple 原版浅色 secondaryLabel
  60% = 3.29:1 不达 AA → 提到 75%（4.77:1），深色 60% 本就 6.9:1。
  tertiary/quaternary 钉"装饰性存在下限"（WCAG 1.4.3 豁免）。
- **C2 Reduce Transparency 响应** ✅：设置页"减少透明度"开关 →
  `AppVisualSettings` InheritedWidget → AppMaterial 退化为不透明
  elevation 色（tier→elevation 映射），环境底图退化为纯色基底；
  持久化于加密 settings box。
- **C3 深浅双主题 golden 成对** ✅：
  `test/shared/theme/theme_pair_goldens_test.dart` —— settings 深浅对 +
  **chrome-glass 玻璃采样验证对**（条纹背景穿过玻璃模糊的像素锁定）。

## Phase F — 环境底图与材质纵深（本批次新增，替代原 D1 位置）

- **F1 环境底图层** ✅：`AppAmbientCanvas`（中性基底 + 三个 accent
  色斑，深浅各一套参数，静态 RepaintBoundary），外壳 scaffold 透明化，
  桌面侧栏/移动 tab 栏/浮层全部获得真实采样源。色斑强度受测试约束
  （对比度增量 < 0.35，"是深度不是装饰"）。
- **F2 视觉核查纪律** ✅：九轮截图核查结论入 research §10；
  golden 像素采样验证玻璃透出（chrome-glass）。

## Phase D — 液态玻璃深度（长期）

- **D3 触觉反馈钩子** ✅（本批次）：槽位吸附/导航切换 selectionClick、
  shake heavyImpact；按压不震（噪音）。
- **D1 滚动联动材质强度**：滚动速度映射 tint 微调（保留）。
- **D2 指针自适应动效全局化**：sheet/scale 类推广（保留）。
- **D4 拖拽跟手推广**：spring sheet 1:1 跟手推广到 synthesis panel
  与 quick capture（保留）。

## Phase E — 视觉回归基建（贯穿）

- 每新增一个交互模式：参数测试 + 行为测试 + golden 三件套（既定纪律）。✅
- 季度性全 golden 重生成 + 目视审查（本路线图的验收手段）。
- **新增**：settings golden 已随 secondaryLabel 75% + 减少透明度开关
  重生成；theme-pair goldens 为增量新基线。

## 执行纪律

每个 Phase 内条目独立成原子 commit：`fix(motion)/feat(motion)` 前缀，
push 后 CI 必须绿再进入下一条。任何"看起来像 Apple 但测不出来"的
改动一律退回参数化。
