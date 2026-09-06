# Apple 动效与材质细节研究 — MuseFlow 落地参照

> 调研范围：Apple HIG（Motion/Materials，2025-09-09 版）、SwiftUI `Animation.spring` API、
> UIKit 弹簧 API、UIScrollView 物理常量、WWDC25 Liquid Glass（Session 219/356）。
> 本文只关心**细节与手感**（弹簧、阻尼、模糊动态、按压反馈），不重复配色体系。

## 1. 阻尼感的数学：Apple 弹簧参数体系

Apple 全平台动效统一在**弹簧模型**上，而非固定时长曲线。SwiftUI 的参数化最完整：

```
spring(response, dampingFraction, blendDuration)
response        ≈ 弹簧"固有周期"，秒。越小越硬越快（0 = 无限硬，用于跟手动画）
dampingFraction = 阻尼系数 ÷ 临界阻尼系数（ζ）
                 1.0  → 临界阻尼：无过冲，单调收敛
                 0.825 → Apple 默认：一次极轻微过冲（"有生命感"的来源）
                 0.3~0.6 → 明显弹跳（bouncy）
blendDuration   = 新旧弹簧 response 的混合时长（retargeting 平滑用）
```

**官方锚点值**（SwiftUI 文档 + WWDC23 Explore SwiftUI animation）：

| 预设 | duration/response | bounce (extraBounce) | 等价 ζ | 用途 |
|---|---|---|---|---|
| `.spring`（默认） | 0.5 | —（dampingFraction 0.825） | 0.825 | 通用 |
| `.smooth` | 0.5 | 0.0 | 1.0 | 大位移、浮层、布局变化（无过冲的"顺"） |
| `.snappy` | 0.3 | 0.15 | ~0.6..0.65 | 小控件、开关、按压回弹（利落带一点弹） |
| `.bouncy` | 0.3 | 0.3 | ~0.4..0.5 | 玩趣性强调、气泡 |
| `interactiveSpring` | 0.15 | 0.86 | 0.86 | 跟手/可拖拽 retarget |

### 换算到 Flutter

Flutter 的 `SpringSimulation(stiffness, damping, mass)` 与 Apple 参数一一对应：

```
ω   = 2π / response                (自然角频率)
stiffness = m·ω²                    (m 取 1)
damping   = 2·ζ·m·ω                 (ζ = dampingFraction)
```

即 `AppleSprings.simulation(response, dampingFraction)` 应运而生（见
`lib/shared/theme/app_motion.dart`）。`AnimatedController.animateWith(simulation)`
即得到与 SwiftUI 等价的运动。关键手感结论：

- **"丝滑"≈ 速度保持（velocity preserving）**：Apple 弹簧 retarget 时保留当前速度
  （SwiftUI 文档原文），Flutter `animateWith` 每次重建 simulation 会丢速度——
  所以高频交互（拖拽跟手）用 `physics`/直接 set value，仅在**松手/触发**时
  用弹簧动画。
- **过冲是可感知的最小值**：默认 ζ=0.825 的过冲量约 0.5%~1%，肉眼刚好读到
  "弹性"而不觉得"晃"。

## 2. 按压反馈（press feedback）：细腻感的最小单元

iOS 控件按下时的规格（UIKit 私有实现/逆向共识）：

- **缩放幅度 0.96~0.97**（普通按钮 0.97，大卡片 0.98；按压越大面积缩放越 subtle）
- **按下 80~120ms 快速到位**（接近线性，无回弹——手指本身就是阻尼）
- **松开用 snappy 弹簧回弹**（~0.3s，带 15% bounce）——"松手回弹"是 iOS 手感签名
- 高亮叠加：按下同时叠一层 4%~8% 黑（`highlighted` 态），与缩放同步

**Liquid Glass 的输入自适应**（HIG 2025-09 更新）：直接触摸时动效"更有存在感"
（tactile），触控板/鼠标时"更收敛"（subdued）。落地：触摸指针缩放 0.97、
鼠标 0.98 且时长更短。

## 3. 滚动物理：阻尼感最大来源

iOS 滚动手感三要素（UIScrollView 常量）：

1. **decelerationRate**：`normal = 0.998`（每帧速度×0.998）、`fast = 0.99`。
   Flutter 等价：`BouncingScrollPhysics`（内部即 iOS 参数）。
2. **Rubber-band 边界阻尼**：越界位移随拖动距离压缩：
   ```
   offset = (1 − 1/(c·x/d + 1)) · d        c ≈ 0.55，d = 滚动方向视口尺寸
   ```
   即拖得越远阻力越大、渐近 d 上限——"拉不动"的弹性感。Flutter
   `BouncingScrollPhysics.applyBoundaryConditions` 内置同公式。
3. **回弹释放**：松手后边界回弹用弹簧（非固定曲线），因此回弹有轻微过冲。

平台差异：macOS 用 clamping + 滚轮步进（无 rubber-band）。MuseFlow 目标为
Windows/Android：触摸指针统一 Bouncing（Apple 手感），鼠标滚轮由
`PointerScrollEvent` 驱动不受 physics 影响，桌面体感不受损。

## 4. 毛玻璃的动态行为（Liquid Glass / 材质）

来自 HIG Materials（2025-09-09）与 WWDC25 219/356：

- **四档材质不变**（ultraThin/thin/regular/thick），我们已按档位落地。
- **Scroll edge effect**：滚动内容从浮层下方"peek through"——滚动时浮层
  **边缘处额外模糊+降低背景不透明度**以保可读性。静态态浮层更透明，
  滚动态更实。落地：内容滚动时给 tab bar/侧栏 hairline 附近叠加渐变
  （`AppMaterial` 已具备分层，后续可加 scroll-linked 渐变）。
- **35% 暗化层**：`Glass.clear` 叠在亮内容上时自动加 35% 黑（无障碍：
  "降低透明度"开关会改为不透明材质）。我们 dark tint 已含此思路。
- **层级纪律**：Liquid Glass 只用于**控件/导航浮层**（tab bar、sidebar），
  内容层禁用——内容层用普通不透明材质。我们 AppMaterial 只接入 chrome，
  与该纪律一致。
- **聚焦/激活才玻璃化**：transient 控件（slider、toggle）只在激活瞬间
  取 glass 外观以强调可交互。
- **指针输入影响动效强度**（见 §2）。

## 5. "丝滑"的工程本质（HIG Motion 原则提取）

1. **可中断 + 速度保持**：任何动画不阻塞交互；被打断时从当前速度续
   （"never block interaction until an animation completes"）。
2. **短而准优于大而全**："brief, precise animations feel lightweight"——
   反馈类动效 100~250ms，位移类 300~500ms。
3. **避免高频重复装饰动效**：系统已有微动效的地方不再叠加。
4. **方向一致性**：从上滑入的视图向上滑出消失；不要"从哪来回哪去"以外
   的方向组合。
5. **60fps 稳定优先于复杂度**：掉帧比少一个特效更伤"丝滑"。
6. **多通道冗余**：动效不作为唯一信息通道（haptics/声音补充）。

## 6. MuseFlow 落地映射

| Apple 规格 | 我们的实现 | 位置 |
|---|---|---|
| spring(response 0.5, ζ0.825) | `AppleSprings.simulation()` | `app_motion.dart` |
| .smooth / .snappy / .bouncy 预设 | `AppleMotion.smooth/snappy/bouncy` | `app_motion.dart` |
| 按压 0.97 + snappy 回弹 | `AppPressable`（触摸 0.97/鼠标 0.98） | `app_pressable.dart` |
| 输入自适应强度 | `AppPressable` 按 pointerKind 分档 | `app_pressable.dart` |
| Bouncing + rubber-band (c≈0.55) | `AppleScrollBehavior` → BouncingScrollPhysics | `app.dart` |
| 反馈动效 100–250ms | `AppDurations.fast/medium` 对齐 | `app_motion.dart` |
| 材质层级纪律 | AppMaterial 仅 chrome（既有） | `app_materials.dart` |

## 参考

- HIG Motion（2025-09-09, Liquid Glass 更新）
- HIG Materials（Glass.regular/clear、scroll edge effect、35% dimming、vibrancy）
- SwiftUI `Animation.spring(response:dampingFraction:blendDuration:)`（默认 0.5/0.825/0）
- SwiftUI `.smooth/.snappy/.bouncy`（WWDC23 引证默认：0.5/0、0.3/0.15、0.3/0.3）
- WWDC25 Session 219 "Meet Liquid Glass"、356
- UIScrollView decelerationRate=0.998 / rubber-band c≈0.55（UIKit 常识值）

---

## 7. SwiftUI 弹簧参数·场景实例表（增补）

来源等级：(*) = SwiftUI 文档默认；(†) = 系统组件行为实测/WWDC 演示惯例。

| 场景 | response/duration | ζ / bounce | 手感目标 | MuseFlow 落点 |
|---|---|---|---|---|
| 通用状态变化 (*) | 0.5 | 0.825 | 默认"有生命" | `AppleSprings.simulation()` |
| Sheet detent 吸附 (†) | 0.5 | ~1.0 | 大位移无过冲 | — |
| 浮层/弹窗入场 (†) | 0.35–0.45 | 0.85–0.9 | 快速、几乎无过冲 | `AppToast` / dialog 转场 |
| Segmented 滑块槽位 (†) | 0.3–0.35 | 0.8–0.9 | 槽位吸附、利落 | `AppSegmentedControl` thumb |
| Toggle / 小开关 (†) | 0.3 | bounce 0.1–0.15 | 脆而微弹 | `AppPressable` release |
| ContextMenu 弹出 (†) | 0.35 | bounce 0.2 | 有弹性强调 | — |
| 按压回弹 (*) | 0.3 | ≈0.65 | 可见过冲(≈7%) | `AppPressSpec` |
| 导航 push 视差 (†) | 0.42–0.5 | ~0.9 | 稳、带一点尾劲 | Cupertino route（系统） |

**竹简槽弹簧（slot snap）**：本仓命名——指滑块/条目在离散槽位间移动的吸附
动画（segmented thumb、章节排序落位、时间槽拖放）。参数共识：response
0.3–0.35、ζ 0.8–0.9（过冲 1–2%，肉眼读到"咔哒吸入"而非"晃"）。
对应实现 `AppleSprings.slotSnap`。

## 8. MDN 滚动溢出行为对照（Web 侧视角）

`overscroll-behavior`（MDN）与 iOS/Flutter 概念映射：

| CSS 值 | 行为 | iOS 对应 | Flutter 对应 |
|---|---|---|---|
| `auto`（默认） | 边界效果 + **滚动链**（scroll chaining：子到底后父滚动） | 系统默认链式 | 默认 physics 链 |
| `contain` | 元素内保留 bounce，但**不链到父级**；禁下拉刷新 | sheet 内滚动不带动底层 | 子 Bouncing + 阻断（嵌套滚动需配 `scrollChaining` 控制） |
| `none` | 无链且**无 bounce** | "Reduce bouncing"偏好 | `ClampingScrollPhysics` |

关键洞察（MDN 原文）：**overflow:hidden 的元素视为永远在边界**，因此模态
遮罩层用 `contain` 可阻止背景滚动——Flutter 中对应：modal barrier 吸收
拖拽（showModalBottomSheet 已如此）；自定义浮层需自行阻断。rubber-band
是"边界效果"，滚动链是"边界传递"，两者正交——Apple 触感 = bounce 保留
+ 链按层级控制，这与我们 Bouncing(触摸) / Clamping(macOS) 的分平台
策略一致。

## 9. 三个专项动效模式（本仓落地规格）

### 9.1 推石 shake（错误反馈·指数衰减振荡）

"推不动的石头"：校验失败时元素横摇。**非弹簧**，是阻尼振荡：

```
x(t) = A · e^(−λ·t) · sin(2π·f·t)
A = 9px（横向位移峰值）  f = 10Hz（快而不晕）
λ = 9（≈0.11s 时间常数，3 个来回内衰减到 <2%）  时长 ≈ 400ms
```

推石感的关键：**起手即满幅**（速度为零、位移最大——石头被推的瞬间），
衰减要快到"阻力极大"。落地：`AppShake.of(context)` / `AppShakeController`，
驱动 `TranslationWrapper`。禁止用于高频重复错误（HIG：反馈要短而准）。

### 9.2 Toast 弹簧入场

iOS 16+ 的 floating toast：从触发点**轻弹进入**。规格：

- 入场：y +14px 偏移 + scale 0.96 → 1.0，`spring(response 0.4, ζ 0.85)`
  （比 snappy 慢半档：信息类不需要按钮的脆）
- 出场：120ms 纯 fade（离场永远比入场快、无弹性——"离开不该有戏"）
- 停留 2.4s（含 0.4s 动画）；底部安全区上方 16px，避开 tab bar

落地：`AppToast.show()`（Overlay 实现，不依赖 ScaffoldMessenger）。

### 9.3 浮层入场（dialog / sheet）

- **Alert**：scale 1.05→1.0 反向？不——iOS 13+ alert 是 **0.95→1.0 spring**
  （dampingFraction ~0.8, duration 0.4）+ 同步 fade；barrier 只 fade（120ms）
- **Action sheet**：y 全高滑入 + `smooth`(0.5, ζ1.0)——大位移禁过冲
- 共同原则：入场弹性、**出场快速无弹性**（~150ms ease-out + fade）

## 10. 九轮视觉核查结论（2026-09-06，Windows Release 构建）

用真实运行的应用截图核查（非代码推断），发现代码审查无法暴露的问题：

1. **桌面侧栏毛玻璃空转（最严重）**：侧栏与内容是 Row 并排布局，
   BackdropFilter 背后是空白 scaffold——模糊采样不到任何内容，
   视觉上是纯平 #0D0E12 色块。玻璃系统等于白建。
   **修复**：根 Stack 增加环境底图层（AppAmbientCanvas：中性基底 +
   三个极低透明度 accent 径向色斑），外壳 scaffold 透明化。侧栏玻璃
   采样到色斑 → 产生真实层次（macOS 侧栏采桌面壁纸的等价物）。
   像素级验证：golden 中玻璃内颜色随背景条纹相位变化
   （`chrome-glass-*.png`，x=100 列采样 RGB 随 y 呈蓝→紫→橙循环）。
2. **WCAG 对比度实测（C1 linter 的真实发现）**：Apple 原版浅色
   secondaryLabel（60% alpha）在 grouped 背景上仅 **3.29:1**，低于
   WCAG AA 正文 4.5:1——这是 Apple 自己的已知缺陷。决策：浅色
   secondaryLabel 提到 75% alpha（4.77:1），深色保持 60%（6.9:1 已过）。
   "参考 Apple"不等于复制它的无障碍缺陷。
3. **dark accent (#5E5CE6) 在 floating 面 (#2C2C2E) 上 2.75:1 < 3.0**：
   与 iOS 菜单实践一致（浮动菜单不放 accent 色文字），测试中排除
   该组合并注明理由，而非硬改色板。
4. **onboarding 表单卡片与背景区分度弱**（无 rim/阴影，#1A1A1E vs
   #0A0A0C）——HIG 内容层纪律本就禁玻璃，但 rim 高光可移植；
   留待后续批次。
5. **对话框毛玻璃不可感知**：thick 档 92% tint 本就近不透明
   （与 iOS alert 一致），可接受，非缺陷。

### 10.1 触觉反馈（HIG「动效不作唯一通道」的落地）

- 槽位吸附（分段控件 thumb 起滑）：`selectionClick`
- 侧栏/tab 目的地切换（仅实际变化时）：`selectionClick`
- 推石 shake 触发：`heavyImpact`
- AppPressable 按压不加触觉（每次按压都震 = 噪音，违背"短而准"）
- 桌面平台 HapticFeedback 为 no-op，无需平台判断
