---
name: run-museflow
description: Launch MuseFlow Flutter app (Windows desktop primary, Android secondary) — install, codegen, run, and verify recipe for /run and /verify
disable-model-invocation: true
---

# Run MuseFlow 灵韵

Flutter 人机协作小说创作工具。Windows 桌面为主目标，Android 次之。本 recipe 供 `/run` 与 `/verify` 复用，免去每次重新摸索启动方式。

## Prerequisites
- Flutter 3.44.0 (stable) / Dart ^3.12.0 — SDK 在 `/home/re/flutter/bin`
- Windows 桌面构建: 需 Windows host + Visual Studio C++ build tools
- Android: Android SDK + 模拟器或真机 (`flutter devices` 查看)
- 本地补丁 `third_party/super_keyboard` (compileSdk 36 兼容), `flutter pub get` 自动经 `dependency_overrides` 处理
- 若当前 shell 找不到 `flutter` 或 `dart`, 先执行:
  !`export PATH="/home/re/flutter/bin:$PATH"`

## Install (clean environment)
!`flutter pub get`

## Code generation (必需 — riverpod_generator + freezed + json_serializable)
!`dart run build_runner build --delete-conflicting-outputs`
- 开发期 watch: `dart run build_runner watch -d`

## Launch
Windows 桌面 (主目标):
!`flutter run -d windows`

Android:
!`flutter run -d <device-id>`

## Verify launched
- 窗口/应用启动, 首屏 < 3 秒 (CLAUDE.md 性能目标)
- Hive 初始化成功 (本地存储 hive_ce + flutter_secure_storage)
- 富文本编辑器 (super_editor) 可输入
- `flutter analyze` 零错误

## Notes
- WSL2 内无法实跑 Windows 桌面 (需 Windows host display)。在 Windows PowerShell 跑 `/run-skill-generator` 可将本骨架精炼为实跑验证版。
- 普通配置仅存本地 Hive；API key 仅通过 flutter_secure_storage 保存，不写入 Hive，无需环境变量。
- 编辑器栈: CLAUDE.md 与 pubspec.yaml 均以 `super_editor ^0.3.0-dev.20` 为准 (Phase 0 benchmark 胜出方)。
