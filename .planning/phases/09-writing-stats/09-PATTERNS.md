# Phase 9 Patterns — Writing Stats

## Feature Layout

Use the existing feature-first layout:

```text
lib/features/stats/
  domain/
  application/
  infrastructure/
  presentation/
```

Tests mirror the same path under `test/features/stats/`.

## State And Providers

Follow `lib/core/presentation/providers.dart` patterns:

- Repositories are `FutureProvider<T>` when they open Hive boxes.
- Stateless services can be plain `Provider<T>`.
- UI-facing async state should use `AsyncNotifierProvider` when it performs refresh/mutation.

Provider names to standardize:

- `writingStatsRepositoryProvider`
- `writingStatsCollectorProvider`
- `writingStatsNotifierProvider`
- `achievementServiceProvider`
- `achievementNotifierProvider`

## Data Classes

Use immutable Dart classes with `copyWith`, matching current project style. Do not introduce generated code unless the surrounding feature already needs it.

Required methods on persisted domain classes:

- `toJson()`
- `factory fromJson(Map<String, dynamic> json)`
- `copyWith(...)`

## Counting Text

Implement a deterministic helper:

```dart
int countWritingUnits(String text)
```

Rules:

- Count each CJK character as 1 unit.
- Count contiguous ASCII/Latin letters or digits as 1 unit.
- Ignore whitespace and punctuation.
- Never return negative values.

## Debounced Persistence

Collector rules:

- Keep current session counters in memory.
- Flush no more often than every 30 seconds during active editing.
- Provide explicit `flush()` for editor dispose and tests.
- Never await Hive writes in the synchronous typing path.

## UI Style

Match current Material 3 app style:

- `Scaffold` + `ListView` or responsive `SingleChildScrollView`.
- Cards use `colorScheme.surfaceContainerLow` or standard `Card`.
- Empty states use calm Chinese copy, not error language.
- Desktop and mobile layouts must both work; avoid fixed wide chart sizes.

## Test Naming

Use focused test files:

- `test/features/stats/domain/writing_unit_counter_test.dart`
- `test/features/stats/infrastructure/writing_stats_repository_test.dart`
- `test/features/stats/application/writing_stats_collector_test.dart`
- `test/features/stats/presentation/writing_stats_page_test.dart`
- `test/features/stats/application/achievement_service_test.dart`
- `test/features/settings/presentation/settings_page_stats_test.dart`
