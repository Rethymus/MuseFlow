# Repo Hygiene — 分支 / Tag / PR 规范

> 2026-09-06 仓库整理时建立。此前的混乱：本地残留 4 个过期 tag、19 个已关闭 PR 噪音、
> 合并后分支不删除、main 被 force-push 过（产生了 backup tag）。本文件定义规范，防止回潮。

## Tag 规范

- 只允许 `vX.Y.Z`（semver），且**创建 tag 的同时必须创建 GitHub Release**。
- 禁止里程碑 tag（如 `v1.3-phase16-complete`）和备份 tag（如 `backup/*`）。
- 版本线只沿一条 semver 单调递增，绝不重置、绝不倒退（历史上的 v1.0/v1.2 早于
  v0.1.x 就是版本线重置造成的混乱）。

## 分支规范

- `main` 是唯一长期分支，合并到 main 的代码必须 CI 全绿。
- 功能分支短生命周期：`feat/*`、`fix/*`、`chore/*`，用完即删。
- 仓库已开启 **merge 后自动删除分支**（`delete_branch_on_merge`），不需要手动清理。
- `main` 已开启分支保护：**禁止 force-push、禁止删除**（对管理员同样生效）。
  历史改写需求一律通过 revert，不走 force-push。

## PR 规范

- dependabot 已配置分组：pub 依赖的 minor/patch 合并为一个 PR，GitHub Actions
  全部版本合并为一个 PR；pub 的 **major 升级单独开 PR**，专门评估迁移成本。
- 跨大版本的依赖升级（如 openai_dart 6→8）必须单独开迁移分支，analyze/test/build
  全绿后再合入，不与例行维护混在一起。
- 过期（超 1 个月无进展）且 CI 失败的 PR 直接关闭并留说明；dependabot 会在新基线上
  重新提出。

## 清理日志（2026-09-06）

| 动作 | 明细 |
| --- | --- |
| 合并 PR | #20（actions/deploy-pages 4→5）、#21（actions/configure-pages 5→6），CI 全绿，squash 合并 |
| 关闭 PR | #24（ollama_dart 2.5.0，CI 失败且停滞 2 月）、#25（openai_dart 8.0.0 跨大版本，应走专门迁移 PR） |
| 删除本地残留 tag | 见下表（远端从未推送过这些 tag，无关联 Release） |
| 仓库设置 | 开启 `delete_branch_on_merge`；main 分支保护禁 force-push/删除 |
| dependabot | `.github/dependabot.yml` 增加更新分组 |

被删除 tag 的恢复方式：`git tag <name> <hash>`（哈希为 tag 所指提交）：

| Tag | 指向提交 |
| --- | --- |
| `v1.0` | `456cf259387a4e3e0411aa095484ff2eaa9782a5` |
| `v1.2` | `7830fd88527e45379bed51516429eb1237de42ce` |
| `v1.3-phase16-complete` | `a101ac59c948b34021957a3a09c9e183cead64ff` |
| `backup/pre-forcepush-e625243` | `e625243e73559af8f5967b1c956948f9fbc737a2` |

注意：前三个提交都是 main 历史的祖先，永久可恢复；`e625243` 不在 main 历史上，
仅在当地仓库 reflog 过期前可恢复。
