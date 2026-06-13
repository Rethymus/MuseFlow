import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';
import 'package:museflow/features/manuscript/domain/chapter_export.dart';

/// Decodes the content of an [ArchiveFile] as UTF-8 string.
String _decodeFile(ArchiveFile f) => utf8.decode(f.content);

void main() {
  group('ExportService', () {
    late ExportService service;
    late List<_FileWriteCall> writeCalls;

    setUp(() {
      writeCalls = [];
      service = ExportService(
        fileWriter: (path, content) async {
          writeCalls.add(_FileWriteCall(path: path, content: content));
        },
      );
    });

    ExportBundle createTestBundle({String manuscriptText = '第一段。\n\n第二段。'}) {
      return ExportBundle(
        schemaVersion: '1.0',
        exportedAt: DateTime(2026, 6, 4),
        manuscriptText: manuscriptText,
        foreshadowingEntries: [
          ForeshadowingEntry(
            id: 'f1',
            title: '伏笔一',
            mode: ForeshadowingMode.detailed,
            status: ForeshadowingStatus.planted,
            plantedChapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        plotNodes: [
          PlotNode(
            id: 'p1',
            title: '开端',
            chapter: 1,
            createdAt: DateTime(2026, 6, 1),
          ),
        ],
        guardianAnnotations: [
          GuardianAnnotation(
            id: 'g1',
            kind: GuardianFindingKind.characterConsistency,
            severity: GuardianSeverity.medium,
            message: '角色行为不一致',
            reason: '与设定冲突',
            createdAt: DateTime(2026, 6, 2),
          ),
        ],
        characterCards: [
          {'id': 'c1', 'name': '角色A'},
        ],
        worldSettings: [
          {'id': 'w1', 'name': '修仙世界'},
        ],
        skillDocuments: [
          {'id': 's1', 'name': '功法体系'},
        ],
        activeSkillIds: ['s1'],
        metadata: {'appVersion': '1.0.0'},
      );
    }

    // --- TXT builder ---

    group('TXT builder', () {
      test('should return readable manuscript text with LF line endings', () {
        final bundle = createTestBundle();
        final txt = service.buildTxt(bundle);

        expect(txt, contains('第一段。'));
        expect(txt, contains('第二段。'));
        // Should use LF line endings
        expect(txt.contains('\r'), isFalse);
      });

      test('should produce stable output for the same input', () {
        final bundle = createTestBundle();
        final txt1 = service.buildTxt(bundle);
        final txt2 = service.buildTxt(bundle);
        expect(txt1, txt2);
      });
    });

    // --- Markdown builder ---

    group('Markdown builder', () {
      test('should return paragraph-separated manuscript text', () {
        final bundle = createTestBundle();
        final md = service.buildMarkdown(bundle);

        expect(md, contains('第一段。'));
        expect(md, contains('第二段。'));
      });

      test('should preserve blank line between paragraphs', () {
        final bundle = createTestBundle();
        final md = service.buildMarkdown(bundle);

        expect(md, contains('\n\n'));
      });
    });

    // --- JSON builder ---

    group('JSON builder', () {
      test('should return valid JSON with complete structured data', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);

        // Should be valid JSON
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        expect(parsed['schemaVersion'], '1.0');
        expect(parsed['manuscriptText'], '第一段。\n\n第二段。');
        expect(parsed['foreshadowingEntries'], isA<List>());
        expect(parsed['plotNodes'], isA<List>());
        expect(parsed['guardianAnnotations'], isA<List>());
        expect(parsed['characterCards'], isA<List>());
        expect(parsed['worldSettings'], isA<List>());
        expect(parsed['skillDocuments'], isA<List>());
        expect(parsed['activeSkillIds'], isA<List>());
        expect(parsed['metadata'], isA<Map>());
      });

      test('should include manuscript text in JSON export', () {
        final bundle = createTestBundle(manuscriptText: '特殊的稿件文本');
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        expect(parsed['manuscriptText'], '特殊的稿件文本');
      });

      test('should include all foreshadowing entries in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final entries = parsed['foreshadowingEntries'] as List;
        expect(entries.length, 1);
        expect(entries[0]['id'], 'f1');
        expect(entries[0]['title'], '伏笔一');
      });

      test('should include all plot nodes in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final nodes = parsed['plotNodes'] as List;
        expect(nodes.length, 1);
        expect(nodes[0]['id'], 'p1');
      });

      test('should include guardian annotations in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final annotations = parsed['guardianAnnotations'] as List;
        expect(annotations.length, 1);
        expect(annotations[0]['id'], 'g1');
      });

      test('should include character cards in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final chars = parsed['characterCards'] as List;
        expect(chars.length, 1);
        expect(chars[0]['name'], '角色A');
      });

      test('should include world settings in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final worlds = parsed['worldSettings'] as List;
        expect(worlds.length, 1);
        expect(worlds[0]['name'], '修仙世界');
      });

      test('should include skill documents and active IDs in JSON export', () {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final skills = parsed['skillDocuments'] as List;
        expect(skills.length, 1);
        expect(skills[0]['name'], '功法体系');

        final activeIds = parsed['activeSkillIds'] as List;
        expect(activeIds, ['s1']);
      });
    });

    // --- Local file writing ---

    group('local file writing', () {
      test('should write file to selected path via file writer', () async {
        await service.writeLocalFile('/test/output.txt', 'content');

        expect(writeCalls.length, 1);
        expect(writeCalls[0].path, '/test/output.txt');
        expect(writeCalls[0].content, 'content');
      });

      test('should write TXT content to file', () async {
        final bundle = createTestBundle();
        final txt = service.buildTxt(bundle);
        await service.writeLocalFile('/test/manuscript.txt', txt);

        expect(writeCalls[0].content, txt);
      });

      test('should write JSON content to file', () async {
        final bundle = createTestBundle();
        final jsonStr = service.buildJson(bundle);
        await service.writeLocalFile('/test/export.json', jsonStr);

        expect(writeCalls[0].content, jsonStr);
        // Verify it's valid JSON
        expect(() => jsonDecode(writeCalls[0].content), returnsNormally);
      });

      test(
        'dartFileWriter should create parent directories and write file',
        () async {
          final tempDir = await Directory.systemTemp.createTemp(
            'museflow-export-test-',
          );
          addTearDown(() async {
            if (await tempDir.exists()) {
              await tempDir.delete(recursive: true);
            }
          });

          final outputPath =
              '${tempDir.path}/nested/reports/token-cost-report.md';
          await ExportService.dartFileWriter(outputPath, '# report');

          final outputFile = File(outputPath);
          expect(await outputFile.exists(), isTrue);
          expect(await outputFile.readAsString(), '# report');
        },
      );
    });

    // --- Export format selection ---

    group('export format selection', () {
      test('should build content based on ExportFormat', () {
        final bundle = createTestBundle();

        final txt = service.buildContent(bundle, ExportFormat.txt);
        final md = service.buildContent(bundle, ExportFormat.markdown);
        final json = service.buildContent(bundle, ExportFormat.json);

        expect(txt, contains('第一段。'));
        expect(md, contains('第一段。'));
        expect(() => jsonDecode(json), returnsNormally);
      });

      test('buildContent should throw for DOCX format', () {
        final bundle = createTestBundle();
        expect(
          () => service.buildContent(bundle, ExportFormat.docx),
          throwsUnsupportedError,
        );
      });
    });

    // --- DOCX builder ---

    group('DOCX builder', () {
      test('should produce a valid ZIP archive', () {
        final bundle = createTestBundle();
        final bytes = service.buildDocxBytes(bundle);

        // Should be a valid ZIP (starts with PK magic bytes)
        expect(bytes.isNotEmpty, isTrue);
        expect(bytes[0], 0x50); // P
        expect(bytes[1], 0x4B); // K

        // Should be decodable as ZIP
        final archive = ZipDecoder().decodeBytes(bytes);
        expect(archive, isNotNull);
      });

      test('should contain required OOXML files', () {
        final bundle = createTestBundle();
        final bytes = service.buildDocxBytes(bundle);
        final archive = ZipDecoder().decodeBytes(bytes);

        final fileNames =
            archive.files.map((f) => f.name).toList();
        expect(fileNames, contains('[Content_Types].xml'));
        expect(fileNames, contains('_rels/.rels'));
        expect(fileNames, contains('word/document.xml'));
        expect(fileNames, contains('word/_rels/document.xml.rels'));
      });

      test('should include flat manuscript text in document.xml', () {
        final bundle = createTestBundle(
          manuscriptText: '第一段。\n\n第二段。',
        );
        final bytes = service.buildDocxBytes(bundle);
        final archive = ZipDecoder().decodeBytes(bytes);

        final docFile = archive.files.firstWhere(
          (f) => f.name == 'word/document.xml',
        );
        final docXml = _decodeFile(docFile);
        expect(docXml, contains('第一段。'));
        expect(docXml, contains('第二段。'));
        expect(docXml, contains('BodyText'));
      });

      test('should render chapter titles as Heading1', () {
        final bundle = ExportBundle(
          schemaVersion: '1.0',
          manuscriptText: '',
          chapters: [
            ChapterExport(title: '第一章 开端', sortOrder: 1, content: '内容一。'),
            ChapterExport(title: '第二章 发展', sortOrder: 2, content: '内容二。'),
          ],
        );
        final bytes = service.buildDocxBytes(bundle);
        final archive = ZipDecoder().decodeBytes(bytes);

        final docFile = archive.files.firstWhere(
          (f) => f.name == 'word/document.xml',
        );
        final docXml = _decodeFile(docFile);
        expect(docXml, contains('第一章 开端'));
        expect(docXml, contains('第二章 发展'));
        expect(docXml, contains('Heading1'));
        expect(docXml, contains('BodyText'));
      });

      test('should sort chapters by sortOrder', () {
        final bundle = ExportBundle(
          schemaVersion: '1.0',
          manuscriptText: '',
          chapters: [
            ChapterExport(title: '第二章', sortOrder: 2, content: 'B'),
            ChapterExport(title: '第一章', sortOrder: 1, content: 'A'),
          ],
        );
        final bytes = service.buildDocxBytes(bundle);
        final archive = ZipDecoder().decodeBytes(bytes);

        final docFile = archive.files.firstWhere(
          (f) => f.name == 'word/document.xml',
        );
        final docXml = _decodeFile(docFile);

        // 第一章 should appear before 第二章 in the XML
        final firstIndex = docXml.indexOf('第一章');
        final secondIndex = docXml.indexOf('第二章');
        expect(firstIndex, lessThan(secondIndex));
      });

      test('should escape XML special characters in content', () {
        final bundle = createTestBundle(
          manuscriptText: '他喊道："快跑！" <tag>',
        );
        final bytes = service.buildDocxBytes(bundle);
        final archive = ZipDecoder().decodeBytes(bytes);

        final docFile = archive.files.firstWhere(
          (f) => f.name == 'word/document.xml',
        );
        final docXml = _decodeFile(docFile);

        // XML special chars should be escaped
        expect(docXml, contains('&lt;'));
        expect(docXml, contains('&gt;'));
        expect(docXml, contains('&quot;'));
      });

      test('should produce stable output for same input', () {
        final bundle = createTestBundle();
        final bytes1 = service.buildDocxBytes(bundle);
        final bytes2 = service.buildDocxBytes(bundle);
        expect(bytes1, bytes2);
      });
    });
  });
}

class _FileWriteCall {
  final String path;
  final String content;

  _FileWriteCall({required this.path, required this.content});
}
