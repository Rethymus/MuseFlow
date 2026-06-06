import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/templates/application/template_draft.dart';
import 'package:museflow/features/templates/domain/world_template.dart';

class TemplateInstantiationService {
  const TemplateInstantiationService({
    required this.worldSettingRepository,
    required this.characterCardRepository,
    required this.chapterRepository,
  });

  final WorldSettingRepository worldSettingRepository;
  final CharacterCardRepository characterCardRepository;
  final ChapterRepository chapterRepository;

  TemplateDraft createDraft(
    WorldTemplate template, {
    String storyConcept = '',
  }) {
    return TemplateDraft(
      templateId: template.id,
      storyConcept: storyConcept,
      world: WorldSettingDraft(
        selected: true,
        name: _templateField(template.world.name),
        description: _templateField(template.world.description),
        rules: _templateField(template.world.rules),
        factions: _templateField(template.world.factions),
        geography: _templateField(template.world.geography),
        techLevel: _templateField(template.world.techLevel),
        aliases: _templateField(template.world.aliases.join('，')),
      ),
      characters: [
        for (var i = 0; i < template.characters.length; i++)
          CharacterCardDraft(
            draftId: 'character-$i',
            selected: true,
            name: _templateField(template.characters[i].name),
            personality: _templateField(template.characters[i].personality),
            appearance: _templateField(template.characters[i].appearance),
            backstory: _templateField(template.characters[i].backstory),
            aliases: _templateField(template.characters[i].aliases.join('，')),
          ),
      ],
    );
  }

  Future<TemplateCreationResult> saveDraft(TemplateDraft draft) async {
    final createdWorld = draft.world.selected
        ? await worldSettingRepository.add(draft.world.toWorldSetting())
        : null;

    final createdCharacters = <dynamic>[];
    for (final character in draft.characters) {
      if (!character.selected) continue;
      createdCharacters.add(
        await characterCardRepository.add(character.toCharacterCard()),
      );
    }

    // Create chapter skeleton entities when manuscriptId is provided
    final createdChapters = <Chapter>[];
    if (draft.manuscriptId != null && draft.chapterTitles.isNotEmpty) {
      for (var i = 0; i < draft.chapterTitles.length; i++) {
        final chapter = await chapterRepository.add(Chapter(
          id: '',
          manuscriptId: draft.manuscriptId!,
          title: draft.chapterTitles[i],
          sortOrder: i,
          status: '草稿',
          documentContent: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
        createdChapters.add(chapter);
      }
    }

    return TemplateCreationResult(
      worldSetting: createdWorld,
      characterCards: createdCharacters.cast(),
      chapters: createdChapters,
    );
  }

  DraftTextField _templateField(String value) {
    return DraftTextField(
      value: value,
      source: TemplateFieldSource.templateDefault,
    );
  }
}
