# Phase 7: 预设世界观模板库 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 7-预设世界观模板库
**Areas discussed:** 类型清单, 模板内容, 创建流程, AI补全, 数据来源, 筛选排序, 编辑粒度, 模板元数据

---

## 类型清单

| Question | Options | Selected |
|----------|---------|----------|
| 这14种小说类型应该怎么组织？ | 固定14类 / 主类+标签 / 你决定 | 主类+标签 |
| 画廊里要不要显式区分男频/女频？ | 频道分组 / 混合展示 / 分组+全部 | 分组+全部 |
| 每个模板卡片的标题应该按什么粒度命名？ | 主类型命名 / 热门标签命名 / 名称+副题 | 名称+副题 |
| 每个主类要带多少热门子标签？ | 每类2-4个 / 每类5-8个 / 单方向 | 每类5-8个 |

**Notes:** Gallery should preserve the roadmap's 8 male-frequency + 6 female-frequency intent while still giving users a unified browse mode.

---

## 模板内容

| Question | Options | Selected |
|----------|---------|----------|
| 模板预览页应该默认露出多少内容？ | 折叠全量 / 摘要优先 / 核心优先 | 折叠全量 |
| 每个模板应该内置多少角色原型？ | 1世界+3角色 / 1世界+5角色 / 角色模板 | 1世界+3角色 |
| 类型专属伏笔模式要用什么表达方式？ | 弧线结构 / 标签清单 / 单条示例 | 弧线结构 |
| 每个模板的3个开篇示例应该怎么区分？ | 三种切入 / 三种语气 / 同题三写 | 三种切入 |

**Notes:** Opening sample categories should align with Phase 8 opening generator categories.

---

## 创建流程

| Question | Options | Selected |
|----------|---------|----------|
| 使用模板后应该立即写入知识库吗？ | 直接创建 / 确认再建 / 草稿确认 | 草稿确认 |
| 草稿确认页里，用户能否选择只创建部分实体？ | 默认全选 / 全部必建 / 分步选择 | 默认全选 |
| 创建出来的实体名称应该怎么处理？ | 模板前缀 / 概念命名 / 默认可改 | 默认可改 |
| 模板里的伏笔弧线和开篇示例要不要写入现有知识库/故事结构？ | 只建实体 / 创建伏笔 / 写入备注 | 只建实体 |

**Notes:** Phase 7 must not expand into story-structure creation.

---

## AI补全

| Question | Options | Selected |
|----------|---------|----------|
| AI根据故事概念补全时，权限边界是什么？ | 只补空白 / 整体改写 / 补空+可润色 | 补空+可润色 |
| 故事概念输入框应该放在哪里？ | 预览页 / 草稿页 / 两处可改 | 两处可改 |
| AI补全结果应该以什么格式进入草稿字段？ | 结构JSON / Markdown解析 / 你决定 | 结构JSON |
| AI补全失败时，用户还能不能继续创建模板实体？ | 保留草稿 / 阻止保存 / 占位保底 | 保留草稿 |

**Notes:** AI failure must not block manual template creation.

---

## 数据来源

| Question | Options | Selected |
|----------|---------|----------|
| 14个模板的初始内容应该怎么生产？ | AI初稿+审核 / 人工编写 / 运行时AI | AI初稿+审核 |
| 模板内容的文案风格应该更偏哪种？ | 套路工具箱 / 平台风格 / 中性+热度 | 中性+热度 |
| 人工审核模板时，质量门槛要设到哪里？ | 四项审核 / 格式审核 / 重点审核 | 四项审核 |
| 模板数据后续怎么更新？ | 随App更新 / 预留导入 / 在线更新 | 随App更新 |

**Notes:** Review gates are important because template data quality/authenticity is a known Phase 7 concern.

---

## 筛选排序

| Question | Options | Selected |
|----------|---------|----------|
| 画廊的频道筛选入口应该怎么做？ | 三段切换 / 全部Chip / 频道标签 | 三段切换 |
| 每类5-8个热门子标签是否需要参与筛选？ | 单选标签 / 多选标签 / 只展示 | 只展示 |
| 画廊默认排序按什么规则？ | 策展排序 / 拼音排序 / 频道顺序 | 策展排序 |
| 模板画廊需要搜索框吗？ | 提供搜索 / 不搜索 / 桌面搜索 | 提供搜索 |

**Notes:** Tags are searchable metadata and card flavor, not active filters in Phase 7.

---

## 编辑粒度

| Question | Options | Selected |
|----------|---------|----------|
| 草稿确认页允许编辑哪些字段？ | 全字段编辑 / 轻编辑 / 折叠全字段 | 全字段编辑 |
| 全字段编辑页默认应该怎么展开？ | 默认折叠 / 全部展开 / 世界展开 | 默认折叠 |
| AI补全后的字段要不要标记来源？ | 来源标记 / 整体说明 / 不标记 | 来源标记 |
| 草稿保存成功后，用户应该看到什么？ | 结果摘要 / 跳知识库 / 打开世界观 | 结果摘要 |

**Notes:** This keeps templates editable/non-locked while avoiding an overwhelming default page.

---

## 模板元数据

| Question | Options | Selected |
|----------|---------|----------|
| 模板JSON需要多少维护型元数据？ | 完整元数据 / 最小元数据 / 展示来源 | 完整元数据 |
| 模板版本应该怎么表示？ | 独立版本 / App版本 / 模板版本 | 独立版本 |
| 这些元数据要不要在UI里露出？ | 轻提示 / 显示详情 / 不显示 | 轻提示 |
| 模板数据是否需要预留语言字段？ | 中文+预留 / 纯中文 / 中英内置 | 中文+预留 |

**Notes:** Metadata is primarily for maintenance, migrations, and testing. Creative UI should remain light.

## Claude's Discretion

None.

## Deferred Ideas

None.
