# MuseFlow 依赖管理系统

## 概述

MuseFlow依赖管理系统提供精确的版本控制和全面的依赖审计功能，确保项目依赖的稳定性和可维护性。

## 核心功能

### 1. 精确版本控制
- 所有依赖使用精确的版本号（x.y.z格式）
- 消除版本不确定性导致的兼容性问题
- 确保跨环境部署的一致性

### 2. 依赖审计
- 自动解析和验证所有依赖项
- 检测版本冲突和兼容性问题
- 生成详细的健康报告

### 3. 变更追踪
- 完整的依赖变更历史记录
- 支持变更原因分类（安全、功能、修复等）
- 提供变更审计跟踪

### 4. 健康监控
- 实时依赖健康评分
- 过时依赖检测和建议
- 优先级更新推荐

## 文件结构

```
MuseFlow/
├── pubspec.yaml                          # 主依赖配置（精确版本）
├── .dependency_audit_log.json            # 依赖变更日志
├── .dependency_health_report.json        # 健康报告缓存
├── .dependency_constraints.json          # 依赖约束配置
├── lib/
│   └── utils/
│       ├── dependency_auditor.dart       # 核心审计类
│       └── dependency_manager.dart        # 管理器入口
└── bin/
    └── dependency_audit.dart             # CLI工具
```

## 使用方法

### 命令行工具

```bash
# 执行完整审计
dart bin/dependency_audit.dart

# 快速健康检查
dart bin/dependency_audit.dart health

# 生成Markdown报告
dart bin/dependency_audit.dart report

# 导出JSON数据
dart bin/dependency_audit.dart json

# 仅显示更新建议
dart bin/dependency_audit.dart suggestions

# 仅显示冲突
dart bin/dependency_audit.dart conflicts

# 显示帮助
dart bin/dependency_audit.dart help
```

### 编程API

```dart
import 'package:museflow/utils/dependency_manager.dart';

void main() async {
  // 创建管理器
  final manager = DependencyManager(projectPath: '/path/to/project');

  // 执行完整审计
  final result = await manager.performFullAudit();

  if (result.success) {
    print('健康评分: ${result.healthReport.score}');
    print('冲突数: ${result.conflicts.length}');
    print('过时依赖: ${result.healthReport.outdatedCount}');
  }

  // 快速健康检查
  final status = await manager.quickHealthCheck();
  print('项目健康: ${status.isHealthy}');

  // 记录依赖变更
  await manager.recordDependencyChange(
    packageName: 'http',
    oldVersion: '1.2.0',
    newVersion: '1.2.2',
    reason: ChangeReason.security,
    author: 'developer@example.com',
    notes: '修复CVE-2024-12345',
  );
}
```

## 依赖类别

### 生产依赖
- **UI组件**: cupertino_icons
- **窗口管理**: window_manager, flutter_acrylic
- **数据存储**: hive, hive_flutter, sqflite, path_provider
- **状态管理**: provider
- **工具库**: intl, uuid, json_annotation
- **文件操作**: file_picker, share_plus
- **HTTP客户端**: http, dio
- **安全加密**: flutter_secure_storage, encrypt
- **重试逻辑**: retry

### 开发依赖
- **代码生成**: build_runner, hive_generator, json_serializable
- **代码检查**: flutter_lints

## 版本策略

### 精确版本规则
- 使用 `x.y.z` 格式，不使用 `^` 或 `~` 前缀
- 每个依赖都有明确固定的版本号
- 更新需要手动审核和测试

### 更新流程
1. 检查可用更新: `dart bin/dependency_audit.dart suggestions`
2. 评估优先级和风险
3. 在开发环境测试新版本
4. 记录变更原因和测试结果
5. 更新 pubspec.yaml 并提交

## 健康评分标准

| 分数 | 条件 | 建议 |
|------|------|------|
| 优秀 (🟢) | 无错误、无冲突、警告<3 | 继续保持 |
| 良好 (🟡) | 无错误、无冲突、警告<5 | 监控警告 |
| 一般 (🟠) | 无错误、冲突<2、警告<10 | 计划更新 |
| 较差 (🔴) | 有错误或冲突>2 | 立即修复 |
| 危急 (🚨) | 有严重错误或冲突>5 | 紧急处理 |

## 变更原因分类

- **manual**: 手动更新
- **security**: 安全修复
- **feature**: 新功能需求
- **bugfix**: Bug修复
- **compatibility**: 兼容性要求
- **dependency_update**: 依赖传递更新

## 约束配置

`.dependency_constraints.json` 定义了版本约束规则：

```json
{
  "packageName": "http",
  "constraint": ">=1.0.0",
  "reason": "安全要求：支持TLS 1.3",
  "imposedAt": "2026-05-28T00:00:00.000Z",
  "source": "security_policy"
}
```

## 最佳实践

### 1. 定期审计
- 每周执行健康检查
- 每月生成完整报告
- 重大变更前执行审计

### 2. 安全优先
- 优先更新安全相关依赖
- 关注CVE漏洞公告
- 及时更新安全补丁

### 3. 测试验证
- 每次更新后运行测试套件
- 在开发环境充分验证
- 记录测试结果和问题

### 4. 文档记录
- 详细记录变更原因
- 保存测试结果
- 维护变更日志

## 故障排除

### 常见问题

**Q: 如何解决版本冲突？**
A: 运行 `dart bin/dependency_audit.dart conflicts` 查看详情，按照建议的解决方案调整版本。

**Q: 依赖更新后应用崩溃？**
A: 检查 `.dependency_audit_log.json` 中的变更记录，回滚到上一个工作版本，分析崩溃原因。

**Q: 如何验证约束配置？**
A: 系统会自动验证约束。如果验证失败，检查 `.dependency_constraints.json` 中的配置是否正确。

## 技术支持

如遇问题，请检查以下文件：
- `pubspec.yaml` - 依赖配置
- `.dependency_audit_log.json` - 变更历史
- `.dependency_health_report.json` - 健康状态
- `.dependency_constraints.json` - 约束规则

## 版本历史

- **v1.0.0** (2026-05-28): 初始版本
  - 精确版本控制实现
  - 依赖审计功能
  - 健康监控系统
  - CLI工具集成
