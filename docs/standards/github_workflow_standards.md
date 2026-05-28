---
name: github-workflow-standards
description: GitHub工作流和分支管理规范
metadata: 
  node_type: memory
  type: reference
  originSessionId: 722bc612-8d9f-4032-b1be-353134450a76
---

# GitHub工作流规范

## 仓库配置

- **仓库类型**: 私密仓库 (Private)
- **主分支**: `main`（符合GitHub标准）
- **远程地址**: `https://github.com/YOUR_USERNAME/MuseFlow.git`

## 分支策略

### main分支
- 受保护分支
- 生产就绪代码
- 所有合并需经过Pull Request
- 需要至少1个审批

### 功能分支
- 命名格式: `feature/功能名称`
- `fix/问题描述`
- `docs/文档更新`
- `refactor/重构描述`

## 开发工作流

```
1. 从main创建功能分支
   git checkout -b feature/your-feature

2. 开发和提交
   git add .
   git commit -m "feat: description"

3. 推送到远程
   git push -u origin feature/your-feature

4. 创建Pull Request
   - 在GitHub上创建PR
   - 填写PR描述
   - 等待审查和批准

5. 合并到main
   - 审查通过后合并
   - 删除功能分支
```

## 验证检查清单

合并前必须确认：
- [ ] 代码编译通过
- [ ] 所有测试通过
- [ ] 新功能有测试覆盖
- [ ] 文档已更新
- [ ] Commit消息符合规范
- [ ] 代码审查通过

## 分支保护规则

**main分支规则**:
- Require pull request before merging
- Require approvals: 1
- Require status checks to pass
- Require branches to be up to date

## 紧急修复流程

仅用于关键紧急问题：
```bash
git checkout main
git pull origin main
# 修复...
git commit -m "fix: critical issue"
git push origin main
```
