import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'package:museflow/features/story_structure/domain/export_bundle.dart';

/// Supported export formats.
enum ExportFormat {
  txt,
  markdown,
  json,
  docx;

  /// Deserialize from JSON string.
  static ExportFormat fromJsonString(String value) {
    return ExportFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExportFormat.txt,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => name;

  /// Whether this format produces binary output (vs. text).
  bool get isBinary => this == ExportFormat.docx;

  /// Human-readable label for the format.
  String get label => switch (this) {
    ExportFormat.txt => 'TXT',
    ExportFormat.markdown => 'Markdown',
    ExportFormat.json => 'JSON',
    ExportFormat.docx => 'DOCX',
  };

  /// Expected file extension.
  String get extension => switch (this) {
    ExportFormat.txt => '.txt',
    ExportFormat.markdown => '.md',
    ExportFormat.json => '.json',
    ExportFormat.docx => '.docx',
  };
}

/// File writer function signature for testability.
///
/// In production, this writes to [dart:io] File. In tests, this can be
/// replaced with an in-memory recorder.
typedef FileWriter = Future<void> Function(String path, String content);

/// Binary file writer function signature for binary export formats (DOCX).
typedef BinaryFileWriter = Future<void> Function(String path, List<int> bytes);

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
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Default binary file writer using dart:io.
  ///
  /// Writes raw bytes to a file. Used for DOCX export.
  static Future<void> dartBinaryFileWriter(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
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
    return bundle.manuscriptText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
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
    return bundle.manuscriptText
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
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
  ///
  /// For binary formats (DOCX), use [buildDocxBytes] instead.
  String buildContent(ExportBundle bundle, ExportFormat format) {
    return switch (format) {
      ExportFormat.txt => buildTxt(bundle),
      ExportFormat.markdown => buildMarkdown(bundle),
      ExportFormat.json => buildJson(bundle),
      ExportFormat.docx => throw UnsupportedError(
        'Use buildDocxBytes for DOCX format',
      ),
    };
  }

  /// Builds a DOCX (Office Open XML) file as raw bytes.
  ///
  /// Creates a minimal OOXML ZIP archive containing:
  /// - `[Content_Types].xml` — content type declarations
  /// - `_rels/.rels` — package relationships
  /// - `word/document.xml` — the manuscript content
  /// - `word/_rels/document.xml.rels` — document relationships
  ///
  /// When the bundle has chapters, each chapter title is rendered as a
  /// Heading1 paragraph and its content as BodyText. Otherwise falls back
  /// to flat manuscript text with paragraphs separated by BodyText.
  List<int> buildDocxBytes(ExportBundle bundle) {
    final archive = Archive();

    // [Content_Types].xml
    final contentTypes =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        contentTypes.length,
        utf8.encode(contentTypes),
      ),
    );

    // _rels/.rels
    const rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));

    // word/_rels/document.xml.rels
    const docRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
</Relationships>''';
    archive.addFile(
      ArchiveFile(
        'word/_rels/document.xml.rels',
        docRels.length,
        utf8.encode(docRels),
      ),
    );

    // word/document.xml
    final documentXml = _buildDocumentXml(bundle);
    final docBytes = utf8.encode(documentXml);
    archive.addFile(
      ArchiveFile('word/document.xml', docBytes.length, docBytes),
    );

    return ZipEncoder().encode(archive);
  }

  /// Builds the word/document.xml content from the export bundle.
  String _buildDocumentXml(ExportBundle bundle) {
    final bodyBuffer = StringBuffer();

    if (bundle.chapters.isNotEmpty) {
      final sorted = List.of(bundle.chapters)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (final chapter in sorted) {
        // Chapter title as Heading1
        bodyBuffer.writeln(_buildParagraphXml(chapter.title, 'Heading1'));
        // Chapter content as BodyText paragraphs
        _appendTextAsParagraphs(bodyBuffer, chapter.content);
      }
    } else {
      // Flat text fallback
      _appendTextAsParagraphs(bodyBuffer, bundle.manuscriptText);
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" mc:Ignorable="w14 wp14">
  <w:body>
$bodyBuffer</w:body>
</w:document>''';
  }

  /// Builds a single OOXML paragraph element.
  String _buildParagraphXml(String text, String style) {
    final escaped = _xmlEscape(text);
    return '<w:p><w:pPr><w:pStyle w:val="$style"/></w:pPr><w:r><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
  }

  /// Appends text as BodyText paragraphs, splitting on double newlines.
  void _appendTextAsParagraphs(StringBuffer buffer, String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final paragraphs = normalized.split('\n\n');
    for (final para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;
      buffer.writeln(_buildParagraphXml(trimmed, 'BodyText'));
    }
  }

  /// Escapes text for safe inclusion in XML content.
  static String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Writes content to a local file at [path].
  ///
  /// Uses the injectable file writer for testability.
  /// In production, the caller selects the path via file_picker saveFile.
  Future<void> writeLocalFile(String path, String content) async {
    await _fileWriter(path, content);
  }
}
