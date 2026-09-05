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
