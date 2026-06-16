---
phase: quick-260616-hd9
plan: 01
subsystem: knowledge/presentation
tags: [mc-01, knowledge-base, staleness, ui-wiring, presentation, widget-test]
requires:
  - 260614-mc1 (KbStalenessChecker + lastVerifiedChapter field on CharacterCard/WorldSetting)
  - lib/core/presentation/providers.dart (chapterNotifierProvider, characterCardNotifierProvider, worldSettingNotifierProvider)
provides:
  - "_CharacterCardTile / _WorldSettingTile staleness 徽章 + 标记为已验证 PopupMenu 动作"
  - "_StalenessBadge 纯展示组件（fresh 隐藏，stale amber，veryStale red）"
affects:
  - 知识库列表项 UI 视觉（trailing IconButton → PopupMenuButton，subtitle Column 化）
tech-stack:
  added: []
  patterns:
    - "ConsumerWidget + ref.watch(.select) 细粒度读取 chapterCount"
    - "PopupMenuButton<String> 统一多动作（标记为已验证 + 删除）"
    - "private widget 通过入口页间接 widget test（find.byIcon/textContaining）"
key-files:
  created:
    - test/features/knowledge/knowledge_base_page_staleness_test.dart
  modified:
    - lib/features/knowledge/presentation/knowledge_base_page.dart
decisions:
  - "PopupMenuButton vs 两个 IconButton：选 PopupMenuButton，避免 trailing 视觉拥挤，删除项红色警示保留"
  - "Fake notifier 用具体类子类化（extends CharacterCardNotifier / WorldSettingNotifier / ChapterNotifier），仅 override build + save，无需 implements 抽象接口"
  - "私有 tile 测试改用 KnowledgeBasePage 入口 + initialTab 参数切到世界观 tab"
  - "List<Override> 类型在测试文件不可直接引用（Override 与 dart override 关键字冲突），改为 inline ProviderScope.overrides list 字面量由 Dart 推断"
metrics:
  duration: ~8min
  completed: 2026-06-16
  tasks_completed: 2
  files_changed: 2
  tests_added: 7
  tests_total: 1618 passed / 12 skipped (基线 1611/12)
requirements:
  - MC-01-UI
---

# Phase quick-260616-hd9 Plan 01: MC-01 知识库陈旧度 UI wiring Summary

将已交付的 MC-01 `KbStalenessChecker` 接入知识库管理页 — `_CharacterCardTile` / `_WorldSettingTile` 在 stale/veryStale 状态下显示中文 amber/red 徽章，并提供「标记为已验证」PopupMenu 动作，形成「检测 → 提醒 → 作者校准 → 重新保鲜」的闭环。

## What Changed

### `lib/features/knowledge/presentation/knowledge_base_page.dart`（546 行，+235 / -14）

- **新增 import**：`package:museflow/features/knowledge/application/kb_staleness_checker.dart`
- **新增私有 widget `_StalenessBadge`**（StatelessWidget）：
  - `fresh` → `SizedBox.shrink()`（不渲染）
  - `stale` → amber 背景（`Colors.amber.withValues(alpha: 0.12)`）+ `Icons.warning_amber_rounded` + `Colors.amber[700]` 文案
  - `veryStale` → `errorContainer` 背景（alpha 0.3）+ `Icons.error_outline` + `colorScheme.error` 文案
  - 单行 ellipsis
- **`_CharacterCardTile.build` 改造**：
  - 新增 `ref.watch(chapterNotifierProvider.select((async) => async.asData?.value.length ?? 0))`
  - 计算 `staleness = const KbStalenessChecker().check(card.lastVerifiedChapter, chapterCount)`
  - `subtitle` 从 `Text` 改为 `Column`（原 personality 文本 + fresh 态隐藏的 `_StalenessBadge`）
  - `trailing` 从 delete `IconButton` 改为 `PopupMenuButton<String>`（「标记为已验证」+「删除」两项，删除红色 `colorScheme.error`）
  - 保留 `onTap` 路由 `/knowledge/character/${card.id}`
- **`_CharacterCardTile._confirmVerify(BuildContext, WidgetRef, int chapterCount)`** 新增：
  - 弹 `AlertDialog` 标题「标记为已验证」内容含 `"${card.name}"` 和 `$chapterCount 章`，按钮「取消」+「确认」
  - 确认时 `ref.read(characterCardNotifierProvider.notifier).save(card.copyWith(lastVerifiedChapter: chapterCount))`
- **`_WorldSettingTile`** 完全对称改造（notifier 用 `worldSettingNotifierProvider`，路由 `/knowledge/setting/${id}`，文案用 `setting.name` / `setting.description`）
- 未改 `KnowledgeBasePage`、`_CharacterCardList` / `_WorldSettingList` 结构、搜索逻辑、empty state、FAB

### `test/features/knowledge/knowledge_base_page_staleness_test.dart`（新建，297 行）

7 个测试，3 个 group：

| Group | Test | 期望 |
|-------|------|------|
| `_CharacterCardTile staleness` | legacy null + chapterCount=5 | 无 warning / 无 error 徽章 |
| `_CharacterCardTile staleness` | lastVerifiedChapter=2 + chapterCount=15 → since=13 | amber warning + `13 章未验证` |
| `_CharacterCardTile staleness` | lastVerifiedChapter=2 + chapterCount=25 → since=23 | red error + `严重过期` |
| `_WorldSettingTile staleness` | lastVerifiedChapter=3 + chapterCount=18 → since=15 | amber warning + `15 章未验证` |
| `_WorldSettingTile staleness` | lastVerifiedChapter=5 + chapterCount=30 → since=25 | red error + `严重过期` |
| `mark-as-verified action` | 角色 tap more_vert → 「标记为已验证」→ 确认 | `savedCard.lastVerifiedChapter == 15` |
| `mark-as-verified action` | 世界观对称 | `savedSetting.lastVerifiedChapter == 18` |

辅助类：`_FixedChapterNotifier` / `_FakeCharacterCardNotifier` / `_FakeWorldSettingNotifier`（用具体类子类化，仅 override `build` + `save`）。

## Chapter 构造签名校正（vs PLAN 假设）

PLAN 中假设 `Chapter(id, manuscriptId, orderIndex, title, content, createdAt)`，实际 domain 是：

```dart
const Chapter({
  required this.id,
  required this.manuscriptId,
  required this.title,
  required this.sortOrder,        // 不是 orderIndex
  this.status = '草稿',
  this.documentContent = '',      // 不是 content
  required this.createdAt,
  required this.updatedAt,        // 也是 required，const 构造
});
```

校正：`_FixedChapterNotifier.build` 用 `Chapter(id: 'c$i', manuscriptId: 'm1', title: '第${i+1}章', sortOrder: i, createdAt: now, updatedAt: now)`。

## Decisions Made

1. **PopupMenuButton 而非两个 IconButton**：trailing 视觉空间有限，PopupMenu 收纳「标记为已验证」+「删除」更整洁，删除项仍保留 `colorScheme.error` 警示色。
2. **Fake notifier 用 extends 而非 implements**：`CharacterCardNotifier` / `WorldSettingNotifier` / `ChapterNotifier` 都是具体类（非抽象接口），子类化只 override 需要的方法即可，避免 implements 时被强制实现所有抽象成员。
3. **私有 tile 间接测试**：`_CharacterCardTile` / `_WorldSettingTile` / `_StalenessBadge` 均私有，测试通过 `KnowledgeBasePage` 入口 + `initialTab` 切到世界观 tab 间接断言。
4. **`List<Override>` 类型不可用**：Dart 关键字 `override` 与类型 `Override` 大小写本应不冲突，但实际 analyzer 报 `Override isn't a type`。改为 inline `ProviderScope.overrides: [...]` list 字面量由 Dart 推断（写 `final characterNotifier = fake ?? _Fake();` 在外）。

## Verification Outputs

### `flutter analyze lib/features/knowledge/presentation/knowledge_base_page.dart`
```
Analyzing knowledge_base_page.dart...
No issues found! (ran in 2.4s)
```

### `flutter analyze test/features/knowledge/knowledge_base_page_staleness_test.dart`
```
Analyzing knowledge_base_page_staleness_test.dart...
No issues found! (ran in 1.1s)
```

### `flutter test test/features/knowledge/knowledge_base_page_staleness_test.dart`
```
00:00 +1: _CharacterCardTile staleness should show no staleness badge when legacy lastVerifiedChapter is null
00:00 +2: _CharacterCardTile staleness should show amber badge with stale message when since is 13 chapters
00:00 +3: _CharacterCardTile staleness should show red badge with 严重过期 message when since is 23 chapters
00:01 +4: _WorldSettingTile staleness should show amber badge when world setting is stale
00:01 +5: _WorldSettingTile staleness should show red badge when world setting is very stale
00:01 +6: mark-as-verified action should call CharacterCardNotifier.save with current chapterCount when user confirms
00:01 +7: mark-as-verified action should call WorldSettingNotifier.save with current chapterCount when user confirms
00:01 +7: All tests passed!
```

### `flutter test test/features/knowledge/`（回归）
```
00:07 +219: All tests passed!
```

### `git diff --name-only HEAD~2 HEAD`（红线）
```
lib/features/knowledge/presentation/knowledge_base_page.dart
test/features/knowledge/knowledge_base_page_staleness_test.dart
```
仅 2 个目标文件，**未触及** `kb_staleness_checker.dart` / `character_card.dart` / `world_setting.dart` / `providers.dart` / 任何 notifier `save` 方法。

### 全量 `flutter test`
```
01:56 +1618 ~12: All tests passed!
```
（基线 1611 passed / 12 skipped → 1618 passed / 12 skipped，新增 +7 widget 测试，零回归）

## Deviations from Plan

None - plan 执行与 PLAN.md 描述一致。唯一调整是 Chapter 构造签名按实际 domain 字段填充（PLAN 中假定的字段名 `orderIndex/content` 与实际 `sortOrder/documentContent` 不一致，已在 plan 校正项中预期）。

## Known Stubs

None。wiring 是真实端到端：用户操作 → 确认 → `save(copyWith(...))` → notifier 触发 invalidateSelf → 重新 fresh 渲染。无任何 mock/placeholder。

## Threat Flags

None。无新增网络端点、无认证路径、无新依赖。STRIDE 分析见 PLAN `<threat_model>` 全部 accept/mitigate 落地（`chapterNotifierProvider` watch 用 `.asData?.value.length ?? 0` 优雅降级，T-mc01-ui-03 已 mitigate）。

## 后续 wiring 待办（提示 STATE.md Next step）

- **CI-01 act→prompt 模板适配**：260614-ci1 已交付 `DialogueActClassifier` 纯逻辑，下一步是把识别结果 wire 到响应策略选择。
- **AA-04 编辑器高亮**：260614-aa4 已交付 `SentenceAiScentAnalyzer`，下一步是在编辑器把 worst 句子高亮（视觉与 Phase 19 整体 detector 正交）。
- **MC-02 章节摘要自动刷新**：需要新建摘要 domain（不在本计划范围）。

## Self-Check: PASSED

- [x] `lib/features/knowledge/presentation/knowledge_base_page.dart` 存在（546 行 < 800）
- [x] `test/features/knowledge/knowledge_base_page_staleness_test.dart` 存在（297 行）
- [x] commit `27b401a` (Task 1 wiring) 存在
- [x] commit `643406a` (Task 2 测试) 存在
- [x] analyze 0 issue / 0 warning（两文件）
- [x] dart format 已应用
- [x] 全量 1618 passed / 12 skipped，零回归
- [x] 红线确认：仅 2 个目标文件变更
