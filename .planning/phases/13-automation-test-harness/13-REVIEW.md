---
phase: 13-automation-test-harness
reviewed: 2026-06-07T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - integration_test/manuscript_flow_test.dart
  - lib/core/presentation/providers.dart
  - lib/features/ai/domain/ai_adapter.dart
  - lib/features/ai/infrastructure/openai_adapter.dart
  - lib/features/editor/presentation/floating_toolbar.dart
  - lib/features/knowledge/application/deviation_detection_service.dart
  - lib/features/knowledge/application/skill_generation_service.dart
  - lib/features/manuscript/presentation/chapter_create_dialog.dart
  - lib/features/manuscript/presentation/chapter_sidebar.dart
  - lib/features/manuscript/presentation/manuscript_create_dialog.dart
  - lib/features/onboarding/application/opening_generator_service.dart
  - lib/features/story_structure/presentation/export_dialog.dart
  - lib/features/templates/application/template_completion_service.dart
  - test/automation/core_flow_test.dart
  - test/automation/fixtures/manuscript_fixtures.dart
  - test/automation/fixtures/xianxia_content.dart
  - test/automation/helpers/fake_adapter.dart
  - test/automation/helpers/fake_adapter_test.dart
  - test/automation/helpers/test_container.dart
  - test/features/ai/domain/ai_adapter_test.dart
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-06-07T00:00:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the Phase 13 automation-test-harness file scope at standard depth, including the new AI adapter abstraction, fake adapter/test harness, integration flow tests, manuscript UI entry points, export UI, and AI-assisted generation services. The implementation still has correctness and security defects: export success is reported without the selected path ever being written, model-list fetching bypasses the HTTPS guard used by streaming requests, model-list failures leak client resources, and the editor floating toolbar can crash on cross-node selections.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Export dialog reports success without writing to the selected file

**File:** `lib/features/story_structure/presentation/export_dialog.dart:65-85`

**Issue:** `_doExport()` requires `_selectedPath` but never uses it. It builds content and calls `widget.onExport(_selectedFormat, content)` without passing the path or invoking `ExportService.writeLocalFile()`, then displays `已导出至: $_selectedPath`. This can tell users their manuscript was exported even when no file was written. The integration test at `integration_test/manuscript_flow_test.dart:95-128` repeats the same blind spot: it asserts the success text after a callback that only inspects format/content and never verifies a file exists.

**Fix:** Make the selected path part of the export contract and have the production caller write through `exportServiceProvider`.

```dart
// ExportDialog
final Future<void> Function(
  ExportFormat format,
  String path,
  String content,
) onExport;

Future<void> _doExport() async {
  final path = _selectedPath;
  if (path == null || path.isEmpty) return;

  setState(() {
    _isExporting = true;
    _errorMessage = null;
    _exportSuccess = false;
  });

  try {
    final content = _exportService.buildContent(widget.bundle, _selectedFormat);
    await widget.onExport(_selectedFormat, path, content);
    if (mounted) {
      setState(() {
        _isExporting = false;
        _exportSuccess = true;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isExporting = false;
        _errorMessage = e.toString();
      });
    }
  }
}
```

Production usage should call:

```dart
final exportService = ref.read(exportServiceProvider);

ExportDialog(
  bundle: bundle,
  onExport: (format, path, content) async {
    await exportService.writeLocalFile(path, content);
  },
);
```

Also update the integration test to assert that the chosen file exists and contains the exported content.

### CR-02: Model-list fetching can leak API keys over plaintext HTTP

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:146-153`

**Issue:** `createStream()` enforces HTTPS by calling `_validateBaseUrl(baseUrl)` before creating an `OpenAIClient`, but `fetchModelList()` creates a client directly from the supplied `baseUrl`. A configured non-localhost `http://` endpoint can therefore receive the API key in cleartext during model discovery, violating the adapter’s HTTPS-enforcement contract and the project’s local-secret/privacy requirements.

**Fix:** Reuse `_validateBaseUrl()` before constructing the model-list client.

```dart
Future<List<String>> fetchModelList({
  required String apiKey,
  required String baseUrl,
}) async {
  if (apiKey.isEmpty) return [];

  try {
    _validateBaseUrl(baseUrl);
    final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
    try {
      final modelList = await client.models.list().timeout(
            const Duration(seconds: 5),
          );
      return modelList.data.map((m) => m.id).toList();
    } finally {
      client.close();
    }
  } catch (_) {
    return [];
  }
}
```

## Warnings

### WR-01: Model-list fetch leaks OpenAIClient resources on timeout/error

**File:** `lib/features/ai/infrastructure/openai_adapter.dart:151-160`

**Issue:** `client.close()` is only reached after a successful `client.models.list()`. If the request times out, the network fails, or response parsing throws, execution jumps to `catch` and the client is not closed. Repeated model-list refreshes can accumulate open client resources.

**Fix:** Always close the temporary model-list client with `finally`.

```dart
final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
try {
  final modelList = await client.models.list().timeout(
        const Duration(seconds: 5),
      );
  return modelList.data.map((m) => m.id).toList();
} finally {
  client.close();
}
```

### WR-02: Floating toolbar assumes single TextNode selection and can crash on cross-node selections

**File:** `lib/features/editor/presentation/floating_toolbar.dart:176-180,227-234,255-270`

**Issue:** `_getSelectedText()`, `_setAnchor()`, and `_startOperation()` force-cast both `selection.base.nodePosition` and `selection.extent.nodePosition` to `TextNodePosition` and then call `substring(start, end)` on only the base node’s text. A normal editor selection can span paragraphs/nodes or include a non-text node. In those cases the cast can throw, or `end` can be outside the base node’s text and `substring` will throw. That makes AI rewrite/polish and anchor creation fragile for multi-paragraph selections.

**Fix:** Centralize selection-range extraction and either support cross-node extraction or explicitly reject it before any cast/substr operation.

```dart
({String nodeId, int start, int end, String text})? _singleTextNodeSelection(
  DocumentSelection selection,
) {
  if (selection.base.nodeId != selection.extent.nodeId) return null;

  final node = widget.editor.document.getNodeById(selection.base.nodeId);
  if (node is! TextNode) return null;

  final basePosition = selection.base.nodePosition;
  final extentPosition = selection.extent.nodePosition;
  if (basePosition is! TextNodePosition ||
      extentPosition is! TextNodePosition) {
    return null;
  }

  final text = node.text.toPlainText();
  final start = basePosition.offset < extentPosition.offset
      ? basePosition.offset
      : extentPosition.offset;
  final end = basePosition.offset < extentPosition.offset
      ? extentPosition.offset
      : basePosition.offset;

  if (start < 0 || end > text.length || start >= end) return null;
  return (nodeId: node.id, start: start, end: end, text: text.substring(start, end));
}
```

Then `_setAnchor()` and `_startOperation()` should use this parsed result rather than repeating unchecked casts.

---

_Reviewed: 2026-06-07T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
