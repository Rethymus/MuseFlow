import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:museflow/features/templates/application/template_completion_service.dart';
import 'package:museflow/features/templates/application/template_draft.dart';

void main() {
  group('TemplateCompletionService', () {
    test(
      'fills blank fields with structured JSON and preserves existing values',
      () async {
        final service = TemplateCompletionService(
          completionStream: (_) => Stream.value(
            jsonEncode({
              'world': {'description': 'AI世界描述', 'rules': '不应覆盖'},
              'characters': [
                {
                  'draftId': 'character-0',
                  'personality': 'AI性格',
                  'backstory': '不应覆盖',
                },
              ],
            }),
          ),
        );

        final result = await service.completeBlankFields(_draft());

        expect(result.succeeded, isTrue);
        expect(result.draft.world.description.value, 'AI世界描述');
        expect(
          result.draft.world.description.source,
          TemplateFieldSource.aiCompleted,
        );
        expect(result.draft.world.rules.value, '模板规则');
        expect(result.draft.characters.single.personality.value, 'AI性格');
        expect(result.draft.characters.single.backstory.value, '用户背景');
      },
    );

    test('invalid JSON preserves original draft', () async {
      final draft = _draft();
      final service = TemplateCompletionService(
        completionStream: (_) => Stream.value('not json'),
      );

      final result = await service.completeBlankFields(draft);

      expect(result.succeeded, isFalse);
      expect(result.draft, same(draft));
      expect(result.errorMessage, isNotEmpty);
    });
  });
}

TemplateDraft _draft() {
  return TemplateDraft(
    templateId: 'template-1',
    storyConcept: '概念',
    world: WorldSettingDraft(
      selected: true,
      name: const DraftTextField(
        value: '模板世界',
        source: TemplateFieldSource.templateDefault,
      ),
      description: const DraftTextField(
        value: '',
        source: TemplateFieldSource.templateDefault,
      ),
      rules: const DraftTextField(
        value: '模板规则',
        source: TemplateFieldSource.templateDefault,
      ),
      factions: const DraftTextField(
        value: '',
        source: TemplateFieldSource.templateDefault,
      ),
      geography: const DraftTextField(
        value: '',
        source: TemplateFieldSource.templateDefault,
      ),
      techLevel: const DraftTextField(
        value: '',
        source: TemplateFieldSource.templateDefault,
      ),
      aliases: const DraftTextField(
        value: '',
        source: TemplateFieldSource.templateDefault,
      ),
    ),
    characters: const [
      CharacterCardDraft(
        draftId: 'character-0',
        selected: true,
        name: DraftTextField(
          value: '角色',
          source: TemplateFieldSource.templateDefault,
        ),
        personality: DraftTextField(
          value: '',
          source: TemplateFieldSource.templateDefault,
        ),
        appearance: DraftTextField(
          value: '',
          source: TemplateFieldSource.templateDefault,
        ),
        backstory: DraftTextField(
          value: '用户背景',
          source: TemplateFieldSource.userEdited,
        ),
        aliases: DraftTextField(
          value: '',
          source: TemplateFieldSource.templateDefault,
        ),
      ),
    ],
  );
}
