import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';

/// Builds an in-memory [NameIndex] from character cards and world settings.
class NameIndexService extends Notifier<NameIndex> {
  @override
  NameIndex build() {
    final index = NameIndex();
    final characterRepository = ref.watch(characterCardRepositoryProvider).asData?.value;
    final settingRepository = ref.watch(worldSettingRepositoryProvider).asData?.value;
    final skillRepository = ref.watch(skillRepositoryProvider).asData?.value;

    if (characterRepository != null) {
      for (final card in characterRepository.getAll()) {
        index.addEntity(card.id, EntityType.character, card.allNames);
      }
    }

    if (settingRepository != null) {
      for (final setting in settingRepository.getAll()) {
        index.addEntity(setting.id, EntityType.setting, setting.allNames);
      }
    }

    if (skillRepository != null) {
      for (final skill in skillRepository.getAll()) {
        index.addEntity(skill.id, EntityType.skill, skill.allNames);
      }
    }

    return index;
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
