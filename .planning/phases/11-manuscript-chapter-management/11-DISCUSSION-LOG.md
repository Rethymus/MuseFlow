# Phase 11: 文稿库与章节管理 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-06
**Phase:** 11-manuscript-chapter-management
**Areas discussed:** Data Model, Chapter Navigation UX, Manuscript Library UX, Data Migration, Sidebar Behavior, Manuscript Entity Fields, Chapter Entity Fields, Navigation Flow, Bottom Nav, Chapter Reordering, Template Integration, Empty States, Entity Linking, Deletion, Manuscript Creation, Export, AI Context, Auto-save, Chapter Status Flow, Library Sort, Cover Style, Sidebar Info, Chapter Operations, Metadata Editing, Word Goal Progress, Keyboard Shortcuts, Genres

---

## Data Model

| Option | Description | Selected |
|--------|-------------|----------|
| Per-chapter documents | Each chapter owns its own SuperEditor Document (JSON). Switching chapters swaps the editor's document. | ✓ |
| Single document with chapters | One large Document with chapter-break markers. All content in a single document tree. | |

**User's choice:** Per-chapter documents
**Notes:** Cleaner separation, simpler undo history, natural for migration.

## Chapter Navigation UX

| Option | Description | Selected |
|--------|-------------|----------|
| Left sidebar panel | Editor page 左侧显示章节列表，点击切换。类似 VS Code 文件树或 Notion 侧栏。 | ✓ |
| Horizontal tabs below toolbar | Editor toolbar 下方加水平可滚动标签页。紧凑但空间有限。 | |
| Drawer/popover from toolbar | FloatingPanel 或抽屉式面板，FAB 按钮触发。不占用常驻空间。 | |

**User's choice:** Left sidebar panel

## Manuscript Library UX

| Option | Description | Selected |
|--------|-------------|----------|
| Replace editor with library | App 打开时显示文稿列表，点选后进入编辑器。类似笔记应用（Obsidian/Notion）的库首页。 | ✓ |
| Editor toolbar dropdown | 保持编辑器为首页，在 editor branch 内加一个文稿切换入口。 | |
| New shell branch | 新增底部导航项（文稿库），与现有 Tab 并列。 | |

**User's choice:** Replace editor with library

## Data Migration

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-create first manuscript | 自动创建一个默认文稿，但编辑器历史内容不迁移。 | |
| Migration wizard | 启动时检测老用户，弹出迁移引导。但当前编辑器内容实际未持久化。 | |
| Clean start | 多文稿功能对所有用户全新启用，不迁移旧数据。 | ✓ |

**User's choice:** Clean start
**Notes:** 当前编辑器内容实际未持久化到 Hive（只有 Fragment 被存储），迁移实际无内容可迁。

## Sidebar Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Always visible | Sidebar 固定显示在编辑器左侧（约 240-280px），始终可见。 | ✓ |
| Collapsible with icon toggle | 默认收起，只显示图标按钮。点击展开侧栏。 | |
| Default open, user can close | 默认展开，用户可手动收起。记住偏好。 | |

**User's choice:** Always visible

## Manuscript Entity Fields

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal (title + meta) | 标题 + 简介 + 时间 + 总字数。关联实体通过 ID 引用。 | |
| Rich (title + genre + goals) | 标题 + 简介 + 类型标签 + 关联知识库实体 + 目标字数 + 状态。 | ✓ |
| Minimal + extensible metadata | 基本字段固定，额外属性用 key-value metadata 存储。 | |

**User's choice:** Rich (title + genre + goals)

## Chapter Entity Fields

| Option | Description | Selected |
|--------|-------------|----------|
| Title + order + status | 标题 + 排序号 + 字数 + 状态（草稿/初稿/精修/定稿）。 | ✓ |
| Title + order + summary | 标题 + 排序号 + 字数 + 状态 + 简要摘要。 | |
| Minimal (title + order) | 标题 + 排序号即可，字数和状态实时计算。 | |

**User's choice:** Title + order + status

## Navigation Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Library → Editor → Back | 文稿库首页 → 点击文稿卡片 → 进入编辑器 → AppBar 返回文稿库。 | ✓ |
| Library → Editor + quick switch | 进入编辑器后 AppBar 下拉菜单可快速切换其他文稿。 | |

**User's choice:** Library → Editor → Back

## Bottom Nav

| Option | Description | Selected |
|--------|-------------|----------|
| Keep all 6 items | Editor branch 改为显示文稿库首页，进入文稿后编辑器内容区域不变。 | ✓ |
| Hide nav in editor | 移除 Editor 底部导航项，文稿库作为独立全屏页面。 | |
| Rename Editor → Library | 将底部导航的"编辑器"重命名为"文稿库"。 | |

**User's choice:** Keep all 6 items

## Chapter Reordering

| Option | Description | Selected |
|--------|-------------|----------|
| Drag & drop in sidebar | 长按拖拽章节项移动位置，松开时自动更新排序号。 | ✓ |
| Move up/down buttons | 提供上移/下移按钮。简单但没有拖拽直观。 | |
| Both | 支持拖拽和上下移动按钮两种方式。 | |

**User's choice:** Drag & drop in sidebar

## Template Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Template creates manuscript skeleton | 创建文稿时可选择模板，选择后自动创建关联实体 + 预设章节骨架。 | ✓ |
| Keep templates separate | 模板系统保持独立，不与文稿创建流程集成。 | |
| Link existing template entities | 模板创建的知识库实体与文稿关联，但不自动创建章节。 | |

**User's choice:** Template creates manuscript skeleton

## Empty States

| Option | Description | Selected |
|--------|-------------|----------|
| Simple CTA cards | 文稿库首页显示"创建你的第一部作品"引导卡片。 | |
| Illustrated + step guide | 空文稿库显示引导插图+说明文字+按钮。类似 Phase 10 空状态设计。 | ✓ |

**User's choice:** Illustrated + step guide

## Entity Linking

| Option | Description | Selected |
|--------|-------------|----------|
| One world + many characters | 每个文稿关联一个 WorldSetting + 多个 CharacterCard。 | ✓ |
| One world + one protagonist | 每个文稿关联一个 WorldSetting + 一个主要 CharacterCard。 | |
| Unlimited associations | 每个文稿可关联任意数量的 WorldSetting 和 CharacterCard。 | |

**User's choice:** One world + many characters

## Deletion

| Option | Description | Selected |
|--------|-------------|----------|
| Confirm + keep knowledge | 删除文稿时要求确认，知识库实体保留。 | |
| Double confirm + keep knowledge | 删除时二次确认。 | |
| Soft delete with auto-purge | 删除时放入回收站，30天后自动清理。知识库实体保留。 | ✓ |

**User's choice:** Soft delete with auto-purge

## Manuscript Creation

| Option | Description | Selected |
|--------|-------------|----------|
| Dialog: title + genre | 弹出对话框输入标题+选择类型，快速创建。 | |
| Full creation page | 跳转到创建页面设置全部属性。 | |
| Both quick + detailed | 提供两种入口：快速创建（对话框）和详细创建（完整页面）。 | ✓ |

**User's choice:** Both quick + detailed

## Export

| Option | Description | Selected |
|--------|-------------|----------|
| Whole or single chapter | 导出时选择"整部文稿"或"当前章节"。 | |
| Whole manuscript only | 只导出整部文稿。 | |
| Flexible selection | 支持导出选定章节（多选）或整部文稿。 | ✓ |

**User's choice:** Flexible selection

## AI Context

| Option | Description | Selected |
|--------|-------------|----------|
| Current chapter only | AI 只看到当前章节内容 + 知识库注入。 | |
| Include adjacent summaries | AI 可选择注入相邻章节摘要作为上下文。 | ✓ |
| Always include manuscript outline | AI 始终注入整部文稿的章节标题+摘要。 | |

**User's choice:** Include adjacent summaries
**Notes:** 前一章摘要 + 当前章节全文 + 下一章摘要。

## Auto-save

| Option | Description | Selected |
|--------|-------------|----------|
| Debounced auto-save | 编辑时实时保存（debounced 2-3秒防抖）。 | |
| Save on switch only | 只在切换章节、返回文稿库、或关闭应用时保存。 | |
| Debounced + save on switch | 实时保存 + 切换时强制保存。双重保障。 | ✓ |

**User's choice:** Debounced + save on switch

## Chapter Status Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Free (any status anytime) | 状态自由设置，无强制顺序。 | |
| Sequential (must follow order) | 状态必须按顺序推进（草稿→初稿→精修→定稿）。 | |
| Guided but flexible | 建议按顺序推进，但允许跳过。UI显示下一步建议。 | ✓ |

**User's choice:** Guided but flexible

## Library Sort

| Option | Description | Selected |
|--------|-------------|----------|
| Recent first | 最近编辑的文稿排在最前。 | |
| Manual/custom sort | 固定顺序（手动排序或按创建时间）。 | |
| Multiple sort options | 支持多种排序：最近编辑、创建时间、标题字母序。 | ✓ |

**User's choice:** Multiple sort options

## Cover Style

| Option | Description | Selected |
|--------|-------------|----------|
| Genre-based color | 根据类型标签显示不同背景色。 | |
| Title initial letters | 显示文稿标题的前两个大字作为封面。 | |
| Genre color + initial letter | 类型色背景 + 标题首字叠加。 | |

**User's choice:** 默认类型色背景 + 标题首字叠加，用户可更改字但仅限2字符。(Free-text response extending "Genre color + initial letter" option)

## Sidebar Info

| Option | Description | Selected |
|--------|-------------|----------|
| Title + word count | 每行显示章节标题 + 右侧字数。当前编辑的章节高亮。 | ✓ |
| Title + word count + status | 章节标题 + 字数 + 小状态图标。 | |
| Title only | 仅显示章节标题。 | |

**User's choice:** Title + word count

## Chapter Operations

| Option | Description | Selected |
|--------|-------------|----------|
| Split chapter | 长章节可拆分为两个章节（在光标位置分割）。 | ✓ |
| Merge chapters | 相邻章节可合并为一个。 | ✓ |
| Duplicate chapter | 复制章节（含内容）作为新章节。 | ✓ |

**User's choice:** All three operations (multi-select)

## Metadata Editing

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated settings page | 点击文稿库卡片或编辑器 AppBar 标题进入编辑页面。 | ✓ |
| Inline edit via dialog | AppBar 上点击文稿标题，弹出对话框编辑。 | |
| Sidebar header dropdown | 侧栏顶部显示文稿标题，点击展开下拉菜单编辑。 | |

**User's choice:** Dedicated settings page

## Word Goal Progress

| Option | Description | Selected |
|--------|-------------|----------|
| Progress bar in library + editor | 文稿库卡片和编辑器状态栏都显示进度条。 | ✓ |
| Progress bar in library only | 仅文稿库卡片显示。 | |
| Settings page only | 仅在文稿设置页面显示。 | |

**User's choice:** Progress bar in library + editor

## Keyboard Shortcuts

| Option | Description | Selected |
|--------|-------------|----------|
| Add chapter shortcuts | Ctrl+Up/Down 切换章节，Ctrl+Shift+N 新建章节。 | |
| No new shortcuts | 不添加新的章节快捷键。 | |
| Customizable shortcuts | 添加快捷键，但支持在设置中自定义或禁用。 | ✓ |

**User's choice:** Customizable shortcuts

## Genres

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse template genres (14) | 复用 Phase 7 的 14 种小说类型作为固定列表。 | |
| Extended genre list | 提供更大的类型列表（30+）。 | |
| Preset + custom genres | 预设常见类型 + 用户可自定义添加。 | ✓ |

**User's choice:** Preset + custom genres

---

## Claude's Discretion

The following implementation details are delegated to the planner/executor:
- SuperEditor Document JSON serialization format (use built-in fromJson/toJson)
- Drag & drop package selection
- Genre color palette mapping
- Soft delete auto-purge trigger mechanism
- Adjacent chapter summary generation approach
- Keyboard shortcut customization storage format

## Deferred Ideas

None — discussion stayed within phase scope.
