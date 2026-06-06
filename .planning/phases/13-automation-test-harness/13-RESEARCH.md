# Phase 13: Automation Test Harness - Research

**Researched:** 2026-06-07
**Domain:** Flutter integration testing, Dart standalone automation, fake adapter patterns
**Confidence:** HIGH

## Summary

Phase 13 构建自动化测试框架，用于在无真实 API 的情况下验证 MuseFlow 核心创作流程。研究覆盖三个关键领域：

1. **FakeAdapter 实现模式**：可复现的修仙题材内容生成器，替代真实 AI API 调用
2. **Dart standalone 自动化脚本**：无 UI 执行完整流程（创建文稿→100章→AI生成→导出）
3. **Flutter integration_test**：UI 层关键节点验证（文稿管理→章节 CRUD→编辑器→导出）

核心发现：MuseFlow 已有完善的 Riverpod 架构和 OpenAIAdapter 抽象层，支持通过 `ProviderContainer` + overrides 实现纯 Dart 测试。Phase 12 的 token audit 基础设施可直接验证 FakeAdapter 调用是否被正确记录。

**Primary recommendation:** 采用分层测试策略——底层用 Dart unit tests + ProviderContainer 验证业务逻辑，顶层用 integration_test 验证 UI 交互，FakeAdapter 同时服务两层。

// __CONTINUE_HERE__

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Manuscript CRUD | Application + Infrastructure | Domain | ManuscriptRepository 处理持久化，domain entities 定义不可变数据结构 |
| Chapter CRUD | Application + Infrastructure | Domain | ChapterRepository 管理 Hive 存储，Chapter 实体定义章节结构 |
| AI 内容生成 | Application (notifiers) | Infrastructure (adapters) | SynthesisNotifier/EditorAINotifier 编排流程，OpenAIAdapter/FakeAdapter 执行调用 |
| Token audit 记录 | Application (service) | Infrastructure (repository) | TokenAuditService 批量写入，TokenAuditRepository 持久化到 Hive |
| 导出功能 | Application (ExportService) | Domain (ExportBundle) | ExportService 构建内容，ExportBundle 定义数据结构 |
| 测试脚本编排 | Test layer (automation script) | — | 纯 Dart 脚本使用 ProviderContainer 直接调用 application 层 |
| UI 集成测试 | Test layer (integration_test) | Presentation | integration_test 驱动真实 Widget 树验证用户流程 |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **flutter_test** | SDK | Widget testing + unit tests | Flutter 官方测试框架，与 testWidgets() 集成 [VERIFIED: Flutter SDK] |
| **integration_test** | SDK | 端到端集成测试 | Flutter 官方 E2E 测试包，替代 flutter_driver [VERIFIED: Flutter SDK] |
| **test** | ^1.25.0 | Dart unit testing | Dart 标准测试框架，支持 group/setUp/tearDown [VERIFIED: pub.dev] |
| **flutter_riverpod** | ^3.3.1 | 状态管理（测试用） | 项目已使用，ProviderContainer 支持 overrides [VERIFIED: project pubspec.yaml] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **mockito** | ^5.4.4 | Mock 生成（可选） | 仅在需要验证方法调用次数时使用，本 phase 优先手写 Fake [CITED: docs.flutter.dev] |
| **hive_ce** | ^2.19.3 | 测试数据持久化 | 使用临时目录初始化 Hive，测试后清理 [VERIFIED: project pubspec.yaml] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written FakeAdapter | mockito + when/thenReturn | Mockito 需要 build_runner 生成代码，增加复杂度；手写 Fake 更简单清晰 [CITED: stackoverflow.com] |
| integration_test | flutter_driver | flutter_driver 已弃用，integration_test 是官方推荐替代 [CITED: docs.flutter.dev] |
| ProviderContainer in Dart | flutter_test testWidgets | ProviderContainer 允许纯 Dart 测试无需 Widget 树，执行更快 [CITED: riverpod.dev] |

**Installation:**
```bash
# 核心依赖已在 pubspec.yaml，无需新增
flutter pub get

# 可选：添加 mockito（本 phase 不强制使用）
# flutter pub add mockito --dev
# flutter pub add build_runner --dev
```

**Version verification:** 项目使用 Flutter 3.44.0 (Dart 3.12.0)，integration_test 和 flutter_test 随 SDK 发布，无需单独安装。


## Architecture Patterns

### System Architecture Diagram

```
[Dart Automation Script]
         |
         v
  ProviderContainer (overrides: FakeAdapter)
         |
         +---> ManuscriptRepository -> Hive (manuscripts box)
         +---> ChapterRepository -> Hive (chapters box)
         +---> TokenAuditService -> TokenAuditRepository -> Hive (token_audit box)
         +---> ExportService -> FileWriter (memory/disk)
         +---> SynthesisNotifier -> FakeAdapter.createStream()
         +---> EditorAINotifier -> FakeAdapter.createStream()

[Flutter Integration Test]
         |
         v
  IntegrationTestWidgetsFlutterBinding
         |
         +---> ProviderScope (overrides: FakeAdapter)
               |
               +---> ManuscriptLibraryPage (tester.tap, tester.pump)
               +---> ChapterListPage (scroll, CRUD operations)
               +---> EditorPage (super_editor interactions)
               +---> ExportDialog (file picker mock)
```

**Data flow tracing (100-chapter automation):**
1. Script creates Manuscript entity → ManuscriptRepository.save() → Hive write
2. Loop 100 times: create Chapter → ChapterRepository.save() → Hive write
3. For each chapter: call FakeAdapter.createStream() → yield fixed xianxia text → TokenAuditService.recordAudit()
4. ExportService.buildMarkdown() → read all chapters → sort by sortOrder → concatenate
5. Assertions: 100 chapters exist, token audit has 100 records, exported file contains expected structure

### Recommended Project Structure

```
test/
├── automation/                    # Dart standalone scripts
│   ├── core_flow_test.dart       # TEST-01: 完整流程脚本
│   ├── fixtures/                 # 测试数据
│   │   ├── xianxia_content.dart  # 修仙题材固定文本
│   │   └── manuscript_fixtures.dart
│   └── helpers/
│       ├── fake_adapter.dart     # FakeAdapter 实现
│       └── test_container.dart   # ProviderContainer 工厂
├── integration_test/              # Flutter UI 集成测试
│   ├── manuscript_flow_test.dart # TEST-02: UI 节点验证
│   ├── chapter_crud_test.dart
│   └── export_flow_test.dart
├── helpers/
│   └── hive_test_helper.dart     # 已存在，复用
└── features/                      # 现有 unit tests
```


### Pattern 1: FakeAdapter with Deterministic Responses

**What:** 实现 OpenAIAdapter 相同接口的 FakeAdapter，返回预定义的修仙题材文本流

**When to use:** 所有需要 AI 内容生成的测试场景（synthesis、editor rewrite、polish、free input）

**Example:**
```dart
// Source: 基于项目 OpenAIAdapter 接口设计
class FakeAdapter {
  final Map<String, List<String>> _responsesByOperation;
  int _callCount = 0;
  
  FakeAdapter({Map<String, List<String>>? responses})
      : _responsesByOperation = responses ?? _defaultXianxiaResponses;

  Stream<String> createStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<ChatMessage> messages,
    double? temperature,
    double? topP,
    int? maxTokens,
    void Function(Usage?)? onUsage,
  }) async* {
    // 根据 messages 内容判断操作类型
    final operationType = _detectOperationType(messages);
    final responses = _responsesByOperation[operationType] ?? ['默认修仙文本'];
    final response = responses[_callCount % responses.length];
    _callCount++;

    // 模拟流式返回（每次 yield 一个字符）
    for (int i = 0; i < response.length; i++) {
      await Future.delayed(Duration(milliseconds: 5)); // 模拟网络延迟
      yield response[i];
    }

    // 调用 onUsage callback 模拟 token 统计
    if (onUsage != null) {
      final usage = Usage(
        promptTokens: _estimateTokens(messages.map((m) => m.content).join()),
        completionTokens: _estimateTokens(response),
        totalTokens: 0, // 会被 Usage 类自动计算
      );
      onUsage(usage);
    }
  }

  String _detectOperationType(List<ChatMessage> messages) {
    final content = messages.map((m) => m.content).join(' ').toLowerCase();
    if (content.contains('碎片') || content.contains('整理')) return 'synthesis';
    if (content.contains('改写') || content.contains('语气')) return 'rewrite';
    if (content.contains('润色')) return 'polish';
    return 'freeInput';
  }

  int _estimateTokens(String text) {
    // 简化估算：中文 1 字 ≈ 2 tokens
    return text.replaceAll(RegExp(r'\s'), '').length * 2;
  }

  static final Map<String, List<String>> _defaultXianxiaResponses = {
    'synthesis': [
      '林风立于青云峰巅，剑气纵横三千里。今日筑基大成，他日必证金丹大道。',
      '破晓时分，灵气如潮涌入丹田。她缓缓睁眼，眸中闪过一道金光——练气九层，终于突破！',
      '古洞深处，一枚玉简静静悬浮。其上篆刻着"九霄剑诀"四字，散发出令人心悸的威压。',
    ],
    'rewrite': [
      '剑光一闪，血溅三尺。他面无表情地收剑入鞘，转身踏入风雪之中。',
      '灵力汇聚掌心，化作一道青色光柱直冲云霄。天地为之变色，雷云滚滚而来。',
    ],
    'polish': [
      '他深吸一口气，缓缓运转《玄天功》。丹田内灵力如江河奔涌，沿着经脉游走周天，最终汇聚于气海。',
      '月华如水，洒在剑身之上。她持剑而立，衣袂飘飘，宛若谪仙临尘。',
    ],
    'freeInput': [
      '此剑名为"斩仙"，乃上古仙人遗留之物。持之者可破万法，斩因果，逆天改命。',
    ],
  };
}
```


### Pattern 2: Dart Standalone Script with ProviderContainer

**What:** 纯 Dart 脚本使用 ProviderContainer + overrides 执行完整业务流程，无需 Flutter UI

**When to use:** 测试业务逻辑层（repositories、services、notifiers），验证数据流和副作用

**Example:**
```dart
// Source: 基于 Riverpod 官方测试文档 [CITED: riverpod.dev/docs/how_to/testing]
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  test('TEST-01: Core flow with FakeAdapter', () async {
    // 1. 初始化 Hive 到临时目录
    final tempDir = Directory.systemTemp.createTempSync('test_');
    Hive.init(tempDir.path);
    await Hive.openBox('manuscripts');
    await Hive.openBox('chapters');
    await Hive.openBox('token_audit');

    // 2. 创建 ProviderContainer 并 override openaiAdapterProvider
    final container = ProviderContainer(
      overrides: [
        openaiAdapterProvider.overrideWithValue(FakeAdapter()),
      ],
    );
    addTearDown(() {
      container.dispose();
      Hive.deleteFromDisk();
    });

    // 3. 创建文稿
    final manuscriptRepo = await container.read(manuscriptRepositoryProvider.future);
    final manuscript = Manuscript(
      id: 'test-ms-001',
      title: '剑道苍穹',
      genre: '修仙',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await manuscriptRepo.save(manuscript);

    // 4. 创建 100 章
    final chapterRepo = await container.read(chapterRepositoryProvider.future);
    for (int i = 1; i <= 100; i++) {
      final chapter = Chapter(
        id: 'chapter-$i',
        manuscriptId: manuscript.id,
        title: '第${i}章',
        sortOrder: i,
        documentContent: '', // 初始为空
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await chapterRepo.save(chapter);
    }

    // 5. 对每章调用 AI 生成内容（通过 FakeAdapter）
    final synthesisNotifier = container.read(synthesisProvider.notifier);
    for (int i = 1; i <= 100; i++) {
      // 模拟选中碎片并触发 synthesis
      // 这里需要设置 selectedFragmentsProvider 的值
      final fragments = [
        Fragment(
          id: 'frag-$i',
          text: '第 $i 章灵感：主角突破境界',
          createdAt: DateTime.now(),
        ),
      ];
      // 使用 container.read() 触发 synthesis
      // 实际实现需要等待流完成
    }

    // 6. 验证 token audit 记录
    final auditRepo = await container.read(tokenAuditRepositoryProvider.future);
    final auditRecords = await auditRepo.getAll();
    expect(auditRecords.length, 100, reason: 'Should have 100 audit records');

    // 7. 导出验证
    final exportService = await container.read(exportServiceProvider.future);
    final chapters = await chapterRepo.getAllByManuscript(manuscript.id);
    final bundle = ExportBundle(
      manuscriptText: '',
      chapters: chapters.map((c) => ChapterExport(
        title: c.title,
        sortOrder: c.sortOrder,
        content: c.documentContent,
      )).toList(),
      // ... 其他字段
    );
    final markdown = exportService.buildMarkdown(bundle);
    expect(markdown, contains('## 第1章'));
    expect(markdown, contains('## 第100章'));
  });
}
```


### Pattern 3: Flutter Integration Test with Widget Interactions

**What:** 使用 integration_test 包驱动真实 Widget 树，模拟用户操作验证 UI 流程

**When to use:** 验证 UI 层交互（按钮点击、列表滚动、对话框、路由导航）

**Example:**
```dart
// Source: Flutter 官方文档 [CITED: docs.flutter.dev/testing/integration-tests]
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:museflow/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('TEST-02: Manuscript and chapter flow', () {
    testWidgets('Create manuscript and 100 chapters', (tester) async {
      // 1. 启动应用，override FakeAdapter
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            openaiAdapterProvider.overrideWithValue(FakeAdapter()),
          ],
          child: app.MyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. 导航到文稿库页面
      final manuscriptLibraryButton = find.text('文稿库');
      expect(manuscriptLibraryButton, findsOneWidget);
      await tester.tap(manuscriptLibraryButton);
      await tester.pumpAndSettle();

      // 3. 创建新文稿
      final createButton = find.byIcon(Icons.add);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // 填写文稿信息
      await tester.enterText(find.byKey(Key('manuscript_title')), '剑道苍穹');
      await tester.enterText(find.byKey(Key('manuscript_genre')), '修仙');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      // 4. 进入章节列表页面
      final manuscriptCard = find.text('剑道苍穹');
      await tester.tap(manuscriptCard);
      await tester.pumpAndSettle();

      // 5. 批量创建 100 章（通过 UI 操作或直接调用 provider）
      for (int i = 1; i <= 100; i++) {
        await tester.tap(find.byKey(Key('add_chapter_button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(Key('chapter_title')), '第${i}章');
        await tester.tap(find.text('确认'));
        await tester.pumpAndSettle();
      }

      // 6. 验证章节列表
      await tester.scrollUntilVisible(
        find.text('第100章'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('第100章'), findsOneWidget);

      // 7. 测试 AI 生成功能
      await tester.tap(find.text('第1章'));
      await tester.pumpAndSettle();
      
      // 触发 AI 生成（通过编辑器工具栏）
      await tester.tap(find.byKey(Key('ai_synthesis_button')));
      await tester.pumpAndSettle();
      
      // 等待流式生成完成
      await tester.pump(Duration(seconds: 2));
      
      // 验证内容已插入
      expect(find.textContaining('林风'), findsWidgets);

      // 8. 测试导出功能
      await tester.tap(find.byKey(Key('export_button')));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Markdown'));
      await tester.tap(find.text('导出'));
      await tester.pumpAndSettle();
      
      // 验证导出成功（检查 SnackBar 或日志）
    });
  });
}
```

### Anti-Patterns to Avoid

- **反模式：在 integration_test 中直接操作 Repository**：Integration tests 应该通过 UI 交互验证流程，不要绕过 Widget 层直接调用业务逻辑
- **反模式：FakeAdapter 返回随机内容**：测试需要可复现，所有响应应该是确定性的（固定文本或基于输入的确定性算法）
- **反模式：100 章全部通过 UI 手动创建**：UI 测试应验证关键交互，批量数据准备可以通过 provider override 或直接调用 repository
- **反模式：不清理 Hive 数据**：每个测试应该独立运行，使用 `setUp`/`tearDown` 清理临时数据


## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mock HTTP 客户端 | 自定义 HTTP interceptor | FakeAdapter 实现接口 | OpenAIAdapter 已有清晰接口，直接实现 Fake 比拦截 HTTP 更简单 [CITED: moldstud.com] |
| Widget 查找逻辑 | 自定义递归遍历 Widget 树 | flutter_test 的 find.* 方法 | find.text()、find.byKey()、find.byType() 已覆盖 99% 场景 [VERIFIED: Flutter SDK docs] |
| 异步等待逻辑 | 手动 Future.delayed 轮询 | tester.pumpAndSettle() | pumpAndSettle() 自动等待所有动画和异步操作完成 [VERIFIED: Flutter SDK docs] |
| Token 估算算法 | 复杂的 tokenizer | 简化公式：中文 1 字 ≈ 2 tokens | 测试环境只需粗略估算，无需精确 tokenizer [ASSUMED] |
| 测试数据工厂 | Builder 模式 + 链式调用 | 简单 factory 函数 | Dart 的命名参数 + 默认值已足够表达，Builder 模式过度设计 [ASSUMED] |

**Key insight:** Flutter 和 Riverpod 的测试 API 已非常成熟，直接使用官方工具比自己造轮子更可靠。唯一需要手写的是 FakeAdapter（因为它是领域特定的）。

## Common Pitfalls

### Pitfall 1: ProviderContainer 未正确 dispose

**What goes wrong:** 测试结束后 ProviderContainer 未 dispose，导致 Hive boxes 未关闭，下一个测试启动时报错 "Box already open"

**Why it happens:** Riverpod 的 ProviderContainer 持有所有 provider 的状态，包括打开的 Hive boxes 和 StreamSubscription

**How to avoid:** 始终在 tearDown 或 addTearDown 中调用 `container.dispose()`

**Warning signs:**
```
HiveError: Box is already open
HiveError: Failed to open box
```

**Prevention strategy:**
```dart
test('example', () async {
  final container = ProviderContainer(overrides: [...]);
  addTearDown(container.dispose); // 关键：自动清理
  
  // 测试逻辑
});
```

### Pitfall 2: integration_test 中的异步时序问题

**What goes wrong:** 调用 `tester.tap()` 后立即断言，但 Widget 尚未重建，导致测试失败

**Why it happens:** Flutter 的 Widget 重建是异步的，`tap()` 只是排队一个事件，需要 `pump()` 或 `pumpAndSettle()` 触发帧渲染

**How to avoid:** 所有交互操作后必须调用 `await tester.pumpAndSettle()`

**Warning signs:**
```
Expected: finds one widget
Actual: finds zero widgets
```

**Prevention strategy:**
```dart
await tester.tap(find.text('按钮'));
await tester.pumpAndSettle(); // 关键：等待 UI 更新
expect(find.text('成功'), findsOneWidget);
```

### Pitfall 3: FakeAdapter 的 onUsage callback 未调用

**What goes wrong:** Token audit 记录为空，因为 FakeAdapter 忘记调用 `onUsage?.call(usage)`

**Why it happens:** OpenAIAdapter 在流结束时通过 StreamTransformer.handleDone 调用 onUsage，FakeAdapter 必须模拟相同行为

**How to avoid:** FakeAdapter.createStream() 在 yield 完所有 token 后，显式调用 onUsage

**Warning signs:** TokenAuditRepository.getAll() 返回空列表，但 AI 调用已执行

**Prevention strategy:**
```dart
Stream<String> createStream({..., void Function(Usage?)? onUsage}) async* {
  // yield tokens...
  
  // 关键：流结束前调用 onUsage
  if (onUsage != null) {
    onUsage(Usage(promptTokens: 100, completionTokens: 50, totalTokens: 150));
  }
}
```

### Pitfall 4: 100 章测试超时

**What goes wrong:** 创建 100 章 + 100 次 AI 调用导致测试超过默认 30 秒超时

**Why it happens:** 即使 FakeAdapter 很快，100 次循环 + Hive 写入仍需要时间

**How to avoid:** 为长时间测试设置更长的 timeout

**Warning signs:**
```
Test timed out after 30 seconds
```

**Prevention strategy:**
```dart
test('100-chapter flow', () async {
  // 测试逻辑
}, timeout: Timeout(Duration(minutes: 5))); // 关键：延长超时
```


## Code Examples

验证的代码模式来自官方文档和项目现有实现。

### Example 1: Hive 测试环境初始化

```dart
// Source: 项目现有 test/helpers/hive_test_helper.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

Future<void> setUpHiveTest() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tempDir = Directory.systemTemp.createTempSync('hive_test_');
  Hive.init(tempDir.path);
}

Future<void> tearDownHiveTest() async {
  await Hive.deleteFromDisk();
}

// 使用示例
void main() {
  setUp(setUpHiveTest);
  tearDown(tearDownHiveTest);
  
  test('example', () async {
    await Hive.openBox('manuscripts');
    // 测试逻辑
  });
}
```

### Example 2: ProviderContainer Override Pattern

```dart
// Source: Riverpod 官方文档 [CITED: riverpod.dev/docs/how_to/testing]
final container = ProviderContainer(
  overrides: [
    // Override adapter with fake
    openaiAdapterProvider.overrideWithValue(FakeAdapter()),
    
    // Override API key provider
    activeApiKeyProvider.overrideWithValue('fake-key-for-testing'),
    
    // Override any async provider with immediate value
    activeProviderProvider.overrideWithValue(
      AIProvider(
        id: 'test-provider',
        name: 'Test Provider',
        baseUrl: 'https://fake.api',
        type: AiProviderType.openai,
        model: 'gpt-test',
        createdAt: DateTime.now(),
      ),
    ),
  ],
);
```

### Example 3: 修仙题材测试数据 Fixture

```dart
// Source: 手写示例，基于修仙小说常见情节
class XianxiaFixtures {
  static const List<String> chapterTitles = [
    '第一章 废材少年',
    '第二章 意外传承',
    '第三章 初入修仙',
    '第四章 练气筑基',
    '第五章 宗门试炼',
    // ... 至第 100 章
  ];

  static const List<String> synthesisFragments = [
    '主角在悬崖边缘发现一枚古老玉简',
    '玉简中记载着失传已久的《九霄剑诀》',
    '修炼过程中遇到瓶颈，需要突破',
    '突破时引发天地异象，引来敌对势力',
  ];

  static String generateChapterContent(int chapterNumber) {
    if (chapterNumber <= 10) {
      return '林风在青云宗修炼已有三载。今日他终于突破练气${chapterNumber}层，距离筑基又近一步。';
    } else if (chapterNumber <= 50) {
      return '历经数月闭关，林风成功凝聚金丹。金丹品质达到中品，在同辈中已是佼佼者。';
    } else {
      return '元婴雷劫降临，九道天雷接连轰下。林风咬牙坚持，最终渡劫成功，晋升元婴真人。';
    }
  }

  static Fragment createFragment(String text, {int index = 0}) {
    return Fragment(
      id: 'frag-$index',
      text: text,
      tags: ['修仙', '筑基'],
      createdAt: DateTime.now().subtract(Duration(hours: index)),
    );
  }

  static Manuscript createManuscript({String? id, String? title}) {
    return Manuscript(
      id: id ?? 'ms-test-001',
      title: title ?? '剑道苍穹',
      genre: '修仙',
      targetWordCount: 100000,
      status: '写作中',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static Chapter createChapter({
    required String manuscriptId,
    required int chapterNumber,
    String? content,
  }) {
    return Chapter(
      id: 'ch-$chapterNumber',
      manuscriptId: manuscriptId,
      title: chapterTitles[chapterNumber - 1],
      sortOrder: chapterNumber,
      status: '草稿',
      documentContent: content ?? generateChapterContent(chapterNumber),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

### Example 4: Token Audit 验证断言

```dart
// Source: 基于 Phase 12 TokenAuditRepository 接口
test('verify token audit records', () async {
  final container = ProviderContainer(overrides: [
    openaiAdapterProvider.overrideWithValue(FakeAdapter()),
  ]);
  addTearDown(container.dispose);

  // 执行 AI 调用
  final synthesisNotifier = container.read(synthesisProvider.notifier);
  // ... 触发 synthesis

  // 等待异步完成
  await Future.delayed(Duration(milliseconds: 500));

  // 验证 token audit
  final auditRepo = await container.read(tokenAuditRepositoryProvider.future);
  final records = await auditRepo.getAll();

  expect(records.length, 1, reason: 'Should have 1 audit record');
  
  final record = records.first;
  expect(record.operationType, AuditOperationType.synthesis);
  expect(record.modelName, 'gpt-test');
  expect(record.inputTokens, greaterThan(0));
  expect(record.outputTokens, greaterThan(0));
  expect(record.totalTokens, record.inputTokens + record.outputTokens);
});
```

### Example 5: Export 格式验证

```dart
// Source: 基于项目 ExportService 实现
test('verify markdown export format', () async {
  final exportService = ExportService(
    fileWriter: (path, content) async {
      // 内存中记录导出内容，不写磁盘
      _exportedContent = content;
    },
  );

  final chapters = [
    ChapterExport(title: '第一章 废材少年', sortOrder: 1, content: '林风是青云宗的废材弟子...'),
    ChapterExport(title: '第二章 意外传承', sortOrder: 2, content: '悬崖边，林风发现一枚玉简...'),
  ];

  final bundle = ExportBundle(
    manuscriptText: '',
    chapters: chapters,
    // ... 其他字段
  );

  final markdown = exportService.buildMarkdown(bundle);

  // 验证格式
  expect(markdown, contains('## 第一章 废材少年'));
  expect(markdown, contains('## 第二章 意外传承'));
  expect(markdown, contains('林风是青云宗的废材弟子'));
  expect(markdown, contains('悬崖边，林风发现一枚玉简'));
  
  // 验证章节顺序
  final firstChapterIndex = markdown.indexOf('## 第一章');
  final secondChapterIndex = markdown.indexOf('## 第二章');
  expect(firstChapterIndex, lessThan(secondChapterIndex), 
         reason: 'Chapters should be in correct order');
}
```


## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| flutter_driver | integration_test | Flutter 2.8+ (2021) | integration_test 使用 flutter_test API，更简单且与 widget tests 一致 [CITED: docs.flutter.dev] |
| mockito 手动 when/thenReturn | Hand-written Fakes | 2020+ | Fake 实现更直观，无需 build_runner，适合简单场景 [CITED: stackoverflow.com] |
| ProviderScope 全局 main() | ProviderContainer 测试 | Riverpod 1.0+ (2021) | ProviderContainer 支持 overrides，测试更隔离 [CITED: riverpod.dev] |
| 测试中使用真实 API | Fake/Mock adapters | 持续最佳实践 | 测试更快、更可靠、不依赖网络 [ASSUMED] |

**Deprecated/outdated:**
- **flutter_driver**: 已弃用，官方推荐迁移到 integration_test [CITED: docs.flutter.dev/release/breaking-changes/flutter-driver-migration]
- **Provider (package:provider)**: Riverpod 的前身，已被项目替换为 flutter_riverpod
- **Hive (原版)**: 项目使用 hive_ce (Community Edition)，原版 2.2.3 已停止更新

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK) + integration_test (Flutter SDK) |
| Config file | 无需配置文件 — 标准 test/ 和 integration_test/ 目录结构 |
| Quick run command | `flutter test test/automation/core_flow_test.dart` |
| Full suite command | `flutter test && flutter test integration_test/` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | Dart 脚本创建文稿→100章→AI生成→导出 | Dart unit test | `flutter test test/automation/core_flow_test.dart -x` | ❌ Wave 0 |
| TEST-02 | Flutter UI 文稿创建→章节管理→AI生成→编辑→导出 | Integration test | `flutter test integration_test/manuscript_flow_test.dart` | ❌ Wave 0 |
| TEST-03 | FakeAdapter 返回可复现修仙文本 | Unit test | `flutter test test/automation/helpers/fake_adapter_test.dart -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/automation/ -x` (快速验证 Dart 脚本逻辑)
- **Per wave merge:** `flutter test` (全量 unit tests，不含 integration_test)
- **Phase gate:** `flutter test && flutter test integration_test/` (全量测试包括 UI)

### Wave 0 Gaps

- [ ] `test/automation/core_flow_test.dart` — 覆盖 TEST-01（完整 Dart 自动化脚本）
- [ ] `test/automation/helpers/fake_adapter.dart` — FakeAdapter 实现
- [ ] `test/automation/helpers/fake_adapter_test.dart` — 覆盖 TEST-03（FakeAdapter 单元测试）
- [ ] `test/automation/fixtures/xianxia_content.dart` — 修仙题材测试数据
- [ ] `integration_test/manuscript_flow_test.dart` — 覆盖 TEST-02（UI 集成测试）


## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | 测试环境不涉及真实认证 |
| V3 Session Management | no | 无会话管理 |
| V4 Access Control | no | 无权限控制 |
| V5 Input Validation | yes | 验证 FakeAdapter 输入参数（apiKey、model、messages 不为空） |
| V6 Cryptography | no | 测试环境使用 fake API key，无真实加密需求 |

### Known Threat Patterns for Flutter Testing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| 测试泄露真实 API Key | Information Disclosure | 硬编码使用 'fake-key-for-testing'，永不使用环境变量中的真实 key [ASSUMED] |
| 测试数据污染生产 Hive | Tampering | 使用临时目录 `Directory.systemTemp.createTempSync()`，测试后 `Hive.deleteFromDisk()` [VERIFIED: 项目现有代码] |
| FakeAdapter 模拟不完整导致假阳性 | Spoofing | FakeAdapter 必须调用 onUsage callback，否则 token audit 测试会漏掉真实场景的 bug [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- [Riverpod 官方测试文档](https://riverpod.dev/docs/how_to/testing) - ProviderContainer overrides 模式
- [Flutter integration_test 文档](https://docs.flutter.dev/testing/integration-tests) - IntegrationTestWidgetsFlutterBinding 使用
- [Context7 / Riverpod](https://github.com/rrousselgit/riverpod/blob/master/website/docs/how_to/testing.mdx) - Provider mocking 代码示例
- 项目现有代码：
  - `lib/features/ai/infrastructure/openai_adapter.dart` - createStream 接口定义
  - `lib/features/stats/domain/token_audit_record.dart` - Token audit 数据结构
  - `test/helpers/hive_test_helper.dart` - Hive 测试环境初始化

### Secondary (MEDIUM confidence)

- [Flutter 测试指南](https://docs.flutter.dev/cookbook/testing/widget/scrolling) - scrollUntilVisible 处理大列表
- [Flutter Driver 迁移指南](https://docs.flutter.dev/release/breaking-changes/flutter-driver-migration) - 确认 flutter_driver 已弃用

### Tertiary (LOW confidence)

- [Medium: Unit Testing Flutter Code with Mockito](https://blog.logrocket.com/unit-testing-flutter-code-mockito/) - Mockito vs Fake 对比
- [Stack Overflow: Riverpod Stream Provider Testing](https://stackoverflow.com/questions/76560554/riverpod-stream-provider-testing-in-pure-dart) - 纯 Dart 环境测试 provider

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Flutter SDK 内置工具，项目已使用 Riverpod
- Architecture: HIGH - 基于项目现有架构和官方文档
- Pitfalls: HIGH - 来自官方文档和常见测试反模式

**Research date:** 2026-06-07
**Valid until:** 60 天（Flutter 稳定版本周期约 3 个月）

