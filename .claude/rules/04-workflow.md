# 开发工作流规则

## 功能开发（推荐）

```
1. /gsd discuss   — 需求讨论，明确规格
2. /gsd plan      — 生成实施计划
3. /tdd           — 编写测试（先写测试！）
4. /gsd execute   — 实现功能
5. /code-review   — 代码审查
6. /verify        — 验证实现
7. git commit     — 提交变更
```

## 快速迭代

```
1. /autopilot "描述" — 自动规划+实现
2. /verify           — 验证
3. git commit        — 提交
```

## Bug 修复

```
1. 描述问题 → 定位根因
2. 编写失败测试（RED）
3. 修复代码（GREEN）
4. /verify — 验证修复
5. git commit
```

## 重构

```
1. 确认测试覆盖率 ≥ 90%
2. 每次只改一个关注点
3. 小步前进，每步运行测试
4. /code-review — 审查
5. git commit
```

## 提交规范

```
feat(范围): 简短描述
fix(范围): 简短描述
refactor(范围): 简短描述
docs(范围): 简短描述
test(范围): 简短描述
chore(范围): 简短描述
```

## 禁止事项

- ❌ 没有测试就实现功能
- ❌ 一次改多个关注点
- ❌ 在测试失败时继续
- ❌ 重构和加功能混合
- ❌ 跳过 /verify 直接声称完成
