# MuseFlow 架构规则

## 四层架构

```
Presentation → Application → Domain ← Infrastructure
```

**依赖方向**: 外层 → 内层，单向依赖，禁止反向引用。

## 目录结构

```
lib/
├── core/                    # 核心基础设施
│   ├── domain/             # 实体、值对象、领域服务（纯Dart）
│   ├── application/        # 用例、DTO、端口接口
│   ├── infrastructure/     # 仓储实现、数据源、外部API
│   └── presentation/       # 页面、组件、Riverpod providers
├── features/               # 功能模块（同结构）
│   ├── editor/             # 编辑器
│   ├── knowledge/          # 知识库
│   └── ai/                 # AI服务
└── shared/                 # 共享工具、主题、常量
```

## 层职责与规则

### Domain 层（最内层）
- ✅ 纯 Dart，无 Flutter 依赖
- ✅ 实体、值对象、领域服务接口
- ❌ 不依赖任何其他层

### Application 层
- ✅ 用例编排、DTO 定义、端口接口
- ✅ 可依赖 Domain 层
- ❌ 不依赖 Infrastructure 层

### Infrastructure 层
- ✅ 实现 Domain 定义的接口
- ✅ 外部 API 调用、数据持久化
- ❌ 不被 Domain 层依赖

### Presentation 层
- ✅ UI 组件、Riverpod providers
- ✅ 可依赖 Application 层
- ❌ 不直接访问 Infrastructure 层
- ❌ 不包含业务逻辑

## 关键约束

- AI 适配器统一接口，兼容 OpenAI/Claude/DeepSeek/Ollama
- 本地存储优先（Hive + JSON）；API Key 通过平台安全存储保存，不写入 Hive
- 强制分段交互，不提供"一键生成"功能
