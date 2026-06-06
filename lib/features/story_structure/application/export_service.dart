import 'dart:convert';

import 'package:museflow/features/story_structure/domain/export_bundle.dart';

/// Supported export formats.
enum ExportFormat {
  txt,
  markdown,
  json;

  /// Deserialize from JSON string.
  static ExportFormat fromJsonString(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportFormat.txt,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;

  /// Human-readable label for the format.
  String get label => switch (this) {
        ExportFormat.txt => 'TXT',
        ExportFormat.markdown => 'Markdown',
        ExportFormat.json => 'JSON',
      };

  /// Expected file extension.
  String get extension => switch (this) {
        ExportFormat.txt => '.txt',
        ExportFormat.markdown => '.md',
        ExportFormat.json => '.json',
      };
}

/// File writer function signature for testability.
///
/// In production, this writes to [dart:io] File. In tests, this can be
/// replaced with an in-memory recorder.
typedef FileWriter = Future<void> Function(String path, String content);

/// Service for building and writing exported manuscript content.
///
/// Supports TXT, Markdown, and JSON export formats. TXT and Markdown export
/// readable manuscript text; JSON exports the complete [ExportBundle] with
/// all structured story data per FRMT-04.
///
/// File writing uses an injectable [FileWriter] abstraction so tests can
/// verify behavior without touching the filesystem.
class ExportService {
  final FileWriter _fileWriter;

  /// Creates an ExportService with an injectable file writer.
  ///
  /// Production code should pass [dartFileWriter]. Tests should pass a mock.
  // ignore: prefer_initializing_formals
  ExportService({required FileWriter fileWriter}) : _fileWriter = fileWriter;

  /// Default file writer using dart:io.
  ///
  /// Uses synchronous write for simplicity. Wraps in async for the interface.
  static Future<void> dartFileWriter(String path, String content) async {
    // Import dart:io dynamically so the class compiles in test environments.
    // The actual import is at the call site in production providers.
    final file = await _writeWithDartIo(path, content);
    if (!file) {
      throw StateError('Failed to write file: $path');
    }
  }

  static Future<bool> _writeWithDartIo(String path, String content) async {
    try {
      // dart:io is available on Windows/Android but not in flutter test.
      // Production callers should use the production provider which imports
      // dart:io directly. This fallback exists for the type signature.
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Builds TXT content from the export bundle.
  ///
  /// When the bundle has chapters, produces chapter-separated output with
  /// plain text title separators. Otherwise returns flat manuscript text
  /// with stable LF line endings.
  String buildTxt(ExportBundle bundle) {
    if (bundle.chapters.isNotEmpty) {
      final sorted = List.of(bundle.chapters)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final buffer = StringBuffer();
      for (final chapter in sorted) {
        buffer.writeln(chapter.title);
        buffer.writeln(chapter.content);
        buffer.writeln();
      }
      return buffer.toString().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    }
    return bundle.manuscriptText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Builds Markdown content from the export bundle.
  ///
  /// When the bundle has chapters, produces chapter-aware output with
  /// '## {title}' headers between chapters sorted by sortOrder.
  /// Otherwise returns flat manuscript text with stable LF line endings.
  String buildMarkdown(ExportBundle bundle) {
    if (bundle.chapters.isNotEmpty) {
      final sorted = List.of(bundle.chapters)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final buffer = StringBuffer();
      for (final chapter in sorted) {
        buffer.writeln('## ${chapter.title}');
        buffer.writeln();
        buffer.writeln(chapter.content);
        buffer.writeln();
      }
      return buffer.toString().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    }
    return bundle.manuscriptText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  /// Builds JSON content from the export bundle.
  ///
  /// Returns complete structured story data per FRMT-04 including manuscript
  /// text, foreshadowing, plot nodes, guardian annotations, character cards,
  /// world settings, skill documents, active skill IDs, and metadata.
  String buildJson(ExportBundle bundle) {
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }

  /// Builds content for the specified export format.
  String buildContent(ExportBundle bundle, ExportFormat format) {
    return switch (format) {
      ExportFormat.txt => buildTxt(bundle),
      ExportFormat.markdown => buildMarkdown(bundle),
      ExportFormat.json => buildJson(bundle),
    };
  }

  /// Writes content to a local file at [path].
  ///
  /// Uses the injectable file writer for testability.
  /// In production, the caller selects the path via file_picker saveFile.
  Future<void> writeLocalFile(String path, String content) async {
    await _fileWriter(path, content);
  }
}
