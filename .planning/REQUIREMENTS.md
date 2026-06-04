# Requirements: MuseFlow 灵韵

**Defined:** 2026-06-04
**Core Value:** 让AI帮你写好故事，但让读者看不出AI的痕迹。

## v1.1 Requirements

Requirements for v1.1 创作体验升级 milestone. Each maps to roadmap phases.

### 模板库 (TMPL)

- [ ] **TMPL-01**: 用户可以从类型选择画廊中浏览和筛选14种主要小说类型（8男频+6女频），每种类型配有图标和简介
- [ ] **TMPL-02**: 类型画廊显示起点/番茄2025-2026热门标签（如都市修仙、都市脑洞）
- [ ] **TMPL-03**: 用户点击"使用模板"后，一键创建WorldSetting + CharacterCard原型实体（可编辑，非锁定）
- [ ] **TMPL-04**: 用户可在创建前预览模板包含的内容（世界设定骨架、角色原型、伏笔模式）
- [ ] **TMPL-05**: AI根据用户的故事概念自动补全模板中的空白字段
- [ ] **TMPL-06**: 每个类型模板包含3个开篇示例段落和类型专属伏笔模式（如玄幻：隐藏血脉→觉醒→渡劫）

### 开篇引导 (ONBD)

- [ ] **ONBD-01**: 首次启动App时自动检测并进入引导流程（go_router redirect guard）
- [ ] **ONBD-02**: 4步引导流程：选类型→创建世界→创建角色→AI生成开篇，每步均可跳过
- [ ] **ONBD-03**: 引导流程中断后可恢复，记住用户已完成的步骤
- [ ] **ONBD-04**: AI开篇生成器在引导流程外也可使用（编辑器内入口），生成3种风格开篇（场景切入/人物切入/悬念切入）
- [ ] **ONBD-05**: 用户可选择其中一种开篇，直接插入编辑器进行精修
- [ ] **ONBD-06**: 引导完成标记持久化，完成后不再自动触发

### 写作数据统计 (STAT)

- [ ] **STAT-01**: 全球数据面板展示所有作品的总字数、写作天数、AI辅助比例、会话总数
- [ ] **STAT-02**: 单项目详情展示章节字数分布、AI使用次数、编辑时长
- [ ] **STAT-03**: 折线图展示写作速度趋势（fl_chart LineChart），柱状图展示每日字数（fl_chart BarChart），饼图展示AI使用占比（fl_chart PieChart）
- [ ] **STAT-04**: 成就徽章：首个1000字、1万字、5万字，连续写作7/30/100天
- [ ] **STAT-05**: 写作数据采集对编辑器性能无感知影响（内存计数+30秒批量写入Hive）
- [ ] **STAT-06**: 支持清除所有写作统计数据（设置中提供按钮）

### 故事弧可视化 (VIZO)

- [ ] **VIZO-01**: 基于现有PlotNode数据自动生成交互式节点图（graphview库），支持缩放和平移
- [ ] **VIZO-02**: 因果关系用有向实线连接，关联关系用灰色细线，伏笔关系用虚线标注
- [ ] **VIZO-03**: 节点颜色按结构角色区分（铺垫/发展/转折/高潮/结局），边框样式按写作状态区分
- [ ] **VIZO-04**: 点击节点可内联编辑标题、结构角色、写作状态
- [ ] **VIZO-05**: 拖拽节点可重新排列位置，位置变化持久化
- [ ] **VIZO-06**: 缩略图导航（Minimap）帮助在大图中快速定位

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### 模板库 (v2)

- **TMPL-07**: 用户自定义创建空白模板（非基于预设）
- **TMPL-08**: 社区模板分享（需后端支持）
- **TMPL-09**: 从互联网自动更新模板数据
- **TMPL-10**: 混合类型模板（如都市+仙侠 = 都市修仙）

### 可视化 (v2)

- **VIZO-07**: 自动布局算法（力导向/分层布局）切换
- **VIZO-08**: 导出图表为PNG图片
- **VIZO-09**: 故事进度动画回放
- **VIZO-10**: 3D可视化模式

### 统计 (v2)

- **STAT-07**: 写作目标设定与进度提醒
- **STAT-08**: 导出统计报告为图片或文本
- **STAT-09**: 与其他作者对比数据（需云端）

### 引导 (v2)

- **ONBD-07**: 功能探索式教程（TutorialCoachMark覆盖层）
- **ONBD-08**: 视频教程嵌入

## Out of Scope

| Feature | Reason |
|---------|--------|
| 一键生成全书 | 违背核心理念，强制分段交互 |
| 短剧剧本功能 | 后续里程碑，非v1.1 scope |
| 云端同步/账户系统 | MVP所有数据本地存储 |
| iOS/macOS平台 | 先聚焦Windows/Android |
| 实时协作/多人编辑 | 单人创作工具 |
| 物理设备测试（v1.0 deferred） | 需要真实Windows设备，不在v1.1 scope |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TMPL-01 | Phase 7 | Pending |
| TMPL-02 | Phase 7 | Pending |
| TMPL-03 | Phase 7 | Pending |
| TMPL-04 | Phase 7 | Pending |
| TMPL-05 | Phase 7 | Pending |
| TMPL-06 | Phase 7 | Pending |
| ONBD-01 | Phase 8 | Pending |
| ONBD-02 | Phase 8 | Pending |
| ONBD-03 | Phase 8 | Pending |
| ONBD-04 | Phase 8 | Pending |
| ONBD-05 | Phase 8 | Pending |
| ONBD-06 | Phase 8 | Pending |
| STAT-01 | Phase 9 | Pending |
| STAT-02 | Phase 9 | Pending |
| STAT-03 | Phase 9 | Pending |
| STAT-04 | Phase 9 | Pending |
| STAT-05 | Phase 9 | Pending |
| STAT-06 | Phase 9 | Pending |
| VIZO-01 | Phase 10 | Pending |
| VIZO-02 | Phase 10 | Pending |
| VIZO-03 | Phase 10 | Pending |
| VIZO-04 | Phase 10 | Pending |
| VIZO-05 | Phase 10 | Pending |
| VIZO-06 | Phase 10 | Pending |

**Coverage:**
- v1.1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-06-04 after initial definition for v1.1*
