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

    test('stream error preserves original draft and returns failure', () async {
      final draft = _draft();
      final service = TemplateCompletionService(
        completionStream: (_) => Stream.error(Exception('network failure')),
      );

      final result = await service.completeBlankFields(draft);

      expect(result.succeeded, isFalse);
      expect(result.draft, same(draft));
      expect(result.errorMessage, isNotEmpty);
      expect(result.errorMessage, contains('network failure'));
    });

    test('aiCompleted source applied to blank fields while templateDefault preserved', () async {
      final service = TemplateCompletionService(
        completionStream: (_) => Stream.value(
          jsonEncode({
            'world': {
              'name': '新世界名',
              'description': 'AI生成描述',
              'rules': 'AI生成规则',
              'factions': 'AI生成势力',
              'geography': 'AI生成地理',
              'techLevel': 'AI生成技术',
              'aliases': '别名',
            },
            'characters': [
              {
                'draftId': 'character-0',
                'name': '新角色名',
                'personality': 'AI性格',
                'appearance': 'AI外貌',
                'backstory': 'AI背景',
                'aliases': '别名',
              },
            ],
          }),
        ),
      );

      final result = await service.completeBlankFields(_draft());

      expect(result.succeeded, isTrue);

      // World name was '模板世界' (non-empty) so aiFill should NOT overwrite it
      expect(result.draft.world.name.value, '模板世界');
      expect(
        result.draft.world.name.source,
        TemplateFieldSource.templateDefault,
      );

      // World description was '' (blank) so aiFill should fill it
      expect(result.draft.world.description.value, 'AI生成描述');
      expect(
        result.draft.world.description.source,
        TemplateFieldSource.aiCompleted,
      );

      // World rules was '模板规则' (non-empty) so aiFill preserves
      expect(result.draft.world.rules.value, '模板规则');
      expect(
        result.draft.world.rules.source,
        TemplateFieldSource.templateDefault,
      );

      // Character backstory was '用户背景' (userEdited) so aiFill must not touch it
      expect(result.draft.characters.single.backstory.value, '用户背景');
      expect(
        result.draft.characters.single.backstory.source,
        TemplateFieldSource.userEdited,
      );

      // Character personality was '' (blank) so aiFill fills it
      expect(result.draft.characters.single.personality.value, 'AI性格');
      expect(
        result.draft.characters.single.personality.source,
        TemplateFieldSource.aiCompleted,
      );
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
