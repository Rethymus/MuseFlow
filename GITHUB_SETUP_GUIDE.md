# MuseFlow GitHub 仓库设置指南

## 📋 当前状态

✅ Git仓库已初始化
✅ 主分支已重命名为 `main`
✅ `.gitignore` 已配置
✅ 初始commit已创建 (b1ed313)
✅ 260个文件已提交

---

## 🚀 创建GitHub私密仓库

### 步骤1: 在GitHub上创建仓库

1. 访问 https://github.com/new
2. 配置仓库：
   - **Repository name**: `MuseFlow`
   - **Description**: `AI-powered intelligent writing assistant with knowledge management`
   - **Visibility**: ✅ **Private** (私密仓库)
   - **不要**勾选:
     - ❌ Add a README file
     - ❌ Add .gitignore
     - ❌ Choose a license
3. 点击 **Create repository**

### 步骤2: 推送到GitHub

创建仓库后，GitHub会显示推送命令。使用以下命令：

```bash
# 添加远程仓库 (替换 YOUR_USERNAME 为你的GitHub用户名)
git remote add origin https://github.com/YOUR_USERNAME/MuseFlow.git

# 推送到GitHub
git push -u origin main
```

或者使用SSH（推荐）：
```bash
git remote add origin git@github.com:YOUR_USERNAME/MuseFlow.git
git push -u origin main
```

---

## 📝 Commit消息规范

遵循 [GitHub官方指南](https://docs.github.com/en/get-started/using-git/committing-changes-to-your-project)：

### 格式要求

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type类型

- `feat`: 新功能
- `fix`: 修复bug
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关

### 示例

```bash
# 简单修复
git commit -m "fix: resolve memory leak in cache manager"

# 新功能
git commit -m "feat(ai): add contextual AI service for document analysis"

# 详细描述（多行）
git commit -m "feat(knowledge): implement knowledge graph engine

Add automatic relationship discovery between entities:
- Character-to-character relationships
- Character-to-world relationships
- Visualization data generation
- Smart recommendation system

Closes #123"
```

### 关键原则

1. **使用祈使句**: "Fix bug" 而非 "Fixed bug" 或 "Fixes bug"
2. **首行简短**: 不超过50字符
3. **空行分隔**: 标题和正文之间空一行
4. **解释what和why**: 不需要解释how

---

## 🔄 后续开发流程

### 开发工作流

```bash
# 1. 创建新分支进行开发
git checkout -b feature/your-feature-name

# 2. 进行开发和修改
# ... 编辑文件 ...

# 3. 查看修改状态
git status

# 4. 添加修改的文件
git add .

# 5. 提交修改（遵循commit规范）
git commit -m "feat: description of your changes"

# 6. 推送到远程
git push -u origin feature/your-feature-name

# 7. 在GitHub上创建Pull Request
# 8. 经过验证后合并到main分支
```

### 验证检查清单

在合并到main分支前，确保：

- [ ] 代码编译通过
- [ ] 所有测试通过
- [ ] 新功能有测试覆盖
- [ ] 文档已更新
- [ ] Commit消息符合规范
- [ ] 代码审查通过

### 直接推送到main（紧急修复）

```bash
# 仅用于紧急修复
git checkout main
git pull origin main
# ... 进行修复 ...
git add .
git commit -m "fix: critical issue description"
git push origin main
```

---

## 🛡️ 分支保护规则

建议在GitHub仓库设置中配置：

### Settings → Branches → Add rule

**分支名称模式**: `main`

**启用规则**:
- ✅ Require a pull request before merging
  - Require approvals: 1
- ✅ Require status checks to pass before merging
  - 根据需要添加CI检查
- ✅ Require branches to be up to date before merging

---

## 📊 仓库结构

```
MuseFlow/
├── .git/                   # Git版本控制
├── .gitignore             # Git忽略配置
├── android/               # Android原生代码
├── lib/                   # Flutter/Dart源代码
│   ├── config/           # 配置文件
│   ├── features/         # 功能模块
│   ├── models/           # 数据模型
│   ├── pages/            # 页面
│   ├── services/         # 业务服务
│   ├── utils/            # 工具类
│   └── widgets/          # UI组件
├── test/                  # 测试文件
├── docs/                  # 项目文档
├── windows/               # Windows原生代码
├── pubspec.yaml          # Flutter依赖配置
└── README.md             # 项目说明
```

---

## 🔐 安全提醒

1. **私密仓库**: 确保仓库设置为Private
2. **敏感信息**: 检查commit中不包含:
   - API密钥
   - 密码
   - 个人信息
3. **依赖安全**: 定期运行 `flutter pub upgrade` 更新依赖

---

## 📞 快速命令参考

```bash
# 查看状态
git status

# 查看commit历史
git log --oneline

# 创建分支
git checkout -b branch-name

# 切换分支
git checkout branch-name

# 合并分支
git merge branch-name

# 撤销本地修改
git checkout -- file

# 查看远程
git remote -v

# 拉取最新代码
git pull origin main

# 查看分支
git branch -a
```

---

## ✅ 下一步

1. 在GitHub上创建私密仓库
2. 运行推送命令
3. 验证仓库内容
4. 设置分支保护规则
5. 开始使用规范的工作流开发

---

**创建时间**: 2026年5月28日
**Git版本**: 2.x
**主分支**: main
**初始commit**: b1ed313
