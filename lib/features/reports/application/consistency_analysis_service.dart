import 'dart:math';

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
import 'package:museflow/features/reports/domain/consistency_report.dart';

class ConsistencyAnalysisService {
  const ConsistencyAnalysisService({
    required CharacterCardRepository characterCardRepository,
    required WorldSettingRepository worldSettingRepository,
    required SkillRepository skillRepository,
    required ChapterRepository chapterRepository,
    required NameIndex nameIndex,
  })  : _characterCardRepository = characterCardRepository,
        _worldSettingRepository = worldSettingRepository,
        _skillRepository = skillRepository,
        _chapterRepository = chapterRepository,
        _nameIndex = nameIndex;

  final CharacterCardRepository _characterCardRepository;
  final WorldSettingRepository _worldSettingRepository;
  final SkillRepository _skillRepository;
  final ChapterRepository _chapterRepository;
  final NameIndex _nameIndex;

  ConsistencyReport analyze([String? manuscriptId]) {
    final chapters = _loadChapters(manuscriptId);
    final characters = _characterCardRepository.getAll();
    final settings = _worldSettingRepository.getAll();
    final skills = _skillRepository.getAll();

    if (chapters.isEmpty || (characters.isEmpty && settings.isEmpty && skills.isEmpty)) {
      return ConsistencyReport(
        characterResults: const [],
        settingResults: const [],
        overallConsistencyScore: 0.0,
        driftPerSegment: List.filled(10, 0.0),
      );
    }

    _refreshNameIndex(characters, settings, skills);

    final characterResults = characters
        .map(
          (character) => _analyzeEntity(
            name: character.name,
            entityType: 'character',
            terms: character.allNames,
            chapters: chapters,
          ),
        )
        .toList(growable: false);

    final settingResults = settings
        .map(
          (setting) => _analyzeEntity(
            name: setting.name,
            entityType: 'setting',
            terms: _settingTerms(setting),
            chapters: chapters,
          ),
        )
        .toList(growable: false);

    final skillResults = skills
        .map(
          (skill) => _analyzeEntity(
            name: skill.name,
            entityType: 'skill',
            terms: skill.allNames,
            chapters: chapters,
          ),
        )
        .toList(growable: false);

    final allResults = [
      ...characterResults,
      ...settingResults,
      ...skillResults,
    ];
    final overall = allResults.isEmpty
        ? 0.0
        : allResults.map((result) => result.consistencyScore).reduce((a, b) => a + b) / allResults.length;

    return ConsistencyReport(
      characterResults: characterResults,
      settingResults: settingResults,
      overallConsistencyScore: overall.clamp(0.0, 1.0),
      driftPerSegment: _computeDriftPerSegment(chapters, allResults),
    );
  }

  List<Chapter> _loadChapters(String? manuscriptId) {
    final chapters = (manuscriptId == null || manuscriptId.isEmpty
            ? _chapterRepository.getAll()
            : _chapterRepository.getByManuscriptId(manuscriptId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return chapters;
  }

  void _refreshNameIndex(
    List<CharacterCard> characters,
    List<WorldSetting> settings,
    List<SkillDocument> skills,
  ) {
    _nameIndex.clear();
    for (final character in characters) {
      _nameIndex.addEntity(character.id, character.entityType, character.allNames);
    }
    for (final setting in settings) {
      _nameIndex.addEntity(setting.id, setting.entityType, setting.allNames);
    }
    for (final skill in skills) {
      _nameIndex.addEntity(skill.id, skill.entityType, skill.allNames);
    }
  }

  EntityConsistencyResult _analyzeEntity({
    required String name,
    required String entityType,
    required List<String> terms,
    required List<Chapter> chapters,
  }) {
    final normalizedTerms = terms
        .map((term) => term.trim())
        .where((term) => term.isNotEmpty)
        .toSet()
        .toList(growable: false);
    var mentioned = 0;
    var consecutiveAbsences = 0;
    final flags = <ConsistencyFlag>[];

    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];
      final hasMention = normalizedTerms.any(chapter.documentContent.contains);
      if (hasMention) {
        mentioned++;
        consecutiveAbsences = 0;
      } else {
        consecutiveAbsences++;
        flags.add(
          ConsistencyFlag(
            chapterIndex: index,
            field: 'presence',
            expectedValue: 'mentioned',
            observedText: 'not found',
            severity: consecutiveAbsences >= 5
                ? DeviationSeverity.clear
                : DeviationSeverity.medium,
          ),
        );
      }
    }

    final score = chapters.isEmpty ? 0.0 : mentioned / chapters.length;
    return EntityConsistencyResult(
      entityName: name,
      entityType: entityType,
      chaptersWhereMentioned: mentioned,
      consistencyScore: score.clamp(0.0, 1.0),
      flags: List.unmodifiable(flags),
    );
  }

  List<String> _settingTerms(WorldSetting setting) {
    final rawTerms = <String>[
      ...setting.allNames,
      ..._splitTerms(setting.rules),
      ..._splitTerms(setting.factions),
      ..._splitTerms(setting.geography),
      ..._splitTerms(setting.techLevel),
    ];
    return rawTerms.toSet().toList(growable: false);
  }

  List<String> _splitTerms(String text) {
    return text
        .split(RegExp(r'[\s,，、。；;：:\n]+'))
        .map((term) => term.trim())
        .where((term) => term.runes.length >= 2)
        .toList(growable: false);
  }

  List<double> _computeDriftPerSegment(
    List<Chapter> chapters,
    List<EntityConsistencyResult> results,
  ) {
    if (chapters.isEmpty || results.isEmpty) return List.filled(10, 0.0);

    final segmentCount = 10;
    return List.generate(segmentCount, (segmentIndex) {
      final start = segmentIndex * 10;
      if (start >= chapters.length) return 0.0;
      final end = min(start + 10, chapters.length);
      final segmentChapters = chapters.sublist(start, end);
      var mentions = 0;
      for (final result in results) {
        for (final chapter in segmentChapters) {
          if (chapter.documentContent.contains(result.entityName)) {
            mentions++;
          }
        }
      }
      final denominator = results.length * segmentChapters.length;
      return denominator == 0 ? 0.0 : (mentions / denominator).clamp(0.0, 1.0);
    }, growable: false);
  }
}
