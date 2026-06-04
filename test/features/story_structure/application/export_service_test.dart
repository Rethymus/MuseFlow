import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/export_bundle.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/domain/guardian_annotation.dart';

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

    ExportBundle _createTestBundle({String manuscriptText = '第一段。\n\n第二段。'}) {
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
        final bundle = _createTestBundle();
        final txt = service.buildTxt(bundle);

        expect(txt, contains('第一段。'));
        expect(txt, contains('第二段。'));
        // Should use LF line endings
        expect(txt.contains('\r'), isFalse);
      });

      test('should produce stable output for the same input', () {
        final bundle = _createTestBundle();
        final txt1 = service.buildTxt(bundle);
        final txt2 = service.buildTxt(bundle);
        expect(txt1, txt2);
      });
    });

    // --- Markdown builder ---

    group('Markdown builder', () {
      test('should return paragraph-separated manuscript text', () {
        final bundle = _createTestBundle();
        final md = service.buildMarkdown(bundle);

        expect(md, contains('第一段。'));
        expect(md, contains('第二段。'));
      });

      test('should preserve blank line between paragraphs', () {
        final bundle = _createTestBundle();
        final md = service.buildMarkdown(bundle);

        expect(md, contains('\n\n'));
      });
    });

    // --- JSON builder ---

    group('JSON builder', () {
      test('should return valid JSON with complete structured data', () {
        final bundle = _createTestBundle();
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
        final bundle = _createTestBundle(manuscriptText: '特殊的稿件文本');
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        expect(parsed['manuscriptText'], '特殊的稿件文本');
      });

      test('should include all foreshadowing entries in JSON export', () {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final entries = parsed['foreshadowingEntries'] as List;
        expect(entries.length, 1);
        expect(entries[0]['id'], 'f1');
        expect(entries[0]['title'], '伏笔一');
      });

      test('should include all plot nodes in JSON export', () {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final nodes = parsed['plotNodes'] as List;
        expect(nodes.length, 1);
        expect(nodes[0]['id'], 'p1');
      });

      test('should include guardian annotations in JSON export', () {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final annotations = parsed['guardianAnnotations'] as List;
        expect(annotations.length, 1);
        expect(annotations[0]['id'], 'g1');
      });

      test('should include character cards in JSON export', () {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final chars = parsed['characterCards'] as List;
        expect(chars.length, 1);
        expect(chars[0]['name'], '角色A');
      });

      test('should include world settings in JSON export', () {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        final worlds = parsed['worldSettings'] as List;
        expect(worlds.length, 1);
        expect(worlds[0]['name'], '修仙世界');
      });

      test('should include skill documents and active IDs in JSON export', () {
        final bundle = _createTestBundle();
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
        final bundle = _createTestBundle();
        await service.writeLocalFile('/test/output.txt', 'content');

        expect(writeCalls.length, 1);
        expect(writeCalls[0].path, '/test/output.txt');
        expect(writeCalls[0].content, 'content');
      });

      test('should write TXT content to file', () async {
        final bundle = _createTestBundle();
        final txt = service.buildTxt(bundle);
        await service.writeLocalFile('/test/manuscript.txt', txt);

        expect(writeCalls[0].content, txt);
      });

      test('should write JSON content to file', () async {
        final bundle = _createTestBundle();
        final jsonStr = service.buildJson(bundle);
        await service.writeLocalFile('/test/export.json', jsonStr);

        expect(writeCalls[0].content, jsonStr);
        // Verify it's valid JSON
        expect(() => jsonDecode(writeCalls[0].content), returnsNormally);
      });
    });

    // --- Export format selection ---

    group('export format selection', () {
      test('should build content based on ExportFormat', () {
        final bundle = _createTestBundle();

        final txt = service.buildContent(bundle, ExportFormat.txt);
        final md = service.buildContent(bundle, ExportFormat.markdown);
        final json = service.buildContent(bundle, ExportFormat.json);

        expect(txt, contains('第一段。'));
        expect(md, contains('第一段。'));
        expect(() => jsonDecode(json), returnsNormally);
      });
    });
  });
}

class _FileWriteCall {
  final String path;
  final String content;

  _FileWriteCall({required this.path, required this.content});
}
