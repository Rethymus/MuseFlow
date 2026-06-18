/// MuseFlow core presentation providers library.
///
/// Split across 5 part files (providers_core/ai/knowledge/structure/stats.dart)
/// to satisfy the 03-flutter-standards.md file-size cap. All providers live
/// in the same library — consumers import this file unchanged.
library;

import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:museflow/core/domain/fragment.dart';
import 'package:museflow/core/infrastructure/fragment_repository.dart';
import 'package:museflow/core/infrastructure/secure_storage_service.dart';
import 'package:museflow/core/infrastructure/settings_repository.dart';
import 'package:museflow/core/platform/export_file_writer.dart';
import 'package:museflow/features/ai/application/anti_ai_scent_processor.dart';
import 'package:museflow/features/ai/application/prompt_pipeline.dart';
import 'package:museflow/features/ai/application/provider_service.dart';
import 'package:museflow/features/ai/application/token_budget_calculator.dart';
import 'package:museflow/features/ai/domain/ai_adapter.dart';
import 'package:museflow/features/ai/domain/ai_provider.dart';
import 'package:museflow/features/ai/domain/creativity_level.dart';
import 'package:museflow/features/ai/infrastructure/claude_adapter.dart';
import 'package:museflow/features/ai/infrastructure/openai_adapter.dart';
import 'package:museflow/features/ai/infrastructure/provider_repository.dart';
import 'package:museflow/features/editor/application/diff_calculator.dart';
import 'package:museflow/features/editor/application/editor_chapter_memory_context_builder.dart';
import 'package:museflow/features/editor/application/editor_prompt_pipeline.dart';
import 'package:museflow/features/editor/application/selective_undo.dart';
import 'package:museflow/features/knowledge/application/character_card_notifier.dart';
import 'package:museflow/features/knowledge/application/character_relationship_notifier.dart';
import 'package:museflow/features/knowledge/application/deviation_detection_service.dart';
import 'package:museflow/features/knowledge/application/knowledge_injection_middleware.dart';
import 'package:museflow/features/reports/application/editorial_review_service.dart';
import 'package:museflow/features/knowledge/application/name_index_service.dart';
import 'package:museflow/features/knowledge/application/skill_enforcement_middleware.dart';
import 'package:museflow/features/knowledge/application/skill_generation_service.dart';
import 'package:museflow/features/knowledge/application/skill_notifier.dart';
import 'package:museflow/features/knowledge/application/world_setting_notifier.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';
import 'package:museflow/features/knowledge/domain/skill_document.dart';
import 'package:museflow/features/knowledge/domain/world_setting.dart';
import 'package:museflow/features/knowledge/infrastructure/character_card_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/character_relationship_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/name_index.dart';
import 'package:museflow/features/knowledge/infrastructure/skill_repository.dart';
import 'package:museflow/features/knowledge/infrastructure/world_setting_repository.dart';
import 'package:museflow/features/onboarding/infrastructure/onboarding_progress_repository.dart';
import 'package:museflow/features/onboarding/application/opening_generator_service.dart';
import 'package:museflow/features/stats/application/writing_stats_collector.dart';
import 'package:museflow/features/stats/application/writing_stats_notifier.dart';
import 'package:museflow/features/stats/application/achievement_notifier.dart';
import 'package:museflow/features/stats/application/achievement_service.dart';
import 'package:museflow/features/stats/application/token_audit_notifier.dart';
import 'package:museflow/features/stats/application/token_audit_service.dart';
import 'package:museflow/features/stats/domain/achievement_badge.dart';
import 'package:museflow/features/stats/domain/stats_snapshot.dart';
import 'package:museflow/features/stats/infrastructure/writing_stats_repository.dart';
import 'package:museflow/features/stats/infrastructure/token_audit_repository.dart';
import 'package:museflow/features/manuscript/application/chapter_auto_save.dart';
import 'package:museflow/features/manuscript/application/chapter_notifier.dart';
import 'package:museflow/features/manuscript/application/manuscript_notifier.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/chapter_summary_repository.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_purge_service.dart';
import 'package:museflow/features/manuscript/infrastructure/manuscript_repository.dart';
import 'package:museflow/features/manuscript/domain/manuscript.dart';
import 'package:museflow/features/manuscript/domain/chapter.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_notifier.dart';
import 'package:museflow/features/story_structure/application/foreshadowing_reminder_service.dart';
import 'package:museflow/features/story_structure/application/guardian_check_service.dart';
import 'package:museflow/features/story_structure/application/guardian_context_builder.dart';
import 'package:museflow/features/story_structure/application/guardian_notifier.dart';
import 'package:museflow/features/story_structure/application/logic_guardian_service.dart';
import 'package:museflow/features/story_structure/application/node_position_notifier.dart';
import 'package:museflow/features/story_structure/application/plot_node_notifier.dart';
import 'package:museflow/features/story_structure/application/export_service.dart';
import 'package:museflow/features/story_structure/domain/foreshadowing_entry.dart';
import 'package:museflow/features/story_structure/domain/plot_node.dart';
import 'package:museflow/features/story_structure/infrastructure/foreshadowing_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/guardian_annotation_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/node_position_repository.dart';
import 'package:museflow/features/story_structure/infrastructure/plot_node_repository.dart';
import 'package:museflow/features/templates/application/template_completion_service.dart';
import 'package:museflow/features/templates/application/template_instantiation_service.dart';
import 'package:museflow/features/templates/infrastructure/world_template_repository.dart';
import 'package:museflow/features/editor/infrastructure/style_profile_repository.dart';

export 'package:museflow/features/editor/application/context_anchor_notifier.dart'
    show contextAnchorNotifierProvider, ContextAnchorNotifier;
export 'package:museflow/features/editor/presentation/editor_page.dart'
    show editorProvider;
export 'package:museflow/features/editor/application/editor_ai_notifier.dart'
    show editorAINotifierProvider, EditorAINotifier;

part 'providers_core.dart';
part 'providers_ai.dart';
part 'providers_knowledge.dart';
part 'providers_structure.dart';
part 'providers_stats.dart';
