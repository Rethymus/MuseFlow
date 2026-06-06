# Phase 12: Token Audit Infrastructure - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 15 (new + modified)
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/stats/domain/token_audit_record.dart` | model | CRUD | `lib/features/stats/domain/stats_snapshot.dart` | exact |
| `lib/features/stats/domain/audit_operation_type.dart` | model | transform | `lib/features/editor/domain/editor_ai_state.dart` (enum pattern) | role-match |
| `lib/features/stats/infrastructure/token_audit_repository.dart` | repository | CRUD | `lib/features/stats/infrastructure/writing_stats_repository.dart` | exact |
| `lib/features/stats/application/token_audit_service.dart` | service | event-driven | `lib/features/stats/application/writing_stats_collector.dart` | exact |
| `lib/features/stats/application/token_audit_notifier.dart` | notifier | request-response | `lib/features/stats/application/writing_stats_notifier.dart` | exact |
| `lib/features/stats/presentation/token_summary_card.dart` | component | request-response | `lib/features/stats/presentation/stats_summary_card.dart` | exact |
| `lib/features/stats/presentation/token_audit_page.dart` | component | request-response | `lib/features/stats/presentation/writing_stats_page.dart` | exact |
| `lib/features/stats/presentation/charts/operation_type_pie_chart.dart` | component | transform | `lib/features/stats/presentation/charts/ai_usage_pie_chart.dart` | exact |
| `lib/features/stats/presentation/charts/chapter_token_bar_chart.dart` | component | transform | `lib/features/stats/presentation/charts/daily_words_bar_chart.dart` | exact |
| `lib/features/ai/application/prompt_pipeline.dart` (modified) | middleware | transform | (itself) | self-mod |
| `lib/features/ai/infrastructure/openai_adapter.dart` (modified) | adapter | streaming | (itself) | self-mod |
| `lib/core/infrastructure/hive_adapters.dart` (modified) | config | CRUD | (itself) | self-mod |
| `lib/core/presentation/providers.dart` (modified) | config | request-response | (itself) | self-mod |
| `lib/shared/constants/app_constants.dart` (modified) | config | -- | (itself) | self-mod |
| `lib/app.dart` (modified) | route | request-response | (itself) | self-mod |

## Pattern Assignments

### `lib/features/stats/domain/token_audit_record.dart` (model, CRUD)

**Analog:** `lib/features/stats/domain/stats_snapshot.dart`

**Class pattern** (lines 3-83):
```dart
class StatsSnapshot {
  const StatsSnapshot({
    this.totalUnits = 0,
    this.humanUnits = 0,
    this.aiUnits = 0,
    this.writingDays = 0,
    this.sessionCount = 0,
    this.editSeconds = 0,
    this.daily = const [],
    this.projectStats = const {},
    this.currentProject,
  });

  // final fields...

  double get aiAssistRatio => totalUnits == 0 ? 0 : aiUnits / totalUnits;

  StatsSnapshot copyWith({
    int? totalUnits,
    // ... all fields as nullable params
  }) {
    return StatsSnapshot(
      totalUnits: totalUnits ?? this.totalUnits,
      // ...
    );
  }

  factory StatsSnapshot.fromJson(Map<String, dynamic> json) {
    // parse JSON
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUnits': totalUnits,
      // ... all fields
    };
  }
}
```

**Key conventions to follow:**
- `const` constructor with defaults for optional fields
- Immutable with `copyWith`
- `fromJson` factory + `toJson` method (no freezed for this entity per research)
- Store `AuditOperationType` as index in JSON: `operationTypeIndex: operationType.index`
- Parse back: `AuditOperationType.values[json['operationTypeIndex'] as int]`
- Store `timestamp` as ISO 8601 string: `timestamp.toIso8601String()`

---

### `lib/features/stats/domain/audit_operation_type.dart` (model, transform)

**Analog:** `lib/features/editor/domain/editor_ai_state.dart` (enum pattern from existing codebase)

**Enum with enhanced data pattern:**
```dart
// Follow enhanced enum pattern from Dart 3.5 with label fields
enum AuditOperationType {
  synthesis('碎片整理', 'organize'),
  rewrite('语气改写', 'edit'),
  polish('段落润色', 'edit'),
  freeInput('自由输入', 'edit'),
  skillGen('Skill生成', 'worldview'),
  opening('开篇生成', 'worldview'),
  deviationDetect('偏离检测', 'worldview'),
  templateComplete('模板补全', 'template');

  const AuditOperationType(this.label, this.group);

  final String label;
  final String group;
}
```

**Key conventions:**
- Enhanced enum with const constructor and final fields
- Chinese label for UI display
- Group string for the 4-group categorization per D-04

---

### `lib/features/stats/infrastructure/token_audit_repository.dart` (repository, CRUD)

**Analog:** `lib/features/stats/infrastructure/writing_stats_repository.dart`

**Repository constructor pattern** (lines 6-8):
```dart
class WritingStatsRepository {
  WritingStatsRepository(this._aggregateBox, this._dailyBox, [this._badgeBox]);

  static const globalKey = 'global';
  static const defaultProjectId = 'default';

  final Box<dynamic> _aggregateBox;
  final Box<dynamic> _dailyBox;
  final Box<dynamic>? _badgeBox;
```

**Box write pattern** (lines 121-134):
```dart
Future<void> _mergeAggregate(String key, {...}) async {
  final current = _readSnapshot(key);
  final totalHuman = current.humanUnits + humanUnits;
  await _aggregateBox.put(
    key,
    current.copyWith(...).toJson(),
  );
}
```

**Read pattern** (lines 105-109):
```dart
StatsSnapshot _readSnapshot(String key) {
  final value = _aggregateBox.get(key);
  if (value == null) return const StatsSnapshot();
  return StatsSnapshot.fromJson(Map<String, dynamic>.from(value as Map));
}
```

**Key conventions for TokenAuditRepository:**
- Constructor takes `Box<dynamic>` for the `token_audit` Hive box
- Save records: `_box.add(record.toJson())` or `_box.put(record.id, record.toJson())`
- Load records: iterate `_box.values`, parse each via `TokenAuditRecord.fromJson`
- Auto-cleanup: `enforceLimit(int maxRecords)` sorts by timestamp, deletes oldest
- No encryption needed for audit box (token counts are not sensitive)

---

### `lib/features/stats/application/token_audit_service.dart` (service, event-driven)

**Analog:** `lib/features/stats/application/writing_stats_collector.dart`

**Imports pattern** (lines 1-4):
```dart
import 'dart:async';

import 'package:museflow/features/stats/domain/writing_unit_counter.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';
```

**Debatched write pattern** (full file, lines 6-96):
```dart
class WritingStatsCollector {
  WritingStatsCollector(
    this._repository, {
    this.debounceDuration = const Duration(seconds: 30),
  });

  final WritingStatsRepository _repository;
  final Duration debounceDuration;

  Timer? _flushTimer;
  // ... pending state fields

  void recordTextSnapshot(String plainText, {...}) {
    // Update pending state
    _pendingHumanUnits += delta;
    _scheduleFlush();
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    // Copy pending, clear, then write
    final humanUnits = _pendingHumanUnits;
    final aiUnits = _pendingAiUnits;
    if (humanUnits == 0 && aiUnits == 0) return;

    _pendingHumanUnits = 0;
    _pendingAiUnits = 0;

    await _repository.recordSessionDelta(...);
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    unawaited(flush());
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(debounceDuration, () {
      unawaited(flush());
    });
  }
}
```

**Key conventions for TokenAuditService:**
- Same 30s debounce timer pattern
- `List<TokenAuditRecord> _pendingRecords` buffer
- `record(TokenAuditRecord)` adds to pending list and schedules flush
- `flush()` copies pending, clears, calls `_repository.saveAll(records)` then `_repository.enforceLimit(maxRecords)`
- `dispose()` cancels timer and flushes remaining records
- Fallback estimation: use `TokenBudgetCalculator.estimateTokens()` when API usage is null

---

### `lib/features/stats/application/token_audit_notifier.dart` (notifier, request-response)

**Analog:** `lib/features/stats/application/writing_stats_notifier.dart`

**Full AsyncNotifier pattern** (lines 1-23):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';

class WritingStatsNotifier extends AsyncNotifier<StatsSnapshot> {
  @override
  Future<StatsSnapshot> build() async {
    final repository = await ref.watch(writingStatsRepositoryProvider.future);
    return repository.loadSnapshot();
  }

  Future<void> refresh() async {
    final repository = await ref.read(writingStatsRepositoryProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.loadSnapshot);
  }

  Future<void> clearAll() async {
    final repository = await ref.read(writingStatsRepositoryProvider.future);
    await repository.clearAll();
    state = const AsyncData(StatsSnapshot());
  }
}
```

**Key conventions for TokenAuditNotifier:**
- Extends `AsyncNotifier<TokenAuditSnapshot>` (or equivalent state type)
- `build()` reads from repository provider and loads aggregated data
- `refresh()` uses `AsyncLoading` + `AsyncValue.guard` pattern
- Provider defined in `providers.dart` as `AsyncNotifierProvider`

---

### `lib/features/stats/presentation/token_summary_card.dart` (component, request-response)

**Analog:** `lib/features/stats/presentation/stats_summary_card.dart`

**Full card widget pattern** (lines 1-59):
```dart
import 'package:flutter/material.dart';

class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key conventions for TokenSummaryCard:**
- Reuse `StatsSummaryCard` directly for each metric (total input tokens, total output tokens, AI call count)
- Wrap in a tappable `InkWell` or `GestureDetector` for navigation to TokenAuditPage
- Place in `_SummaryWrap`-style layout with `LayoutBuilder` + `Wrap` for responsive grid

---

### `lib/features/stats/presentation/token_audit_page.dart` (component, request-response)

**Analog:** `lib/features/stats/presentation/writing_stats_page.dart`

**Page structure pattern** (lines 13-58):
```dart
class WritingStatsPage extends ConsumerWidget {
  const WritingStatsPage({super.key, this.debugSnapshot});

  final StatsSnapshot? debugSnapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... debug snapshot path if needed

    final statsAsync = ref.watch(writingStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('写作统计'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppConstants.statsProject),
            icon: const Icon(Icons.article_outlined),
            label: const Text('当前作品'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('统计加载失败：$error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(writingStatsNotifierProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (snapshot) => _StatsContent(snapshot: snapshot),
      ),
    );
  }
}
```

**Content layout pattern** (lines 61-103):
```dart
class _StatsContent extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('写作统计', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('把创作过程变成可感知的轨迹。', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        // Empty state
        if (snapshot.totalUnits == 0)
          const Card(child: Padding(..., child: Text('开始写作后，这里会出现你的创作轨迹。'))),
        _SummaryWrap(snapshot: snapshot),
        const SizedBox(height: 24),
        _ChartSection(title: '每日字数', child: DailyWordsBarChart(dailyStats: snapshot.daily)),
        _ChartSection(title: '速度趋势', child: SpeedTrendLineChart(dailyStats: snapshot.daily)),
        _ChartSection(title: 'AI 使用比例', child: AIUsagePieChart(...)),
      ],
    );
  }
}
```

**`_ChartSection` card pattern** (lines 162-184):
```dart
class _ChartSection extends StatelessWidget {
  const _ChartSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
```

**Key conventions for TokenAuditPage:**
- `ConsumerWidget` with `Scaffold` + `AppBar`
- `ref.watch(tokenAuditNotifierProvider)` with `.when(loading, error, data)`
- Error state shows message + retry button
- `_ChartSection`-style cards wrapping bar chart and pie chart
- Empty state card when no audit records exist

---

### `lib/features/stats/presentation/charts/operation_type_pie_chart.dart` (component, transform)

**Analog:** `lib/features/stats/presentation/charts/ai_usage_pie_chart.dart`

**Full pie chart pattern** (lines 1-49):
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AIUsagePieChart extends StatelessWidget {
  const AIUsagePieChart({
    super.key,
    required this.humanUnits,
    required this.aiUnits,
  });

  final int humanUnits;
  final int aiUnits;

  @override
  Widget build(BuildContext context) {
    final total = humanUnits + aiUnits;
    if (total == 0) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('还没有 AI 使用记录')),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 44,
          sections: [
            PieChartSectionData(
              value: humanUnits.toDouble(),
              color: colorScheme.primary,
              title: '手写',
              radius: 58,
            ),
            PieChartSectionData(
              value: aiUnits.toDouble(),
              color: colorScheme.tertiary,
              title: 'AI',
              radius: 58,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Key conventions for OperationTypePieChart:**
- Same `SizedBox(height: 220)` container
- Empty state: `SizedBox(height: 220, child: Center(child: Text('...')))`
- Use `colorScheme` for colors (different color per operation group)
- Group by `AuditOperationType.group` for 4 sections

---

### `lib/features/stats/presentation/charts/chapter_token_bar_chart.dart` (component, transform)

**Analog:** `lib/features/stats/presentation/charts/daily_words_bar_chart.dart`

**Full bar chart pattern** (lines 1-62):
```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:museflow/features/stats/domain/daily_writing_stats.dart';

class DailyWordsBarChart extends StatelessWidget {
  const DailyWordsBarChart({super.key, required this.dailyStats});

  final List<DailyWritingStats> dailyStats;

  @override
  Widget build(BuildContext context) {
    if (dailyStats.isEmpty) {
      return const _ChartEmptyState(text: '还没有每日字数记录');
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxY = dailyStats
        .map((day) => day.totalUnits)
        .fold<int>(0, (max, value) => value > max ? value : max)
        .toDouble();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (var i = 0; i < dailyStats.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailyStats[i].totalUnits.toDouble(),
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    width: 12,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
```

**Key conventions for ChapterTokenBarChart:**
- Same `SizedBox(height: 220)` container with `BarChart`
- Same `FlGridData(show: false)`, `FlBorderData(show: false)`, hidden top/right titles
- Map per-chapter aggregated token totals to `BarChartGroupData`
- Use `colorScheme.primary` for bar color
- Empty state handling

---

### `lib/features/ai/application/prompt_pipeline.dart` (modified)

**Analog:** (itself -- modification to add `auditContext` field)

**Current `PromptContext` fields** (lines 37-86):
```dart
class PromptContext {
  final List<Fragment> fragments;
  final String? additionalInstruction;
  final List<String> bannedPhrases;
  final List<ChatMessage> messages;
  final int tokenBudget;
  final String? selectedText;
  final List<AnchorReference>? anchors;
  final EditorAIOperation? selectedOperation;
  final String? userInstruction;
  final String? previousChapterSummary;
  final String? nextChapterSummary;

  const PromptContext({...});

  PromptContext addMessage(ChatMessage message) {
    return PromptContext(
      fragments: fragments,
      // ... all fields copied
      messages: [...messages, message],
    );
  }

  PromptContext withMessages(List<ChatMessage> newMessages) {
    return PromptContext(
      fragments: fragments,
      // ... all fields copied
      messages: newMessages,
    );
  }

  PromptContext replaceSystemMessage(int index, String newContent) {
    // ...
  }
}
```

**Modification needed:**
- Add `AuditContext? auditContext` field to `PromptContext`
- `AuditContext` is a simple class: `{ AuditOperationType operationType, String manuscriptId, String? chapterId }`
- Add to constructor, `addMessage`, `withMessages`, `replaceSystemMessage` copy-throughs
- No middleware changes -- audit context flows through the chain but is only consumed at the call site

---

### `lib/features/ai/infrastructure/openai_adapter.dart` (modified)

**Analog:** (itself -- modification to add `onUsage` callback)

**Current `createStream` method** (lines 40-72):
```dart
Stream<String> createStream({
  required String apiKey,
  required String baseUrl,
  required String model,
  required List<ChatMessage> messages,
  double? temperature,
  double? topP,
  int? maxTokens,
}) {
  _validateBaseUrl(baseUrl);
  final client = _getOrCreateClient(apiKey, baseUrl);
  final request = ChatCompletionCreateRequest(
    model: model,
    messages: messages,
    temperature: temperature,
    topP: topP,
    maxTokens: maxTokens,
  );

  return client.chat.completions.createStream(request).map((event) {
    final delta = event.textDelta;
    return delta ?? '';
  }).where((delta) => delta.isNotEmpty).handleError((error) {
    throw classifyException(error);
  });
}
```

**Modification needed:**
- Add optional parameter: `void Function(Usage?)? onUsage`
- Import `ChatStreamAccumulator` from `openai_dart`
- Wrap stream with accumulator: `final accumulator = ChatStreamAccumulator(); accumulator.add(event);`
- Add `StreamTransformer.fromHandlers(handleDone: ...)` to invoke `onUsage?.call(accumulator.usage)` on stream completion
- Return type stays `Stream<String>` -- no breaking change per D-01

---

### `lib/core/infrastructure/hive_adapters.dart` (modified)

**Analog:** (itself -- add `TokenAuditRecordAdapter` with typeId 10)

**Type ID registry pattern** (lines 14-26):
```dart
abstract class HiveTypeIds {
  static const int fragment = 0;
  static const int appSettings = 1;
  static const int manuscript = 2;
  static const int characterCard = 3;
  static const int worldSetting = 4;
  static const int skillDocument = 5;
  static const int foreshadowingEntry = 6;
  static const int plotNode = 7;
  static const int guardianAnnotation = 8;
  static const int chapter = 9;
}
```

**Manual adapter pattern** (lines 31-53):
```dart
class FragmentAdapter extends TypeAdapter<Fragment> {
  @override
  final int typeId = HiveTypeIds.fragment;

  @override
  Fragment read(BinaryReader reader) {
    final json = reader.readMap() as Map<String, dynamic>;
    return Fragment.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Fragment obj) {
    writer.writeMap(obj.toJson());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FragmentAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
```

**Modification needed:**
- Add `static const int tokenAuditRecord = 10;` to `HiveTypeIds`
- Add `TokenAuditRecordAdapter` following the exact same pattern: `read` -> `readMap` -> `fromJson`, `write` -> `writeMap` -> `toJson`
- Add `hashCode` and `operator ==` overrides
- Register in `main.dart`: `Hive.registerAdapter(TokenAuditRecordAdapter());`

---

### `lib/core/presentation/providers.dart` (modified)

**Analog:** (itself -- add token audit providers)

**Repository + collector provider pattern** (lines 451-467):
```dart
final writingStatsRepositoryProvider = FutureProvider<WritingStatsRepository>((
  ref,
) async {
  final aggregateBox = await Hive.openBox<dynamic>('writing_stats');
  final dailyBox = await Hive.openBox<dynamic>('daily_writing_stats');
  final badgeBox = await Hive.openBox<dynamic>('achievement_badges');
  return WritingStatsRepository(aggregateBox, dailyBox, badgeBox);
});

final writingStatsCollectorProvider = FutureProvider<WritingStatsCollector>((
  ref,
) async {
  final repository = await ref.watch(writingStatsRepositoryProvider.future);
  final collector = WritingStatsCollector(repository);
  ref.onDispose(collector.dispose);
  return collector;
});
```

**Notifier provider pattern** (lines 469-472):
```dart
final writingStatsNotifierProvider =
    AsyncNotifierProvider<WritingStatsNotifier, StatsSnapshot>(
      WritingStatsNotifier.new,
    );
```

**Modification needed -- add 3 providers:**
1. `tokenAuditRepositoryProvider` -- `FutureProvider` opening `Hive.openBox<dynamic>('token_audit')`
2. `tokenAuditServiceProvider` -- `FutureProvider` creating `TokenAuditService(repository)` with `ref.onDispose(service.dispose)`
3. `tokenAuditNotifierProvider` -- `AsyncNotifierProvider<TokenAuditNotifier, TokenAuditSnapshot>(TokenAuditNotifier.new)`

---

### `lib/shared/constants/app_constants.dart` (modified)

**Analog:** (itself -- add route constant)

**Route constant pattern** (lines 23-36):
```dart
static const String stats = '/stats';
static const String statsProject = '/stats/project';
```

**Modification needed:**
- Add: `static const String statsTokenAudit = '/stats/token-audit';`

---

### `lib/app.dart` (modified)

**Analog:** (itself -- add route for TokenAuditPage)

**Stats branch route pattern** (lines 175-186):
```dart
// Branch 4: Stats
StatefulShellBranch(
  routes: [
    GoRoute(
      path: AppConstants.stats,
      builder: (context, state) => const WritingStatsPage(),
      routes: [
        GoRoute(
          path: 'project',
          builder: (context, state) => const ProjectStatsPage(),
        ),
      ],
    ),
  ],
),
```

**Modification needed:**
- Add sub-route under `/stats`:
```dart
GoRoute(
  path: 'token-audit',
  builder: (context, state) => const TokenAuditPage(),
),
```

## Shared Patterns

### AsyncNotifier State Management
**Source:** `lib/features/stats/application/writing_stats_notifier.dart`
**Apply to:** `token_audit_notifier.dart`
```dart
class WritingStatsNotifier extends AsyncNotifier<StatsSnapshot> {
  @override
  Future<StatsSnapshot> build() async {
    final repository = await ref.watch(writingStatsRepositoryProvider.future);
    return repository.loadSnapshot();
  }

  Future<void> refresh() async {
    final repository = await ref.read(writingStatsRepositoryProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.loadSnapshot);
  }
}
```

### FutureProvider for Hive Box Opening
**Source:** `lib/core/presentation/providers.dart` (lines 82-87, 451-458)
**Apply to:** `tokenAuditRepositoryProvider`
```dart
final fragmentRepositoryProvider = FutureProvider<FragmentRepository>((ref) async {
  final box = await Hive.openBox<Fragment>('fragments');
  return FragmentRepository(box);
});
```

### Provider with Dispose
**Source:** `lib/core/presentation/providers.dart` (lines 460-467)
**Apply to:** `tokenAuditServiceProvider`
```dart
final writingStatsCollectorProvider = FutureProvider<WritingStatsCollector>((ref) async {
  final repository = await ref.watch(writingStatsRepositoryProvider.future);
  final collector = WritingStatsCollector(repository);
  ref.onDispose(collector.dispose);
  return collector;
});
```

### Hive Adapter Registration in main.dart
**Source:** `lib/main.dart` (lines 68-77)
**Apply to:** Register `TokenAuditRecordAdapter`
```dart
Hive.registerAdapter(FragmentAdapter());
// ... existing adapters ...
Hive.registerAdapter(ChapterAdapter());
// ADD: Hive.registerAdapter(TokenAuditRecordAdapter());
```

### Error Handling in Stream Consumers (AI Call Sites)
**Source:** `lib/features/ai/presentation/synthesis_notifier.dart` (lines 230-240)
**Apply to:** All 6 AI call sites when adding audit recording
```dart
} on AIException catch (e) {
  if (!ref.mounted) return;
  _handleStreamError(e);
} catch (e) {
  if (!ref.mounted) return;
  state = state.copyWith(
    isStreaming: false,
    isEditing: true,
    error: '生成中断，可继续编辑或重试',
  );
}
```

### ConsumerWidget AsyncState Rendering
**Source:** `lib/features/stats/presentation/writing_stats_page.dart` (lines 39-57)
**Apply to:** `token_audit_page.dart`
```dart
body: statsAsync.when(
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, _) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('统计加载失败：$error'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => ref.read(notifierProvider.notifier).refresh(),
          child: const Text('重试'),
        ),
      ],
    ),
  ),
  data: (snapshot) => _Content(data: snapshot),
),
```

## No Analog Found

All files have close analogs in the existing codebase. This phase reuses established patterns extensively:

| File | Closest Analog | Match Quality |
|------|----------------|---------------|
| (all files) | existing stats, AI, and infrastructure code | exact or role-match |

No files require novel patterns not already established in the codebase.

## Metadata

**Analog search scope:** `lib/features/stats/`, `lib/features/ai/`, `lib/core/`, `lib/app.dart`, `lib/main.dart`, `lib/shared/`
**Files scanned:** 15 analog files read
**Pattern extraction date:** 2026-06-06
