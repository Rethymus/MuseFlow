import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:museflow/core/domain/fragment.dart';

Future<void> openTemporaryHiveWorkspace() async {
  Uint8List emptyBox() => Uint8List(0);
  await Hive.openBox<Fragment>('fragments', bytes: emptyBox());
  for (final name in const [
    'settings',
    'manuscripts',
    'chapters',
    'chapter_summaries',
    'character_cards',
    'world_settings',
    'skill_documents',
    'foreshadowing_entries',
    'plot_nodes',
    'guardian_annotations',
    'token_audit',
    'ai_providers',
    'writing_stats',
    'daily_writing_stats',
    'achievement_badges',
    'character_relationships',
    'graph_positions',
    'style_profiles',
  ]) {
    await Hive.openBox<dynamic>(name, bytes: emptyBox());
  }
}
