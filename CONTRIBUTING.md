# MuseFlow 贡献指南

感谢您对 MuseFlow 项目的关注！

## 开发流程

### 1. Fork 和克隆

```bash
# Fork 仓库到你的账号
git clone https://github.com/YOUR_USERNAME/MuseFlow.git
cd MuseFlow
git remote add upstream https://github.com/Rethymus/MuseFlow.git
```

### 2. 创建功能分支

```bash
git checkout -b feature/your-feature-name
# 或
git checkout -b fix/your-bug-fix
```

### 3. 开发和测试

```bash
# 安装依赖
flutter pub get

# 运行代码分析
flutter analyze

# 运行测试
flutter test

# 格式化代码
dart format .
```

### 4. 提交变更

遵循 [Commit 消息规范](docs/standards/commit_message_standards.md):

```bash
git add .
git commit -m "feat: add new feature description"
```

### 5. 推送和创建 Pull Request

```bash
git push origin feature/your-feature-name
```

然后在 GitHub 上创建 Pull Request。

## 代码规范

### Dart/Flutter 规范

- 遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart)
- 使用 `dart format` 格式化代码
- 通过 `flutter analyze` 无警告
- 为公共 API 添加文档注释

### 测试要求

- 新功能必须有测试覆盖
- 测试文件命名: `*_test.dart`
- 使用描述性的测试名称

### 文档要求

- 复杂功能需要文档说明
- 公共 API 需要使用文档注释
- 重大变更更新 CHANGELOG

## Pull Request 检查清单

提交 PR 前确认：

- [ ] 代码通过 `flutter analyze`
- [ ] 代码通过 `dart format`
- [ ] 所有测试通过 `flutter test`
- [ ] 新功能有测试覆盖
- [ ] 文档已更新
- [ ] Commit 消息符合规范
- [ ] PR 描述清晰说明变更内容

## CI/CD

项目使用 GitHub Actions 进行持续集成：

- 代码分析检查
- 单元测试执行
- Windows/Android 构建验证
- 安全扫描

## 行为准则

- 尊重所有贡献者
- 接受建设性反馈
- 关注对社区最有利的事情

## 获取帮助

- 查看 [文档](docs/)
- 搜索现有 [Issues](https://github.com/Rethymus/MuseFlow/issues)
- 创建新的 Issue 讨论

---

再次感谢您的贡献！
