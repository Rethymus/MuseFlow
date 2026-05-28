---
name: commit-message-standards
description: Commit消息规范遵循GitHub官方准则
metadata: 
  node_type: memory
  type: reference
  originSessionId: 722bc612-8d9f-4032-b1be-353134450a76
---

# Commit消息规范

## 格式要求

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Type类型

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(ai): add contextual service` |
| `fix` | 修复bug | `fix: resolve memory leak` |
| `docs` | 文档更新 | `docs: update API guide` |
| `style` | 代码格式 | `style: format code` |
| `refactor` | 代码重构 | `refactor: simplify adapter` |
| `perf` | 性能优化 | `perf: improve cache hit rate` |
| `test` | 测试相关 | `test: add integration tests` |
| `chore` | 构建/工具 | `chore: update dependencies` |

## 关键原则

1. **使用祈使句**: "Fix bug" 而非 "Fixed bug" 或 "Fixes bug"
2. **首行简短**: 不超过50字符
3. **空行分隔**: 标题和正文之间空一行
4. **解释what和why**: 不需要解释how

## 示例

### 简单提交
```bash
git commit -m "feat: add knowledge graph engine"
git commit -m "fix: resolve cache race condition"
```

### 详细提交
```bash
feat(knowledge): implement semantic search engine

Add vector embedding support for semantic similarity search:
- Vector database integration interface
- Similarity search algorithm
- Multi-modal search support framework
- Search suggestion generation

This enables intelligent content discovery beyond keyword matching.

Closes #123
Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
```

### 修复提交
```bash
fix(memory): resolve memory leak in cache manager

The LRU cache was not properly evicting old entries when
the size limit was reached, causing unbounded memory growth.

Added proper size checking and eviction logic in the
put() method.

Fixes #456
```

## Footer引用

- `Closes #123` - 关闭issue
- `Fixes #456` - 修复issue
- `Refs #789` - 引用issue
- `Co-Authored-By:` - 共同作者

## 错误示例

❌ `"Fixed the bug"` - 使用过去式
❌ `"Adding new feature"` - 使用进行时
❌ `"update docs"` - 首字母小写
❌ `"fix: fix the bug that was causing the crash"` - 标题过长

## 正确示例

✅ `"feat: add user authentication"`
✅ `"fix: resolve null pointer exception"`
✅ `"docs: update installation guide"`
