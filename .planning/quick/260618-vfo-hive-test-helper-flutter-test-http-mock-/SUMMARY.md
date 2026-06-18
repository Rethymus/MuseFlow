---
quick_id: 260618-vfo
slug: hive-test-helper-flutter-test-http-mock-
date: 2026-06-18
status: complete
commit: c1dc778
files_changed:
  - test/helpers/hive_test_helper.dart (warn + new helper)
  - test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart (dogfood)
---

# 硬化 hive_test_helper 防 flutter_test HTTP-mock 陷阱

## 交付 / What

`test/helpers/hive_test_helper.dart`：
- `setUpHiveTest` 加醒目 ⚠ doc：本函数调 `ensureInitialized` → flutter_test 装
  `HttpOverrides.global` mock → 所有真实 HTTP 返 400 → 真实 network/API 测试禁用，
  改用 `setUpHiveForNetworkTest`。
- 新增 `setUpHiveForNetworkTest()`：直接 `Hive.init(explicitTempPath)`，**不**调
  ensureInitialized（显式 temp 路径不需 Flutter binding）。镜像 journey_container 真实 API 模式。
- `tearDownHiveTest()` 不变（close boxes + deleteFromDisk，两种 setUp 通用）。

`chapter_summary_refresh_service_real_glm_test.dart`：dogfood 新 helper（替换内联 Hive.init），
吃自己的狗粮，让该真实测试成为 helper 的活文档。

## 根因 / Why（260618-rlo 暴露）

`setUpHiveTest()` → `TestWidgetsFlutterBinding.ensureInitialized()` → flutter_test binding
安装 `HttpOverrides.global`，所有真实 HTTP 返 400（日志原文 "all HTTP requests will return
status code 400, and no network request"），静默拦截真实 API 调用、伪装成 provider 错误。
260618-rlo 因此多花 30min 诊断。journey_container 早已规避，但 hive_test_helper 无提示 →
下一个真实 API 测试作者必再踩。

## 验证 / Evidence

- `flutter analyze` 全仓 → No issues found (4.1s)
- `dart analyze` 两文件 → No issues found
- 真实 GLM 经新 helper dogfood → `+2 All tests passed!`（44字摘要 + 幂等）
- setUpHiveTest 用户零回归：chapter_summary_repository + editor_chapter_memory_context_builder
  + foreshadowing_repository（25 测试）→ All passed（纯新增+doc 不破坏既有）

## 闭合 / Closes

真实 API 测试陷阱永久可防：helper 内置警告 + 安全替代。后续任何 network/real-API 测试
作者在 `hive_test_helper.dart` 即可看到正确路径。
