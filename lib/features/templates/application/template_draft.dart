import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';

enum TemplateFieldSource { templateDefault, aiCompleted, userEdited }

class DraftTextField {
  const DraftTextField({required this.value, required this.source});

  final String value;
  final TemplateFieldSource source;

  DraftTextField copyWith({String? value, TemplateFieldSource? source}) {
    return DraftTextField(
      value: value ?? this.value,
      source: source ?? this.source,
    );
  }

  DraftTextField edit(String value) {
    return DraftTextField(value: value, source: TemplateFieldSource.userEdited);
  }

  DraftTextField aiFill(String value) {
    if (source == TemplateFieldSource.userEdited ||
        this.value.trim().isNotEmpty) {
      return this;
    }
    return DraftTextField(
      value: value,
      source: TemplateFieldSource.aiCompleted,
    );
  }
}

class WorldSettingDraft {
  const WorldSettingDraft({
    required this.selected,
    required this.name,
    required this.description,
    required this.rules,
    required this.factions,
    required this.geography,
    required this.techLevel,
    required this.aliases,
  });

  final bool selected;
  final DraftTextField name;
  final DraftTextField description;
  final DraftTextField rules;
  final DraftTextField factions;
  final DraftTextField geography;
  final DraftTextField techLevel;
  final DraftTextField aliases;

  WorldSettingDraft copyWith({
    bool? selected,
    DraftTextField? name,
    DraftTextField? description,
    DraftTextField? rules,
    DraftTextField? factions,
    DraftTextField? geography,
    DraftTextField? techLevel,
    DraftTextField? aliases,
  }) {
    return WorldSettingDraft(
      selected: selected ?? this.selected,
      name: name ?? this.name,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      factions: factions ?? this.factions,
      geography: geography ?? this.geography,
      techLevel: techLevel ?? this.techLevel,
      aliases: aliases ?? this.aliases,
    );
  }

  WorldSetting toWorldSetting() {
    return WorldSetting(
      id: '',
      name: name.value,
      description: description.value,
      rules: rules.value,
      factions: factions.value,
      geography: geography.value,
      techLevel: techLevel.value,
      aliases: _splitAliases(aliases.value),
      createdAt: DateTime.now(),
    );
  }
}

class CharacterCardDraft {
  const CharacterCardDraft({
    required this.draftId,
    required this.selected,
    required this.name,
    required this.personality,
    required this.appearance,
    required this.backstory,
    required this.aliases,
  });

  final String draftId;
  final bool selected;
  final DraftTextField name;
  final DraftTextField personality;
  final DraftTextField appearance;
  final DraftTextField backstory;
  final DraftTextField aliases;

  CharacterCardDraft copyWith({
    bool? selected,
    DraftTextField? name,
    DraftTextField? personality,
    DraftTextField? appearance,
    DraftTextField? backstory,
    DraftTextField? aliases,
  }) {
    return CharacterCardDraft(
      draftId: draftId,
      selected: selected ?? this.selected,
      name: name ?? this.name,
      personality: personality ?? this.personality,
      appearance: appearance ?? this.appearance,
      backstory: backstory ?? this.backstory,
      aliases: aliases ?? this.aliases,
    );
  }

  CharacterCard toCharacterCard() {
    return CharacterCard(
      id: '',
      name: name.value,
      personality: personality.value,
      appearance: appearance.value,
      backstory: backstory.value,
      aliases: _splitAliases(aliases.value),
      createdAt: DateTime.now(),
    );
  }
}

class TemplateDraft {
  const TemplateDraft({
    required this.templateId,
    required this.storyConcept,
    required this.world,
    required this.characters,
    this.manuscriptId,
    this.chapterTitles = const ['世界观铺垫', '角色登场', '主线开启'],
  });

  final String templateId;
  final String storyConcept;
  final WorldSettingDraft world;
  final List<CharacterCardDraft> characters;

  /// Optional manuscript ID to associate chapter skeletons with.
  final String? manuscriptId;

  /// Chapter titles to create as skeleton entities when saving.
  /// Defaults to genre-appropriate titles per D-20.
  final List<String> chapterTitles;

  TemplateDraft copyWith({
    String? storyConcept,
    WorldSettingDraft? world,
    List<CharacterCardDraft>? characters,
    String? manuscriptId,
    List<String>? chapterTitles,
  }) {
    return TemplateDraft(
      templateId: templateId,
      storyConcept: storyConcept ?? this.storyConcept,
      world: world ?? this.world,
      characters: characters ?? this.characters,
      manuscriptId: manuscriptId ?? this.manuscriptId,
      chapterTitles: chapterTitles ?? this.chapterTitles,
    );
  }
}

class TemplateCreationResult {
  const TemplateCreationResult({
    this.worldSetting,
    required this.characterCards,
    this.chapters = const [],
  });

  final WorldSetting? worldSetting;
  final List<CharacterCard> characterCards;

  /// Chapter skeleton entities created when manuscriptId was provided.
  final List<Chapter> chapters;
}

List<String> _splitAliases(String value) {
  return value
      .split(RegExp(r'[,，\n]'))
      .map((alias) => alias.trim())
      .where((alias) => alias.isNotEmpty)
      .toList();
}
