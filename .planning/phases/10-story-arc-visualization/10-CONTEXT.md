# Phase 10: 故事弧可视化 - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers an interactive story arc visualization using the graphview library (^1.5.1). Users can view their existing PlotNode network as a graph with visual distinction of relationship types (causal/related/foreshadowing), inline-edit nodes via bottom sheet, drag to rearrange with position persistence, and navigate via minimap widget.

This phase does not add automatic layout algorithm switching, does not export graphs as images, and does not add 3D visualization mode.

</domain>

<decisions>
## Implementation Decisions

### 节点组件设计
- **D-01:** 节点显示标题 + 章节号（章节号作为右上角小角标）。
- **D-02:** 节点尺寸使用两个档位（短标题用小尺寸，长标题用大尺寸），平衡空间利用和信息展示。
- **D-03:** 节点形状为矩形（0-4px圆角），现代简洁，与编辑器UI风格一致。
- **D-04:** 标题和章节号布局采用角标形式（章节号在右上角），节省空间，标题区域完整。

### 颜色方案
- **D-05:** 结构角色配色使用戏剧张力色调：铺垫=灰色、发展=绿色、转折=黄色、高潮=橙红、结局=深蓝。符合戏剧张力曲线。
- **D-06:** 写作状态通过边框 + 图标结合表示。边框样式区分状态，右上角状态图标辅助传达。
- **D-07:** 深色模式分别优化颜色值（深色模式用更亮颜色，浅色模式用更深颜色），确保两种模式下都清晰可见。
- **D-08:** 颜色定义使用语义类命名（GraphColor节点角色类、GraphStatus写作状态类），如GraphColor.setup、GraphStatus.complete。代码语义清晰。

### 边样式
- **D-09:** 因果关系（causeNodeIds→consequenceNodeIds）使用渐变线 + 箭头（起点深→终点浅）。渐变表示因果强度，箭头明确方向。
- **D-10:** 关联关系（relatedNodeIds）使用浅灰色细实线，无箭头。与因果边区分明显，表示横向关联。
- **D-11:** 伏笔关系（linkedForeshadowingIds）使用琥珀色虚线 + 圆点标记。虚线表示"潜在"连接，圆点表示伏笔节点。
- **D-12:** 边粗细按重要性区分：因果=2.0px、关联=1.0px、伏笔=1.5px。视觉层次清晰。

### 编辑与存储
- **D-13:** 点击节点弹出底部表单（BottomSheet）进行编辑。符合Flutter移动端习惯。
- **D-14:** 底部表单中允许编辑常用五字段：标题、结构角色、写作状态、章节号、摘要。
- **D-15:** 节点位置使用独立映射表存储（NodePosition: PlotNode.id → Position）。PlotNode保持纯净，位置信息分离。
- **D-16:** 空状态显示"暂无剧情节点"插图和"创建第一个节点"按钮，引导用户开始使用。

### Claude's Discretion
无。用户对所有讨论区域都做出了明确决策。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 产品范围
- `.planning/ROADMAP.md` — Phase 10目标、成功标准、计划拆分、v1.1里程碑边界。
- `.planning/REQUIREMENTS.md` — VIZO-01至VIZO-06需求定义和v2延期可视化项。
- `.planning/PROJECT.md` — 核心产品价值、本地优先约束、反AI味原则、v1.1里程碑决策。
- `.planning/STATE.md` — 当前项目状态和graphview研究笔记（^1.5.1已验证）。

### 现有代码锚点
- `lib/features/story_structure/domain/plot_node.dart` — 目标PlotNode实体字段：causeNodeIds、consequenceNodeIds、relatedNodeIds、linkedForeshadowingIds、structuralRole、writingStatus。
- `lib/features/story_structure/infrastructure/plot_node_repository.dart` — 现有PlotNode Hive持久化路径。
- `lib/features/story_structure/presentation/story_structure_page.dart` — 现有故事结构列表UI模式（可作为可视化入口）。
- `lib/features/story_structure/application/plot_node_notifier.dart` — 现有PlotNode状态管理模式，可复用Riverpod AsyncNotifier模式。

### 技术选型验证
- `.planning/research/STACK.md` — graphview ^1.5.1技术验证：FruchtermanReingold力导向布局、InteractiveViewer缩放平移、自定义节点构建器、边渲染器、节点拖拽支持。

</canonical_refs>

<code_context>
## Existing Code Insights

### 可复用资产
- `PlotNode`已支持所有必需的关系字段（causeNodeIds、consequenceNodeIds、relatedNodeIds、linkedForeshadowingIds）和枚举类型（PlotNodeWritingStatus、PlotNodeStructuralRole）。
- `PlotNodeRepository`已生成UUID并持久化到Hive boxes，节点位置存储应创建独立的`NodePositionRepository`而非修改PlotNode。
- `StoryStructurePage`已有列表/搜索模式，可视化可作为新的视图选项（列表视图 vs 图视图）。
- `PlotNodeNotifier`使用Riverpod AsyncNotifier模式，可视化应遵循相同的异步状态管理模式。

### 已建立模式
- 知识实体是不可变类，使用`copyWith`、`toJson`/`fromJson`、构造函数验证，以及Hive-backed repositories。
- 应用偏好本地bundler数据和本地持久化；节点位置应使用Hive独立box存储（graph_positions box）。
- UI使用ConsumerWidget/ConsumerStatefulWidget配合Riverpod，状态读取用`ref.watch`，操作用`ref.read`。

### 集成点
- 新可视化功能应连接到现有PlotNodeRepository读取节点数据。
- 新NodePositionRepository应创建独立的Hive box（graph_positions）存储节点位置。
- 可视化可作为StoryStructurePage的新视图选项（SegmentedButton切换列表/图视图）。
- 底部表单编辑应调用PlotNodeRepository更新，并触发Riverpod状态刷新。

</code_context>

<specifics>
## Specific Ideas

- 节点内容布局：章节号作为右上角小角标。
- 结构角色配色：灰色（铺垫）→绿色（发展）→黄色（转折）→橙红（高潮）→深蓝（结局）。
- 边样式：因果=渐变线+箭头、关联=细灰线、伏笔=琥珀色虚线+圆点。
- 边粗细：因果2.0px、关联1.0px、伏笔1.5px。
- 颜色代码组织：GraphColor.setup、GraphStatus.complete语义类命名。
- 空状态：插图 + "创建第一个节点"按钮。

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-故事弧可视化*
*Context gathered: 2026-06-05*
