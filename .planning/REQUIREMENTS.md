# Requirements: MuseFlow 灵韵

**Defined:** 2026-06-06
**Core Value:** 让AI帮你写好故事，但让读者看不出AI的痕迹。

## v1.3 Requirements

Requirements for 用户视角全流程验证 — 百章修仙小说 milestone. Each maps to roadmap phases.

### Token 审计基础设施

- [x] **AUDIT-01**: 每次 AI API 调用记录 token 用量（输入 token、输出 token、模型名称、操作类型、关联章节ID、时间戳）
- [x] **AUDIT-02**: Token 审计数据持久化到独立 Hive box（TokenAuditRecord 实体），不侵入现有 Chapter/Manuscript domain 层
- [ ] **AUDIT-03**: 可查看 token 消耗总览页面（总成本、每章分布、按操作类型分布）

### 自动化测试

- [ ] **TEST-01**: Dart 自动化脚本走完核心流程（创建文稿→创建100章→调用AI生成内容→导出），不依赖 UI
- [ ] **TEST-02**: Flutter 集成测试覆盖关键 UI 节点（文稿创建→章节管理→AI生成→编辑→导出）
- [ ] **TEST-03**: 测试脚本使用 FakeAdapter 支持可复现验证，无需真实 API 即可跑通

### 创作准备验证

- [ ] **JOURNEY-01**: 用修仙模板搭建世界观（角色卡创建、设定集创建、Skill 设定守护配置）
- [ ] **JOURNEY-02**: 碎片捕捉→AI整理流程验证（子弹笔记模式输入灵感碎片→AI整理成逻辑通畅的故事段落）
- [ ] **JOURNEY-03**: 开篇引导生成第一章（验证3种风格开篇：场景切入/人物切入/悬念切入）

### 核心创作验证

- [ ] **JOURNEY-04**: 100章创建和管理（CRUD操作、章节排序、拆分、合并、复制、删除），验证多文稿架构可靠性
- [ ] **JOURNEY-05**: 逐章 AI 内容生成（每章~100字修仙/玄幻内容），验证知识库自动注入和 Skill 设定守护的连续性
- [ ] **JOURNEY-06**: 编辑器浮窗操作验证（选中文本→语气改写、段落润色、自由输入编辑），验证反AI味效果

### 精修打磨验证

- [ ] **JOURNEY-07**: 故事结构验证（伏笔埋设→跨章跟踪→填坑解决），验证逻辑闭环检测和一致性守护
- [ ] **JOURNEY-08**: 格式清洗验证（标点修复、排版美化、Markdown残留清理）

### 输出验证

- [ ] **JOURNEY-09**: 三格式导出验证（Markdown 带章节标题结构、TXT 纯文本、JSON 含完整元数据）
- [ ] **JOURNEY-10**: 写作统计数据验证（字数统计、AI使用率、写作速度）

### 分析与报告

- [ ] **REPORT-01**: Token 消耗分析报告（万字短篇实际成本 + 传统长篇50万字消耗推算 + 优化建议）
- [ ] **REPORT-02**: 用户痛点报告（功能缺陷列表 + 体验摩擦点 + 缺失需求建议，按严重程度分类）
- [ ] **REPORT-03**: 反AI味效果评估（盲读测试：选取若干段落由人判断是否AI生成）
- [ ] **REPORT-04**: 知识库一致性衰减分析（100章后角色卡和设定集与实际内容的一致性对比）

## Out of Scope

| Feature | Reason |
|---------|--------|
| 多 Provider 并行测试 | 复杂度过高，先用单一 GLM API 完成验证 |
| 真机物理设备测试 (IME/启动/生命周期) | 已在 v1.0 延迟，本里程碑聚焦功能验证 |
| 无障碍性审计 (Accessibility) | 独立主题，不在本里程碑范围 |
| 1000+ 章压力测试 | 100章验证已足够发现架构问题 |
| 章节摘要自动更新机制 | 研究发现该功能不存在，构建属于新功能开发 |
| Deviation Detection 范围扩展 | 当前仅检查 Skill 文档，扩展到角色卡/设定集属于新功能 |
| Token 精确计数 (stream_options) | 需要修改 OpenAI adapter，估算值对本里程碑足够 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDIT-01 | Phase 12 | Complete |
| AUDIT-02 | Phase 12 | Complete |
| AUDIT-03 | Phase 12 | Pending |
| TEST-01 | Phase 13 | Pending |
| TEST-02 | Phase 13 | Pending |
| TEST-03 | Phase 13 | Pending |
| JOURNEY-01 | Phase 14 | Pending |
| JOURNEY-02 | Phase 14 | Pending |
| JOURNEY-03 | Phase 14 | Pending |
| JOURNEY-04 | Phase 14 | Pending |
| JOURNEY-05 | Phase 14 | Pending |
| JOURNEY-06 | Phase 14 | Pending |
| JOURNEY-07 | Phase 15 | Pending |
| JOURNEY-08 | Phase 15 | Pending |
| JOURNEY-09 | Phase 15 | Pending |
| JOURNEY-10 | Phase 15 | Pending |
| REPORT-01 | Phase 16 | Pending |
| REPORT-02 | Phase 16 | Pending |
| REPORT-03 | Phase 16 | Pending |
| REPORT-04 | Phase 16 | Pending |

**Coverage:**
- v1.3 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-06-06*
*Last updated: 2026-06-06 after roadmap creation*
