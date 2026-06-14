# MuseFlow 数据存储架构规格

> 本文档描述 MuseFlow 灵韵在 Windows / Android / Linux / Web 四个目标平台上的数据存储方式、Hive 数据库的 Box 清单与 Schema、加密机制与平台限制。
>
> 适用版本：0.1.4+5 ｜ 最后更新：2026-06-14

---

## 1. 架构概览

MuseFlow 采用**三层本地优先存储**，无任何云端依赖（符合 PROJECT.md「所有配置与文稿仅存本地」约束）。

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation / Application              │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
        ┌───────▼────────┐          ┌─────────▼─────────┐
        │  ① Hive 主库    │          │ ② 密钥存储         │
        │  (hive_ce)      │          │ (flutter_secure_  │
        │  18 个 Box       │          │   storage)        │
        │  业务数据全部     │          │ API Key + 主密钥  │
        └───────┬────────┘          └─────────┬─────────┘
                │                             │
        ┌───────▼─────────────────────────────▼─────────┐
        │           平台后端（由平台自动选择）            │
        ├──────────────┬──────────────┬────────┬─────────┤
        │   Windows    │   Android    │ Linux  │   Web   │
        │  .hive 文件   │ 沙箱 .hive   │ .hive  │IndexedDB│
        │ Credential Mgr│ Keystore+Prefs│libsecret│ (绕过) │
        └──────────────┴──────────────┴────────┴─────────┘
                │
        ┌───────▼────────┐
        │ ③ 导出交付       │
        │ (条件导出分流)   │
        │ io: 本地文件     │
        │ web: Blob 下载   │
        └────────────────┘
```

**初始化入口**：`lib/main.dart:66` → `await Hive.initFlutter()`，由 `hive_ce_flutter` 按平台自动解析存储路径 / 切换后端，业务代码**不直接调用 path_provider**（依赖仅声明于 `pubspec.yaml:47`）。

---

## 2. 平台后端矩阵

| 平台 | ① Hive 数据库 | ② API Key / 主密钥 | ③ 导出交付 | 平台特殊处理 |
|------|--------------|-------------------|-----------|-------------|
| **Windows** | 本地文件系统 `.hive` 文件（`path_provider` 文档目录下） | **Windows Credential Manager** | `file_picker` 选路径 → `File.writeAsString` | `window_manager` 控制原生窗口；TSF 原生 IME |
| **Android** | 应用私有沙箱 `.hive` 文件 | **Android Keystore + 加密 SharedPreferences** | 本地保存 / `share_plus` 分享 | Android Keystore 硬件级隔离 |
| **Linux** | 本地文件系统 `.hive` 文件 | **Secret Service / libsecret** | `file_picker` 选路径 → `File.writeAsString` | ⚠️ 需 GNOME Keyring / KDE Wallet；无 keyring 时抛平台异常 |
| **Web** | **IndexedDB**（非文件系统） | ⚠️ **无原生安全后端，被代码主动绕过** | 浏览器 `Blob` + `<a download>` 触发下载 | `kIsWeb` 分支跳过加密读取、清理任务、窗口配置 |

后端声明见 `lib/core/infrastructure/secure_storage_service.dart:4-11`；导出分流见 `lib/core/platform/export_file_writer.dart`（条件导出 `io.dart` / `web.dart`）。

---

## 3. Hive 数据库总览

### 3.1 初始化与适配器注册

`main()` 启动序列（`lib/main.dart:60-124`）：

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Hive.initFlutter()` — 按平台初始化存储后端
3. 注册 11 个 TypeAdapter（`hive_adapters.dart`，TypeId 0–10）
4. `!kIsWeb` 时执行 30 天软删除清理（`ManuscriptPurgeService`）
5. `!kIsWeb` 时读取加密 `settings` box 的窗口几何
6. `!kIsWeb` 时配置原生窗口
7. `runApp`

### 3.2 TypeAdapter 与序列化策略

所有适配器均为**手写实现**（`lib/core/infrastructure/hive_adapters.dart`），序列化委托给各领域实体的 `fromJson` / `toJson`（同样是手写，非 freezed 生成）：

```dart
@override
Manuscript read(BinaryReader reader) =>
    Manuscript.fromJson(reader.readMap() as Map<String, dynamic>);
@override
void write(BinaryWriter writer, Manuscript obj) => writer.writeMap(obj.toJson());
```

TypeId 集中注册于 `HiveTypeIds`（`hive_adapters.dart:16-28`），避免冲突。

### 3.3 加密边界（重要）

| 加密状态 | Box | 说明 |
|---------|-----|------|
| 🔒 **AES-256 CBC 加密** | `settings` | 唯一加密 box。`HiveAesCipher(encryptionKey)` 包裹。存窗口几何、用户偏好、禁用词、上次导出路径等配置 |
| 🔓 **明文存储** | 其余 17 个 box | `Hive.openBox('xxx')` 不带 `encryptionCipher`。**文稿正文（`chapters.documentContent`）为明文本地存储** |

> **隐私边界澄清**：API Key 与 Hive 主密钥通过 OS 安全后端加密；文稿正文靠「仅存本地」而非「加密」保证隐私。这与 CLAUDE.md「API Key 加密、文稿仅存本地」一致。

---

## 4. Box 清单总览（18 个）

| # | Box 名 | 加密 | Value 类型 | TypeId | 用途 | 实体/定义文件 |
|---|--------|------|-----------|--------|------|--------------|
| 1 | `settings` | 🔒 | Map (k-v) | 1 | 窗口几何、默认标签、创造力等级、禁用词、上次导出路径 | `app_settings.dart` / `settings_repository.dart` |
| 2 | `manuscripts` | 🔓 | Manuscript | 2 | 文稿（作品）容器 | `manuscript/domain/manuscript.dart` |
| 3 | `chapters` | 🔓 | Chapter | 9 | 章节与正文 | `manuscript/domain/chapter.dart` |
| 4 | `fragments` | 🔓 | Fragment | 0 | 灵感碎片 | `core/domain/fragment.dart` |
| 5 | `character_cards` | 🔓 | CharacterCard | 3 | 角色卡 | `knowledge/domain/character_card.dart` |
| 6 | `world_settings` | 🔓 | WorldSetting | 4 | 世界观设定 | `knowledge/domain/world_setting.dart` |
| 7 | `skill_documents` | 🔓 | SkillDocument | 5 | Skill 规则文档 | `knowledge/domain/skill_document.dart` |
| 8 | `foreshadowing_entries` | 🔓 | ForeshadowingEntry | 6 | 伏笔追踪 | `story_structure/domain/foreshadowing_entry.dart` |
| 9 | `plot_nodes` | 🔓 | PlotNode | 7 | 剧情节点 | `story_structure/domain/plot_node.dart` |
| 10 | `guardian_annotations` | 🔓 | GuardianAnnotation | 8 | 逻辑守护批注 | `story_structure/domain/guardian_annotation.dart` |
| 11 | `token_audit` | 🔓 | TokenAuditRecord | 10 | Token 消费审计 | `stats/domain/token_audit_record.dart` |
| 12 | `ai_providers` | 🔓 | Map (dynamic) | — | AI 模型供应商配置（**API Key 另存 SecureStorage**） | `presentation/providers.dart:216` |
| 13 | `writing_stats` | 🔓 | Map (dynamic) | — | 写作统计聚合 | `stats` 模块 |
| 14 | `daily_writing_stats` | 🔓 | Map (dynamic) | — | 每日写作统计 | `stats` 模块 |
| 15 | `achievement_badges` | 🔓 | Map (dynamic) | — | 成就徽章 | `stats` 模块 |
| 16 | `character_relationships` | 🔓 | Map (dynamic) | — | 角色关系图 | `knowledge` 模块 |
| 17 | `graph_positions` | 🔓 | Map (dynamic) | — | 故事弧图节点坐标 | `story_structure` 模块 |
| 18 | `style_profiles` | 🔓 | Map (dynamic) | — | 文风配置 | `presentation/providers.dart:854` |

> 表格中 `Map (dynamic)` 表示该 box 未注册类型化适配器，存储原始 Map 结构；具体字段由对应 feature 模块在运行期定义，详见各模块 repository。

---

## 5. 核心实体 Schema

### 5.1 文稿与章节

**Manuscript**（TypeId 2）— 文稿容器，拥有多个 Chapter

| 字段 | 类型 | 约束 / 默认 | 说明 |
|------|------|------------|------|
| `id` | String | 必填 | UUID |
| `title` | String | 必填 | 标题 |
| `description` | String? | — | 简介 |
| `genre` | String | 必填 | 题材 |
| `targetWordCount` | int | 默认 0 | 目标字数 |
| `status` | String | 默认 `构思中` | 构思中/写作中/已完成 |
| `worldSettingId` | String? | — | 关联世界观 |
| `characterCardIds` | List\<String\> | 默认 [] | 关联角色卡 |
| `coverLetter` | String | 默认 '' | 封面字符（卡片显示用，≤2 字符） |
| `createdAt` | DateTime | 必填 | ISO-8601 |
| `updatedAt` | DateTime | 必填 | ISO-8601 |
| `deletedAt` | DateTime? | — | 软删除标记（30 天后清理） |

**Chapter**（TypeId 9）— 章节，正文为 **Markdown 字符串**

| 字段 | 类型 | 约束 / 默认 | 说明 |
|------|------|------------|------|
| `id` | String | 必填 | UUID |
| `manuscriptId` | String | 必填 | 所属文稿 |
| `title` | String | 必填 | 章节标题 |
| `sortOrder` | int | 必填 | 排序序号 |
| `status` | String | 默认 `草稿` | 草稿/初稿/精修/定稿 |
| `documentContent` | String | 默认 '' | **序列化 Markdown（非 JSON）**；`wordCount` 为派生 getter（去空白字符数） |
| `createdAt` / `updatedAt` | DateTime | 必填 | ISO-8601 |

### 5.2 灵感碎片

**Fragment**（TypeId 0）

| 字段 | 类型 | 约束 / 默认 | 说明 |
|------|------|------------|------|
| `id` | String | 必填 | UUID |
| `text` | String | 必填 | 碎片文本 |
| `tags` | List\<String\> | 默认 [] | 标签筛选 |
| `createdAt` | DateTime | 必填 | ISO-8601 |
| `updatedAt` | DateTime? | — | ISO-8601 |

### 5.3 知识库

**CharacterCard**（TypeId 3）— 角色卡，用于 AI 上下文注入

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | String | 必填 | UUID |
| `name` | String | ≤ 100 字符，禁控制字符 | 角色名 |
| `personality` | String | 默认 '', ≤ 5000 | 性格 |
| `appearance` | String | 默认 '', ≤ 5000 | 外貌 |
| `backstory` | String | 默认 '', ≤ 5000 | 背景 |
| `aliases` | List\<String\> | ≤ 20 项，每项 ≤ 50 字符 | 别名 |
| `lastVerifiedChapter` | int? | — | MC-01 陈旧度追踪：上次校验章节号（null 视为新鲜） |
| `createdAt` / `updatedAt` | DateTime | 必填 / 可空 | ISO-8601 |

**WorldSetting**（TypeId 4）— 世界观

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | String | 必填 | UUID |
| `name` | String | ≤ 100 | 名称 |
| `description` | String | ≤ 5000 | 描述 |
| `rules` | String | ≤ 5000 | 规则 |
| `factions` | String | ≤ 5000 | 势力 |
| `geography` | String | ≤ 5000 | 地理 |
| `techLevel` | String | ≤ 5000 | 科技/魔法等级 |
| `aliases` | List\<String\> | ≤ 20×50 | 别名 |
| `lastVerifiedChapter` | int? | — | MC-01 陈旧度 |
| `createdAt` / `updatedAt` | DateTime | 必填 / 可空 | ISO-8601 |

**SkillDocument**（TypeId 5）— Skill 规则文档

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | String | 必填 | UUID |
| `name` | String | 必填 | 名称 |
| `description` | String | — | 描述 |
| `content` | String | ≤ 50000 | 原始内容 |
| `sections` | SkillSections | 必填 | 结构化分段（见下） |
| `isActive` | bool | 默认 false | 是否启用为写作规则 |
| `createdAt` / `updatedAt` | DateTime | 必填 / 可空 | ISO-8601 |

`SkillSections` 嵌套结构（每段 ≤ 10000 字符）：`powerHierarchy`（力量等级体系）、`factionRelations`（势力关系）、`rules`（世界规则）、`taboos`（禁忌/限制）、`terminology`（专用术语）、`rawContent`（原始内容）。

### 5.4 故事结构

**ForeshadowingEntry**（TypeId 6）— 伏笔追踪

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | UUID |
| `title` | String | 标题 |
| `mode` | enum (`simple`/`detailed`) | 简易清单 / 完整状态流 |
| `status` | enum (`planted`/`developing`/`resolved`/`abandoned`) | 生命周期状态 |
| `plantedChapter` | int | 埋设章节 |
| `targetResolutionChapter` | int? | 计划回收章节 |
| `resolvedChapter` | int? | 实际回收章节 |
| `sourceExcerpt` | String | 原文摘录 |
| `sourceLocation` | SourceLocation? | 编辑器内定位（nodeId/startOffset/endOffset/chapter?） |
| `notes` | String | 备注 |
| `linkedPlotNodeIds` | List\<String\> | 关联剧情节点 |
| `createdAt` / `updatedAt` | DateTime | ISO-8601 |

**PlotNode**（TypeId 7）— 剧情节点

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` / `title` | String | UUID / 标题 |
| `chapter` | int | 章节位置 |
| `summary` | String | 摘要 |
| `writingStatus` | enum (`notStarted`/`drafting`/`complete`/`needsRevision`) | 写作状态 |
| `structuralRole` | enum (`setup`/`development`/`turn`/`climax`/`resolution`) | 结构角色 |
| `involvedCharacterIds` / `involvedCharacterNames` | List\<String\> | 参与角色 |
| `linkedForeshadowingIds` | List\<String\> | 关联伏笔 |
| `causeNodeIds` / `consequenceNodeIds` / `relatedNodeIds` | List\<String\> | 因果/关联节点 |
| `manualOrder` | int | 手动排序 |
| `createdAt` / `updatedAt` | DateTime | ISO-8601 |

**GuardianAnnotation**（TypeId 8）— 逻辑守护批注（咨询性，不自动改文稿）

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | UUID |
| `kind` | enum (`characterConsistency`/`timelineContradiction`/`worldRuleConflict`/`skillRuleConflict`/`unresolvedForeshadowing`) | 发现类型 |
| `severity` | enum (`low`/`medium`/`high`) | 严重度 |
| `message` / `reason` | String | 消息 / 理由 |
| `suggestedFix` | String? | 建议修复 |
| `nodeId` / `startOffset` / `endOffset` | String? / int? | 文档内精确位置（三者非空才有效） |
| `sourceText` | String? | 源文本 |
| `characterIds` / `worldSettingIds` / `skillIds` / `plotNodeIds` / `foreshadowingIds` | List\<String\> | 关联实体 |
| `createdAt` | DateTime | 必填 |
| `dismissedAt` | DateTime? | 被作者忽略的时间 |

### 5.5 统计

**TokenAuditRecord**（TypeId 10）— AI 调用 Token 审计

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | UUID |
| `inputTokens` / `outputTokens` | int | ≥ 0；`totalTokens` 为派生 getter |
| `modelName` | String | 模型名 |
| `operationTypeIndex` | int | `AuditOperationType` 枚举索引（**注意：存为 index，非字符串**） |
| `manuscriptId` | String | 必填 |
| `chapterId` | String? | 可空 |
| `timestamp` | DateTime | ISO-8601 |

### 5.6 设置（加密 box）

`settings` box 的 key-value 结构（`settings_repository.dart`）：

| Key | 类型 | 说明 |
|-----|------|------|
| `windowSize` | `{width, height}` | 窗口尺寸 |
| `windowPosition` | `{x, y}` | 窗口位置 |
| `defaultTag` | String | 默认碎片标签（默认 `故事`） |
| `auto_deviation_check` | bool | 是否自动一致性检查（默认 false，避免 token 翻倍） |
| `creativity_level` | String | 创造力等级（AA-03，影响生成温度） |
| `banned_phrases` | List\<String\> | 反 AI 味禁用词表 |
| `last_export_path` | String? | 上次导出路径（本地，不含文稿内容） |

---

## 6. 密钥存储：SecureStorageService

`lib/core/infrastructure/secure_storage_service.dart` 封装 `flutter_secure_storage`（`^10.3.1`）。

**存储两类敏感值**：

| 用途 | Key 前缀 | 示例 |
|------|---------|------|
| AI 供应商 API Key | `api_key_<providerId>` | `api_key_openai`、`api_key_claude`、`api_key_deepseek` |
| Hive 加密主密钥 | `hive_encryption_key` | Base64 编码的 AES 密钥 |

**各平台后端**（由 `flutter_secure_storage` 自动选择）：

| 平台 | 后端 | 特性 |
|------|------|------|
| Windows | Windows Credential Manager | OS 级 DPAPI 加密 |
| Android | Android Keystore + 加密 SharedPreferences | 硬件级（TEE/StrongBox） |
| Linux | Secret Service / libsecret | 依赖 D-Bus keyring daemon |
| Web | ⚠️ 无原生后端（Web Crypto + localStorage 模拟） | **项目代码主动绕过**，见第 8 节 |

> 设计约束（`secure_storage_service.dart:8-11`）：**不回落明文文件**。平台后端不可用时向上抛平台异常，由调用方呈现可操作错误。

---

## 7. 加密机制

`settings` box 的加密链路（`lib/main.dart:23-58` + `presentation/providers.dart:111-120`）：

```
首次启动:
  生成随机 AES 密钥 → Base64 → 存入 SecureStorage('hive_encryption_key')

后续启动:
  SecureStorage 读取密钥 → base64Decode → HiveAesCipher
  → Hive.openBox('settings', encryptionCipher: cipher)
```

- 算法：AES-256 CBC（Hive CE 内建 `HiveAesCipher`）
- 仅 `settings` box 加密；其余 box 明文（见第 3.3 节边界说明）
- 密钥丢失 → `settings` box 无法解密 → `_readSavedGeometry` 捕获异常并退回默认值（`main.dart:54-57`）

---

## 8. 平台限制与注意事项

### 8.1 Web 平台（测试/UAT 目标，非生产）

Web 存在三个已知限制，代码以 `kIsWeb` 分支主动规避：

1. **加密 `settings` 读取被跳过**（`main.dart:109-111`）：注释明确「SecureStorageService may hang」。Web 首次启动无法解密读取窗口几何等配置 → 退回默认值。
2. **业务任务跳过**（`main.dart:86`）：30 天软删除清理（`ManuscriptPurgeService`）在 Web 不执行。
3. **API Key 安全性弱**：`flutter_secure_storage` 在 Web 仅能用 Web Crypto + localStorage 模拟，非 OS 级隔离；本项目已绕过该路径 → **Web 端 API Key 存储是未妥善解决的痛点**，印证 Web 仅作测试目标。

### 8.2 Linux libsecret 依赖

Linux 平台的 `flutter_secure_storage` 后端依赖 Secret Service / libsecret。在无桌面 keyring（headless 服务器、最小化窗口管理器）的环境下会抛平台异常。**部署建议**：安装 `gnome-keyring` 或等效组件，否则 API Key 保存/读取失败。

### 8.3 软删除与清理

`ManuscriptPurgeService`（`main.dart:83-103`）在桌面/移动平台每次启动时，清理 `deletedAt` 超过 30 天的软删除文稿（D-21）。Web 跳过。

---

## 9. 导出交付机制

导出走条件导出分流（`lib/core/platform/export_file_writer.dart`）：

```dart
export 'export_file_writer_io.dart'
    if (dart.library.html) 'export_file_writer_web.dart';
```

| 平台 | 实现 | 行为 |
|------|------|------|
| 桌面/移动 | `export_file_writer_io.dart` | `File(path).writeAsString`；路径由 `file_picker` 的 `saveFile` 选择 |
| Web | `export_file_writer_web.dart` | `Blob` + `URL.createObjectURL` + `<a download>` 触发浏览器下载；无文件系统路径 |

导出格式支持：Markdown / 纯文本 / DOCX（`export_service.dart` 用 `archive` 包拼装 `.docx` 的 OOXML）。`last_export_path` 仅在非 Web 记录。

---

## 10. 相关文件索引

| 关注点 | 文件 |
|--------|------|
| 启动初始化 | `lib/main.dart` |
| TypeAdapter 注册 | `lib/core/infrastructure/hive_adapters.dart` |
| 密钥存储服务 | `lib/core/infrastructure/secure_storage_service.dart` |
| 设置仓储（加密 box） | `lib/core/infrastructure/settings_repository.dart` |
| Box 开启与 Provider 绑定 | `lib/core/presentation/providers.dart` |
| 导出分流 | `lib/core/platform/export_file_writer*.dart` |
| 窗口控制（平台分流） | `lib/core/platform/window_controller*.dart` |

---

*本文档基于 0.1.4+5 版本代码梳理生成。Box 新增或 Schema 变更时请同步更新本文档与对应 TypeId 注册表。*
