// ignore_for_file: prefer_initializing_formals

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
  }) : _characterCardRepository = characterCardRepository,
       _worldSettingRepository = worldSettingRepository,
       _skillRepository = skillRepository,
       _chapterRepository = chapterRepository,
       _nameIndex = nameIndex;

  final CharacterCardRepository _characterCardRepository;
  final WorldSettingRepository _worldSettingRepository;
  final SkillRepository _skillRepository;
  final ChapterRepository _chapterRepository;
  final NameIndex _nameIndex;

  static const List<String> _sensoryTerms = [
    '看',
    '望',
    '听',
    '声',
    '闻',
    '气息',
    '冷',
    '热',
    '痛',
    '触',
    '光',
    '影',
    '风',
    '雨',
    '血',
    '尘',
    '香',
  ];

  static const List<String> _actionTerms = [
    '走',
    '踏',
    '握',
    '抬',
    '落',
    '斩',
    '退',
    '冲',
    '停',
    '转身',
    '低声',
    '皱眉',
    '沉默',
  ];

  static const List<String> _characterAnchorTerms = [
    '说',
    '问',
    '笑',
    '怒',
    '怕',
    '想',
    '记得',
    '低声',
    '沉默',
    '眼神',
    '心中',
    '师父',
    '同门',
    '敌',
    '友',
  ];

  static const List<String> _aiScentTerms = [
    '值得注意的是',
    '总而言之',
    '需要指出的是',
    '不可否认',
    '与此同时',
    '在这个过程中',
    '显而易见',
    '综上所述',
  ];

  ConsistencyReport analyze([String? manuscriptId]) {
    final chapters = _loadChapters(manuscriptId);
    final characters = _characterCardRepository.getAll();
    final settings = _worldSettingRepository.getAll();
    final skills = _skillRepository.getAll();

    if (chapters.isEmpty ||
        (characters.isEmpty && settings.isEmpty && skills.isEmpty)) {
      return ConsistencyReport(
        characterResults: const [],
        settingResults: const [],
        overallConsistencyScore: 0.0,
        driftPerSegment: List.filled(10, 0.0),
        narrativeQuality: const NarrativeQualitySnapshot.empty(),
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
        : allResults
                  .map((result) => result.consistencyScore)
                  .reduce((a, b) => a + b) /
              allResults.length;

    return ConsistencyReport(
      characterResults: characterResults,
      settingResults: settingResults,
      overallConsistencyScore: overall.clamp(0.0, 1.0),
      driftPerSegment: _computeDriftPerSegment(chapters, allResults),
      narrativeQuality: _analyzeNarrativeQuality(
        chapters: chapters,
        characters: characters,
        settings: settings,
      ),
    );
  }

  List<Chapter> _loadChapters(String? manuscriptId) {
    final chapters =
        (manuscriptId == null || manuscriptId.isEmpty
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
      _nameIndex.addEntity(
        character.id,
        character.entityType,
        character.allNames,
      );
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

  NarrativeQualitySnapshot _analyzeNarrativeQuality({
    required List<Chapter> chapters,
    required List<CharacterCard> characters,
    required List<WorldSetting> settings,
  }) {
    if (chapters.isEmpty) return const NarrativeQualitySnapshot.empty();

    final signals = <NarrativeQualitySignal>[];
    var immersiveChapters = 0;
    var anchoredMentions = 0;
    var totalCharacterMentions = 0;
    var aiScentHits = 0;

    for (var index = 0; index < chapters.length; index++) {
      final chapter = chapters[index];
      final text = chapter.documentContent;
      final sensoryCount = _countTerms(text, _sensoryTerms);
      final actionCount = _countTerms(text, _actionTerms);
      final isImmersive = sensoryCount + actionCount >= 2;
      if (isImmersive) {
        immersiveChapters++;
      } else {
        signals.add(
          NarrativeQualitySignal(
            chapterIndex: index,
            category: 'immersion',
            title: '场景沉浸线索偏弱',
            evidence: '感官词 $sensoryCount 个，动作词 $actionCount 个',
            suggestion: '复查本章是否有具体动作、环境细节或身体感受承载情绪。',
            severity: DeviationSeverity.medium,
          ),
        );
      }

      final chapterAiHits = _matchedTerms(text, _aiScentTerms);
      if (chapterAiHits.isNotEmpty) {
        aiScentHits += chapterAiHits.length;
        signals.add(
          NarrativeQualitySignal(
            chapterIndex: index,
            category: 'style',
            title: '疑似模板化 AI 表达',
            evidence: chapterAiHits.take(3).join('、'),
            suggestion: '将说明式连接词改成角色动作、场景变化或直接叙事推进。',
            severity: DeviationSeverity.medium,
          ),
        );
      }

      for (final character in characters) {
        if (!character.allNames.any(text.contains)) continue;
        totalCharacterMentions++;
        final anchorCount = _countTerms(text, _characterAnchorTerms);
        if (anchorCount > 0) {
          anchoredMentions++;
        } else {
          signals.add(
            NarrativeQualitySignal(
              chapterIndex: index,
              category: 'character',
              title: '${character.name} 缺少人设锚点',
              evidence: '出现角色名，但未检测到动作、情绪、关系或语气线索',
              suggestion: '复查该角色在本章是否有符合人设的选择、反应或说话方式。',
              severity: DeviationSeverity.clear,
            ),
          );
        }
      }
    }

    signals.addAll(_settingDriftSignals(chapters, settings));

    signals.sort((a, b) {
      final severityCompare = _severityRank(
        b.severity,
      ).compareTo(_severityRank(a.severity));
      if (severityCompare != 0) return severityCompare;
      return a.chapterIndex.compareTo(b.chapterIndex);
    });

    final immersionScore = immersiveChapters / chapters.length;
    final characterAnchoringScore = totalCharacterMentions == 0
        ? 1.0
        : anchoredMentions / totalCharacterMentions;
    final antiAiScentScore = (1 - (aiScentHits / chapters.length)).clamp(
      0.0,
      1.0,
    );

    return NarrativeQualitySnapshot(
      immersionScore: immersionScore.clamp(0.0, 1.0),
      characterAnchoringScore: characterAnchoringScore.clamp(0.0, 1.0),
      antiAiScentScore: antiAiScentScore,
      signals: List.unmodifiable(signals.take(24)),
    );
  }

  List<NarrativeQualitySignal> _settingDriftSignals(
    List<Chapter> chapters,
    List<WorldSetting> settings,
  ) {
    final signals = <NarrativeQualitySignal>[];
    for (final setting in settings) {
      final supportTerms = _settingTerms(
        setting,
      ).where((term) => term != setting.name).toList(growable: false);
      if (supportTerms.isEmpty) continue;

      var unsupportedRun = 0;
      for (var index = 0; index < chapters.length; index++) {
        final text = chapters[index].documentContent;
        if (!setting.allNames.any(text.contains)) {
          unsupportedRun = 0;
          continue;
        }
        final hasSupport = supportTerms.any(text.contains);
        if (hasSupport) {
          unsupportedRun = 0;
          continue;
        }
        unsupportedRun++;
        if (unsupportedRun >= 2) {
          signals.add(
            NarrativeQualitySignal(
              chapterIndex: index,
              category: 'setting',
              title: '${setting.name} 设定支撑不足',
              evidence: '连续 $unsupportedRun 次只出现设定名，缺少规则/势力/地理等支撑词',
              suggestion: '复查该设定是否仍在推动冲突、限制行动或影响场景，而不只是被点名。',
              severity: DeviationSeverity.medium,
            ),
          );
        }
      }
    }
    return signals;
  }

  int _countTerms(String text, List<String> terms) {
    return terms.where(text.contains).length;
  }

  List<String> _matchedTerms(String text, List<String> terms) {
    return terms.where(text.contains).toList(growable: false);
  }

  int _severityRank(DeviationSeverity severity) {
    return switch (severity) {
      DeviationSeverity.clear => 3,
      DeviationSeverity.medium => 2,
      DeviationSeverity.low => 1,
    };
  }
}
