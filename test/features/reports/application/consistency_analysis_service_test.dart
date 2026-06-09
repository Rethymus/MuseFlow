import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/reports/application/consistency_analysis_service.dart';
import 'package:museflow/features/reports/providers.dart';

void main() {
  group('ConsistencyAnalysisService', () {
    test(
      'should return zero-value report when chapters and entities are empty',
      () {
        final service = _service(chapters: const []);

        final report = service.analyze();

        expect(report.overallConsistencyScore, 0.0);
        expect(report.characterResults, isEmpty);
        expect(report.settingResults, isEmpty);
        expect(report.driftPerSegment, List.filled(10, 0.0));
      },
    );

    test('should detect character name presence in chapters', () {
      final service = _service(
        chapters: [
          _chapter('c1', 'm1', '林青玄踏入山门，灵气翻涌。'),
          _chapter('c2', 'm1', '青玄在石阶前回望故乡。'),
        ],
        characters: [
          _character('林青玄', aliases: ['青玄']),
        ],
      );

      final report = service.analyze('m1');

      expect(report.characterResults.single.entityName, '林青玄');
      expect(report.characterResults.single.chaptersWhereMentioned, 2);
      expect(report.characterResults.single.consistencyScore, 1.0);
    });

    test('should count chaptersWhereMentioned per entity', () {
      final service = _service(
        chapters: [
          _chapter('c1', 'm1', '林青玄来到灵溪宗。'),
          _chapter('c2', 'm1', '灵溪宗钟声响起。'),
          _chapter('c3', 'm1', '山雨压城。'),
        ],
        characters: [_character('林青玄')],
      );

      final result = service.analyze('m1').characterResults.single;

      expect(result.chaptersWhereMentioned, 1);
      expect(result.flags, hasLength(2));
    });

    test('should produce driftPerSegment with exactly 10 entries', () {
      final service = _service(
        chapters: List.generate(
          100,
          (index) => _chapter(
            'c$index',
            'm1',
            index < 50 ? '林青玄闭关修炼。' : '山风寂静。',
            sortOrder: index + 1,
          ),
        ),
        characters: [_character('林青玄')],
      );

      final report = service.analyze('m1');

      expect(report.driftPerSegment, hasLength(10));
      expect(report.driftPerSegment.first, 1.0);
      expect(report.driftPerSegment.last, 0.0);
    });

    test(
      'should flag missing entities in later chapters as consistency drift',
      () {
        final service = _service(
          chapters: List.generate(
            8,
            (index) => _chapter(
              'c$index',
              'm1',
              index == 0 ? '林青玄出场。' : '无人提起他的名字。',
              sortOrder: index + 1,
            ),
          ),
          characters: [_character('林青玄')],
        );

        final flags = service.analyze('m1').characterResults.single.flags;

        expect(flags.first.severity, DeviationSeverity.medium);
        expect(flags.last.severity, DeviationSeverity.clear);
      },
    );

    test('should check world setting keywords in chapter content', () {
      final service = _service(
        chapters: [
          _chapter('c1', 'm1', '灵溪宗以剑修为尊。'),
          _chapter('c2', 'm1', '外门弟子守着灵溪宗山门。'),
        ],
        settings: [_setting('灵溪宗', rules: '剑修', factions: '外门弟子')],
      );

      final result = service.analyze('m1').settingResults.single;

      expect(result.entityName, '灵溪宗');
      expect(result.chaptersWhereMentioned, 2);
      expect(result.consistencyScore, 1.0);
    });

    test(
      'should expose blindReadProvider and consistencyReportProvider overrides',
      () {
        final container = ProviderContainer(
          overrides: [
            blindReadProvider.overrideWith(BlindReadNotifier.new),
            consistencyReportProvider.overrideWith(
              ConsistencyReportNotifier.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(blindReadProvider), isA<BlindReadState>());
        expect(container.read(consistencyReportProvider), isA<AsyncValue>());
      },
    );
  });
}

ConsistencyAnalysisService _service({
  required List<Chapter> chapters,
  List<CharacterCard> characters = const [],
  List<WorldSetting> settings = const [],
  List<SkillDocument> skills = const [],
}) {
  return ConsistencyAnalysisService(
    characterCardRepository: _FakeCharacterCardRepository(characters),
    worldSettingRepository: _FakeWorldSettingRepository(settings),
    skillRepository: _FakeSkillRepository(skills),
    chapterRepository: _FakeChapterRepository(chapters),
    nameIndex: NameIndex(),
  );
}

Chapter _chapter(
  String id,
  String manuscriptId,
  String content, {
  int sortOrder = 1,
}) {
  return Chapter(
    id: id,
    manuscriptId: manuscriptId,
    title: id,
    sortOrder: sortOrder,
    documentContent: content,
    createdAt: DateTime(2026, 6, 8),
    updatedAt: DateTime(2026, 6, 8),
  );
}

CharacterCard _character(String name, {List<String> aliases = const []}) {
  return CharacterCard(
    id: name,
    name: name,
    aliases: aliases,
    createdAt: DateTime(2026, 6, 8),
  );
}

WorldSetting _setting(String name, {String rules = '', String factions = ''}) {
  return WorldSetting(
    id: name,
    name: name,
    rules: rules,
    factions: factions,
    createdAt: DateTime(2026, 6, 8),
  );
}

class _FakeChapterRepository implements ChapterRepository {
  _FakeChapterRepository(this.chapters);
  final List<Chapter> chapters;
  @override
  List<Chapter> getAll() => chapters;
  @override
  Future<Chapter> add(Chapter chapter) async => chapter;
  @override
  Chapter? getById(String id) => chapters.where((c) => c.id == id).firstOrNull;
  @override
  List<Chapter> getByManuscriptId(String manuscriptId) =>
      chapters.where((c) => c.manuscriptId == manuscriptId).toList();
  @override
  Future<void> update(Chapter chapter) async {}
  @override
  Future<void> updateDocumentContent(String chapterId, String markdown) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> deleteByManuscriptId(String manuscriptId) async {}
}

class _FakeCharacterCardRepository implements CharacterCardRepository {
  _FakeCharacterCardRepository(this.cards);
  final List<CharacterCard> cards;
  @override
  List<CharacterCard> getAll() => cards;
  @override
  Future<CharacterCard> add(CharacterCard card) async => card;
  @override
  CharacterCard? getById(String id) =>
      cards.where((c) => c.id == id).firstOrNull;
  @override
  List<CharacterCard> searchByName(String query) =>
      cards.where((c) => c.name.contains(query)).toList();
  @override
  Future<void> update(CharacterCard card) async {}
  @override
  Future<void> delete(String id) async {}
}

class _FakeWorldSettingRepository implements WorldSettingRepository {
  _FakeWorldSettingRepository(this.settings);
  final List<WorldSetting> settings;
  @override
  List<WorldSetting> getAll() => settings;
  @override
  Future<WorldSetting> add(WorldSetting setting) async => setting;
  @override
  WorldSetting? getById(String id) =>
      settings.where((s) => s.id == id).firstOrNull;
  @override
  List<WorldSetting> searchByName(String query) =>
      settings.where((s) => s.name.contains(query)).toList();
  @override
  Future<void> update(WorldSetting setting) async {}
  @override
  Future<void> delete(String id) async {}
}

class _FakeSkillRepository implements SkillRepository {
  _FakeSkillRepository(this.skills);
  final List<SkillDocument> skills;
  @override
  List<SkillDocument> getAll() => skills;
  @override
  List<SkillDocument> getActive() => skills.where((s) => s.isActive).toList();
  @override
  Future<SkillDocument> add(SkillDocument document) async => document;
  @override
  SkillDocument? getById(String id) =>
      skills.where((s) => s.id == id).firstOrNull;
  @override
  Future<void> update(SkillDocument document) async {}
  @override
  Future<void> setActive(String id, bool isActive) async {}
  @override
  Future<void> delete(String id) async {}
}
