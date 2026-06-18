---
quick_id: 260618-vfo
slug: hive-test-helper-flutter-test-http-mock-
date: 2026-06-18
status: complete
type: test-infrastructure-hardening
---

# 硬化 hive_test_helper 防 flutter_test HTTP-mock 陷阱

## 背景 / Why

260618-rlo 暴露并根因定位了一个**可复现的测试陷阱**：`hive_test_helper.dart` 的 `setUpHiveTest()`
调 `TestWidgetsFlutterBinding.ensureInitialized()`，flutter_test 的 binding 随即安装
`HttpOverrides.global` 拦截**所有**真实 HTTP 返回 400（日志原文 "all HTTP requests will
return status code 400, and no network request"）。任何真实 API/network 测试若误用
`setUpHiveTest`，会被静默拦截、伪装成 provider 错误，诊断极耗时（本次 30min）。

journey_container.dart 早已规避（仅 local test key 才 ensureInitialized），但 `hive_test_helper`
无任何提示——下一个写真实 API 测试的人会再次踩坑。

## 方案 / Approach

`test/helpers/hive_test_helper.dart`：
1. `setUpHiveTest` 加醒目 ⚠ doc 警告：本函数调 ensureInitialized → 装 HTTP mock → 真实
   network/API 测试禁用，改用 `setUpHiveForNetworkTest`。
2. 新增 `setUpHiveForNetworkTest()`：直接 `Hive.init(explicitTempPath)`，**不**调
   ensureInitialized（显式 temp 路径不需 Flutter binding）。镜像 journey_container 真实 API 模式。
3. `tearDownHiveTest()` 不变（close boxes + deleteFromDisk，两种 setUp 通用）。

## Dogfood / 验证

260618-rlo 的 `chapter_summary_refresh_service_real_glm_test.dart` 当前内联了正确模式——
重构改用 `setUpHiveForNetworkTest()` + `tearDownHiveTest()`，吃自己的狗粮。真实 GLM 下仍须 GREEN
（既验证 helper 正确，又让该测试成为 helper 的活文档）。

## 文件 / Files

- 改: `test/helpers/hive_test_helper.dart`（警告 + 新 helper）
- 改: `test/features/manuscript/application/chapter_summary_refresh_service_real_glm_test.dart`（dogfood）

## 验证 / Verification

- `dart analyze` 两文件 → 0
- `flutter test chapter_summary_refresh_service_real_glm_test.dart`（GLM_API_KEY 注入）→ T1+T2 GREEN
- `flutter test test/helpers/` 或既有用 setUpHiveTest 的测试 → 零回归（helper 改动是纯新增+doc）
- 全仓 `flutter analyze` → 0

## 成功标准 / Done

- 新 helper 可用，MC-02 真实测试 dogfood GREEN
- setUpHiveTest 警告到位
- analyze 0 + 零回归
