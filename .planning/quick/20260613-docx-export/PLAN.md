# DOCX Export Support

## Task
Add DOCX export format using `archive` package for ZIP generation and manual OOXML XML construction.

## Changes

### 1. pubspec.yaml
- Add `archive: ^4.0.0` dependency

### 2. export_service.dart
- Add `docx` to `ExportFormat` enum (label: 'DOCX', extension: '.docx')
- Add `BinaryFileWriter` typedef: `Future<void> Function(String path, List<int> bytes)`
- Add `dartBinaryFileWriter` static method
- Add `buildDocxBytes(ExportBundle bundle)` → `List<int>` (ZIP bytes)
  - Creates minimal OOXML: `[Content_Types].xml`, `_rels/.rels`, `word/document.xml`, `word/_rels/document.xml.rels`
  - Chapter titles → `<w:p>` with `<w:pStyle w:val="Heading1"/>`
  - Content paragraphs → `<w:p>` with `<w:pStyle w:val="BodyText"/>`
  - Handles XML escaping for special characters in Chinese text
- Update `buildContent` switch: for docx, throw unsupported (use `buildDocxBytes`)

### 3. export_dialog.dart
- Add DOCX to SegmentedButton
- Change `onExport` signature: `Future<void> Function(ExportFormat, String, String? text, List<int>? bytes)`
- In `_doExport()`, branch on format: text formats use `buildContent`, docx uses `buildDocxBytes`
- Add DOCX format description
- Add DOCX content summary section (chapter-aware export info)

### 4. story_structure_page.dart
- Update `onExport` callback to handle binary content for DOCX

### 5. export_service_test.dart
- Add DOCX builder tests:
  - Valid ZIP archive
  - Contains document.xml with chapter titles
  - Flat text (no chapters) fallback
  - Chinese text XML escaping

### 6. format_export_test.dart
- Update for DOCX button in dialog
- Update onExport callback signature

## Design Decisions
- **No external DOCX package**: pub.dev has no standalone DOCX generation package. Manual OOXML is sufficient for manuscript export.
- **Dual callback**: `onExport(format, path, textContent?, binaryContent?)` preserves backward compatibility while supporting binary DOCX.
- **Minimal OOXML**: Only 4 files in the ZIP — no styles.xml, no fonts. Headers use Word built-in style names (Heading1, BodyText) so Word applies defaults.
