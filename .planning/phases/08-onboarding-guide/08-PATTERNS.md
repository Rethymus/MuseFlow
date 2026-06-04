# Phase 08: Onboarding Guide - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 15 new/modified files
**Analogs found:** 14 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/onboarding/domain/opening_variant.dart` | model | transform | `lib/features/templates/domain/world_template.dart` (OpeningSample class) | exact |
| `lib/features/onboarding/application/opening_generator_service.dart` | service | request-response | `lib/features/templates/application/template_completion_service.dart` | exact |
| `lib/features/onboarding/application/onboarding_progress.dart` | utility | CRUD | `lib/core/infrastructure/settings_repository.dart` | role-match |
| `lib/features/onboarding/application/onboarding_notifier.dart` | provider | event-driven | `lib/features/knowledge/presentation/skill_generation_wizard.dart` (step state) | role-match |
| `lib/features/onboarding/presentation/onboarding_wizard_page.dart` | component | event-driven | `lib/features/knowledge/presentation/skill_generation_wizard.dart` | role-match |
| `lib/features/onboarding/presentation/wizard_steps/genre_step_page.dart` | component | request-response | `lib/features/templates/presentation/template_gallery_page.dart` | exact |
| `lib/features/onboarding/presentation/wizard_steps/world_step_page.dart` | component | CRUD | `lib/features/knowledge/presentation/world_setting_form.dart` | exact |
| `lib/features/onboarding/presentation/wizard_steps/character_step_page.dart` | component | CRUD | `lib/features/knowledge/presentation/character_card_form.dart` | exact |
| `lib/features/onboarding/presentation/wizard_steps/opening_step_page.dart` | component | request-response | `lib/features/knowledge/presentation/skill_generation_wizard.dart` (AI step) | role-match |
| `lib/features/onboarding/presentation/opening_generator_sheet.dart` | component | request-response | `lib/features/knowledge/presentation/quick_insert_dialog.dart` | role-match |
| `lib/features/onboarding/presentation/opening_variant_card.dart` | component | transform | `lib/features/templates/presentation/template_gallery_page.dart` (_TemplateCard) | role-match |
| `lib/app.dart` (modified) | config | request-response | existing file, add redirect + route | exact |
| `lib/shared/constants/app_constants.dart` (modified) | config | transform | existing file, add route constant | exact |
| `lib/features/editor/presentation/editor_toolbar.dart` (modified) | component | request-response | existing file, add toolbar button | exact |
| `lib/core/presentation/providers.dart` (modified) | provider | transform | existing file, add providers | exact |

## Pattern Assignments

### `lib/features/onboarding/domain/opening_variant.dart` (model, transform)

**Analog:** `lib/features/templates/domain/world_template.dart` -- `OpeningSample` class (lines 267-279)

**Imports pattern:**
```dart
// No external imports needed -- pure Dart value object
```

**Core pattern** (from `world_template.dart` lines 267-279):
```dart
class OpeningSample {
  const OpeningSample({required this.style, required this.text});

  final OpeningSampleStyle style;
  final String text;

  factory OpeningSample.fromJson(Map<String, dynamic> json) {
    return OpeningSample(
      style: OpeningSampleStyle.fromString(json['style'] as String),
      text: json['text'] as String,
    );
  }
}
```

The new `OpeningVariant` should follow this exact shape but may add a `label` getter for display ("场景切入" / "人物切入" / "悬念切入"). Reuse the existing `OpeningSampleStyle` enum (lines 21-39) which already has scene/character/suspense values.

**Enum reuse** (from `world_template.dart` lines 21-39):
```dart
enum OpeningSampleStyle {
  scene('scene'),
  character('character'),
  suspense('suspense');

  const OpeningSampleStyle(this.value);

  final String value;
  // ...
}
```

---

### `lib/features/onboarding/application/opening_generator_service.dart` (service, request-response)

**Analog:** `lib/features/templates/application/template_completion_service.dart`

**Imports pattern** (lines 1-5):
```dart
import 'dart:convert';

import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:openai_dart/openai_dart.dart';
```

**Core pattern -- streaming + JSON decode** (lines 37-66):
```dart
Future<TemplateCompletionResult> completeBlankFields(
  TemplateDraft draft,
) async {
  try {
    final messages = _buildMessages(draft);
    final stream =
        completionStream?.call(messages) ??
        openAIAdapter!.createStream(
          apiKey: apiKey!,
          baseUrl: baseUrl!,
          model: model!,
          messages: messages,
        );
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
    }
    final decoded = jsonDecode(buffer.toString()) as Map<String, dynamic>;
    return TemplateCompletionResult(
      draft: _applyCompletion(draft, decoded),
      succeeded: true,
    );
  } catch (error) {
    return TemplateCompletionResult(
      draft: draft,
      succeeded: false,
      errorMessage: error.toString(),
    );
  }
}
```

**Constructor pattern** (lines 23-29):
```dart
class TemplateCompletionService {
  TemplateCompletionService({
    this.openAIAdapter,
    this.apiKey,
    this.baseUrl,
    this.model,
    this.completionStream,
  });

  final OpenAIAdapter? openAIAdapter;
  final String? apiKey;
  final String? baseUrl;
  final String? model;
  final TemplateCompletionStream? completionStream;
```

The new service should mirror this: same constructor shape (adapter + apiKey + baseUrl + model + test-only stream override), same try/catch with result object, same streaming pattern. The key difference is the prompt builds a user message with world/character/concept instead of a draft, and the result parses 3 opening variants from JSON.

**System prompt pattern** (lines 68-71):
```dart
List<ChatMessage> _buildMessages(TemplateDraft draft) {
  return [
    ChatMessage.system(
      '你是 MuseFlow 模板补全助手。只返回严格 JSON，不要返回 Markdown。...'
    ),
    ChatMessage.user(
      jsonEncode({...}),
    ),
  ];
}
```

---

### `lib/features/onboarding/application/onboarding_progress.dart` (utility, CRUD)

**Analog:** `lib/core/infrastructure/settings_repository.dart`

**Core pattern -- Hive box key-value read/write** (lines 19-25, 48-56):
```dart
// Read with default
Size? getWindowSize() {
  final data = _box.get(_windowSizeKey);
  if (data == null) return null;
  return Size(data['width'] as double, data['height'] as double);
}

// Write
Future<void> saveWindowSize(Size size) async {
  await _box.put(_windowSizeKey, {
    'width': size.width,
    'height': size.height,
  });
}
```

**SettingsRepository constructor** (lines 9-14):
```dart
class SettingsRepository {
  final Box<dynamic> _box;

  // Key constants
  static const String _windowSizeKey = 'windowSize';
  static const String _windowPositionKey = 'windowPosition';

  SettingsRepository(this._box);
```

The onboarding progress class should take the settings `Box<dynamic>` and read/write a JSON map under an `onboarding_progress` key. Also add `onboarding_completed` boolean read/write. Follow the same `_box.get` / `_box.put` pattern.

---

### `lib/features/onboarding/application/onboarding_notifier.dart` (provider, event-driven)

**Analog:** `lib/features/knowledge/presentation/skill_generation_wizard.dart` -- step state management

The wizard manages step index, form data, and AI generation state. Rather than a Riverpod AsyncNotifier, the onboarding wizard state is best managed locally in the `ConsumerStatefulWidget` (like the skill wizard manages `_step` and generation state). The notifier should wrap `OnboardingProgress` persistence.

**Provider registration pattern** (from `providers.dart` lines 334-337):
```dart
final skillGenerationNotifierProvider =
    AsyncNotifierProvider<SkillGenerationNotifier, SkillGenerationState>(
      SkillGenerationNotifier.new,
    );
```

The onboarding notifier should follow the same `AsyncNotifierProvider` pattern if it manages async operations (AI generation), or a simple `NotifierProvider` if it only manages progress state.

---

### `lib/features/onboarding/presentation/onboarding_wizard_page.dart` (component, event-driven)

**Analog:** `lib/features/knowledge/presentation/skill_generation_wizard.dart`

**Core pattern -- multi-step wizard with state** (lines 13-16, 26-87):
```dart
class _SkillGenerationWizardState extends ConsumerState<SkillGenerationWizard> {
  final _nameController = TextEditingController();
  final _conceptController = TextEditingController();
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(skillGenerationNotifierProvider);
    final generated = generation.asData?.value.document;

    return Scaffold(
      appBar: AppBar(title: const Text('创建世界观模板')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () => _continue(generated != null),
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
```

The onboarding wizard replaces `Stepper` with `PageView` but follows the same state management pattern: `_step` index, `TextEditingController` instances, step advancement logic, AI generation triggering.

**Key difference:** Use `PageController` + `PageView` instead of `Stepper`. Use `AutomaticKeepAliveClientMixin` on step pages to preserve state across swipes.

---

### `lib/features/onboarding/presentation/wizard_steps/genre_step_page.dart` (component, request-response)

**Analog:** `lib/features/templates/presentation/template_gallery_page.dart`

**Core pattern -- template card grid** (lines 144-205):
```dart
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template});

  final WorldTemplate template;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconFor(template.iconName))),
        title: Text(template.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              template.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _PassiveTag(
                  label: template.channel == TemplateChannel.male ? '男频' : '女频',
                ),
                const _PassiveTag(label: '内置已审核'),
                for (final tag in template.tags) _PassiveTag(label: tag),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () =>
            context.go('${AppConstants.knowledgeTemplates}/${template.id}'),
      ),
    );
  }
```

**Tag widget** (lines 207-225):
```dart
class _PassiveTag extends StatelessWidget {
  const _PassiveTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}
```

**Icon mapping** (lines 187-204):
```dart
IconData _iconFor(String iconName) {
  return switch (iconName) {
    'filter_vintage' => Icons.filter_vintage,
    'location_city' => Icons.location_city,
    // ...
    _ => Icons.auto_awesome,
  };
}
```

The genre step reuses `WorldTemplateRepository.getAll()` for data and the `_TemplateCard` / `_PassiveTag` pattern for display, but uses a `GridView` (3 columns) instead of `ListView`. Selection state (border highlight) is new.

---

### `lib/features/onboarding/presentation/wizard_steps/world_step_page.dart` (component, CRUD)

**Analog:** `lib/features/knowledge/presentation/world_setting_form.dart`

**Core pattern -- form with controllers and save** (lines 20-29, 43-57, 88-200):
```dart
class _WorldSettingFormState extends ConsumerState<WorldSettingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  // ... more controllers
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    // ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedFromExisting();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    // ...
    super.dispose();
  }
```

**Text field pattern** (lines 98-115):
```dart
TextFormField(
  controller: _nameController,
  decoration: const InputDecoration(
    labelText: '名称 *',
    hintText: '世界观名称',
    border: OutlineInputBorder(),
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入世界观名称';
    }
    if (value.trim().length > 100) {
      return '名称不能超过100个字符';
    }
    return null;
  },
  maxLength: 100,
),
```

**Save pattern** (lines 210-270):
```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSaving = true);
  try {
    // ... create entity, save via notifier
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('世界观已创建')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

The world step page should be a simplified subset: only `name` and `description` fields (not all 7 fields from the full form). No separate Scaffold -- embedded in the wizard's step content area.

---

### `lib/features/onboarding/presentation/wizard_steps/character_step_page.dart` (component, CRUD)

**Analog:** `lib/features/knowledge/presentation/character_card_form.dart`

**Core pattern** -- same as world_setting_form.dart above but for CharacterCard fields. The character step uses `name` and optionally `personality`/`backstory` fields.

**CharacterCard construction** (lines 203-211):
```dart
final card = CharacterCard(
  id: '',
  name: _nameController.text.trim(),
  personality: _personalityController.text.trim(),
  appearance: _appearanceController.text.trim(),
  backstory: _backstoryController.text.trim(),
  aliases: aliases,
  createdAt: DateTime.now(),
);
await notifier.add(card);
```

---

### `lib/features/onboarding/presentation/wizard_steps/opening_step_page.dart` (component, request-response)

**Analog:** `lib/features/knowledge/presentation/skill_generation_wizard.dart` -- AI generation step (lines 68-76)

**AI generation + loading/error pattern:**
```dart
Step(
  title: const Text('AI 生成'),
  isActive: _step == 1,
  content: generation.when(
    loading: () => const LinearProgressIndicator(),
    error: (error, _) => Text('生成失败: $error'),
    data: (state) => SelectableText(
      state.progressText.isEmpty ? '点击下一步开始生成。' : state.progressText,
    ),
  ),
),
```

The opening step shows: optional concept TextField, generate button, loading indicator, error + retry, and 3 variant cards on success. The `generation.when(loading/error/data)` pattern from `AsyncValue` should be used.

---

### `lib/features/onboarding/presentation/opening_generator_sheet.dart` (component, request-response)

**Analog:** `lib/features/knowledge/presentation/quick_insert_dialog.dart`

**Core pattern -- overlay that reads editor and inserts text** (lines 1-14, 128-148):
```dart
class QuickInsertDialog extends ConsumerStatefulWidget {
  const QuickInsertDialog({super.key});

  @override
  ConsumerState<QuickInsertDialog> createState() => _QuickInsertDialogState();
}

// Insert pattern:
void _insert(KnowledgeEntity entity) {
  final editor = ref.read(editorProvider);
  final selection = editor?.composer.selection;
  if (editor == null || selection == null) {
    Navigator.of(context).pop();
    return;
  }

  final position = selection.extent;
  if (!selection.isCollapsed) {
    editor.execute([DeleteContentRequest(documentRange: selection)]);
  }
  editor.execute([
    InsertTextRequest(
      documentPosition: position,
      textToInsert: entity.displayName,
      attributions: {},
    ),
  ]);
  Navigator.of(context).pop();
}
```

The bottom sheet follows the same pattern: read `editorProvider`, get selection, execute `InsertTextRequest` on selection, close sheet. Uses `showModalBottomSheet` instead of `showDialog`.

**Editor provider access** (from `editor_page.dart` lines 44-60):
```dart
class EditorHolderNotifier extends Notifier<Editor?> {
  @override
  Editor? build() => null;

  void setEditor(Editor? editor) => state = editor;
}

final editorProvider = NotifierProvider<EditorHolderNotifier, Editor?>(
  EditorHolderNotifier.new,
);
```

---

### `lib/features/onboarding/presentation/opening_variant_card.dart` (component, transform)

**Analog:** `lib/features/templates/presentation/template_gallery_page.dart` -- `_TemplateCard` + `_PassiveTag`

**Card pattern** (from template_gallery_page.dart lines 150-185):
```dart
Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: ListTile(
    leading: CircleAvatar(child: Icon(_iconFor(template.iconName))),
    title: Text(template.displayTitle),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(template.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _PassiveTag(label: '场景切入'),
          ],
        ),
      ],
    ),
  ),
)
```

The variant card uses a similar Card layout but replaces ListTile with a custom Column: style badge at top (pill tag from `_PassiveTag` pattern), text preview in body (max 4 lines), "使用此开篇" button at bottom. Selected state changes border color.

---

### `lib/app.dart` (modified -- add redirect + onboarding route)

**Analog:** existing `lib/app.dart`

**Current router pattern** (lines 41-166):
```dart
GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppConstants.editor,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          // ... existing branches
        ],
      ),
    ],
  );
}
```

**Modification:** Add `redirect` callback and a top-level `GoRoute(path: '/onboarding')` as a sibling to `StatefulShellRoute.indexedStack`:

```dart
GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppConstants.editor,
    redirect: _handleRedirect,  // NEW
    routes: [
      GoRoute(  // NEW: outside StatefulShellRoute
        path: '/onboarding',
        builder: (context, state) => const OnboardingWizardPage(),
      ),
      StatefulShellRoute.indexedStack(
        // ... existing branches unchanged
      ),
    ],
  );
}
```

The redirect callback reads from the settings box:
```dart
FutureOr<String?> _handleRedirect(BuildContext context, GoRouterState state) {
  final isOnboarding = state.matchedLocation == '/onboarding';
  // Read via SettingsRepository or directly from Hive.box('settings')
  final completed = ... ; // read onboarding_completed
  if (!completed && !isOnboarding) return '/onboarding';
  if (completed && isOnboarding) return AppConstants.editor;
  return null;
}
```

---

### `lib/shared/constants/app_constants.dart` (modified -- add route constant)

**Analog:** existing file

**Current pattern** (lines 22-34):
```dart
// --- Route paths ---
static const String capture = '/capture';
static const String editor = '/editor';
static const String settings = '/settings';
```

**Add:**
```dart
static const String onboarding = '/onboarding';
```

---

### `lib/features/editor/presentation/editor_toolbar.dart` (modified -- add opening button)

**Analog:** existing toolbar button pattern

**Button pattern** (lines 31-37):
```dart
_FormatToggleButton(
  icon: Icons.format_bold,
  tooltip: '加粗 (Ctrl+B)',
  isActive: _isBoldActive(),
  onPressed: _toggleBold,
),
```

**Add after list buttons, before the closing of the Row's children:**
```dart
const SizedBox(width: 4),
SizedBox(
  height: 24,
  child: VerticalDivider(color: colorScheme.outline),
),
const SizedBox(width: 4),
_FormatToggleButton(
  icon: Icons.auto_stories,
  tooltip: '开篇生成',
  isActive: false,
  onPressed: () => _showOpeningGenerator(context),
),
```

The `_showOpeningGenerator` method calls `showModalBottomSheet(isScrollControlled: true)`.

---

### `lib/core/presentation/providers.dart` (modified -- add onboarding providers)

**Analog:** existing provider registration pattern

**AI service provider pattern** (lines 384-397):
```dart
final templateCompletionServiceProvider =
    FutureProvider<TemplateCompletionService>((ref) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  return TemplateCompletionService(
    openAIAdapter: ref.watch(openaiAdapterProvider),
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});
```

**Add similar providers for:**
- `openingGeneratorServiceProvider` -- same pattern as `templateCompletionServiceProvider`
- `onboardingProgressProvider` -- reads from `settingsRepositoryProvider`

---

## Shared Patterns

### AI Service Construction
**Source:** `lib/core/presentation/providers.dart` lines 384-397
**Apply to:** `openingGeneratorServiceProvider`

```dart
final openingGeneratorServiceProvider =
    FutureProvider<OpeningGeneratorService>((ref) async {
  final provider = ref.watch(activeProviderProvider);
  final apiKey = ref.watch(activeApiKeyProvider);
  if (provider == null || apiKey == null || apiKey.isEmpty) {
    throw StateError('未配置可用的 AI 模型');
  }
  return OpeningGeneratorService(
    openAIAdapter: ref.watch(openaiAdapterProvider),
    apiKey: apiKey,
    baseUrl: provider.baseUrl,
    model: provider.model,
  );
});
```

### Editor Text Insertion
**Source:** `lib/features/knowledge/presentation/quick_insert_dialog.dart` lines 128-148
**Apply to:** `opening_generator_sheet.dart`, `opening_step_page.dart` (wizard completion)

```dart
void _insertText(Editor editor, String text) {
  final selection = editor.composer.selection;
  if (selection == null) return;

  final position = selection.extent;
  if (!selection.isCollapsed) {
    editor.execute([DeleteContentRequest(documentRange: selection)]);
  }
  editor.execute([
    InsertTextRequest(
      documentPosition: position,
      textToInsert: text,
      attributions: {aiProvenanceAttribution},
    ),
  ]);
}
```

### Hive Settings Box Access
**Source:** `lib/core/infrastructure/settings_repository.dart` lines 1-14, 19-25, 48-56
**Apply to:** `onboarding_progress.dart`

```dart
// Constructor: takes Box<dynamic>
class SettingsRepository {
  final Box<dynamic> _box;
  SettingsRepository(this._box);

  // Read with default
  String getDefaultTag() {
    return _box.get(_defaultTagKey, defaultValue: FragmentTags.story) as String;
  }

  // Write
  Future<void> setDefaultTag(String tag) async {
    await _box.put(_defaultTagKey, tag);
  }
}
```

### AI Streaming + JSON Parse Pattern
**Source:** `lib/features/templates/application/template_completion_service.dart` lines 37-66
**Apply to:** `opening_generator_service.dart`

```dart
// Stream to buffer, then JSON decode, with catch for parse errors
try {
  final messages = _buildMessages(...);
  final stream = openAIAdapter!.createStream(
    apiKey: apiKey!, baseUrl: baseUrl!, model: model!, messages: messages,
  );
  final buffer = StringBuffer();
  await for (final chunk in stream) {
    buffer.write(chunk);
  }
  // Strip markdown fences before parsing
  final raw = buffer.toString().trim();
  final jsonStr = raw.startsWith('```') ? _stripFences(raw) : raw;
  final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
  return ...;
} catch (error) {
  return ... // error result with errorMessage
}
```

### Form Save Pattern
**Source:** `lib/features/knowledge/presentation/world_setting_form.dart` lines 210-270
**Apply to:** `world_step_page.dart`, `character_step_page.dart`

```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isSaving = true);
  try {
    // ... entity creation + notifier.add()
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已创建')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }
}
```

### Card + Tag Widget Pattern
**Source:** `lib/features/templates/presentation/template_gallery_page.dart` lines 144-225
**Apply to:** `genre_step_page.dart` (card grid), `opening_variant_card.dart` (variant display)

```dart
// Card with selection border
Card(
  margin: const EdgeInsets.only(bottom: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      width: 2,
    ),
  ),
  child: ...
)

// Pill tag
DecoratedBox(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  ),
)
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | -- | -- | All files have at least a role-match analog. The PageView-based wizard is a variation of the existing Stepper-based wizard pattern. |

## Metadata

**Analog search scope:** `lib/` (all Dart source files)
**Files scanned:** 26 source files examined
**Pattern extraction date:** 2026-06-04
