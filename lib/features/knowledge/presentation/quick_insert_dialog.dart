import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/entity_type.dart';
import 'package:museflow/features/knowledge/domain/knowledge_entity.dart';
import 'package:super_editor/super_editor.dart';

class QuickInsertDialog extends ConsumerStatefulWidget {
  const QuickInsertDialog({super.key});

  @override
  ConsumerState<QuickInsertDialog> createState() => _QuickInsertDialogState();
}

class _QuickInsertDialogState extends ConsumerState<QuickInsertDialog> {
  final _searchController = TextEditingController();
  EntityType? _filterType;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _loadEntries(ref);
    final filtered = _filter(entries);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (filtered.isNotEmpty) _insert(filtered.first.entity);
        },
      },
      child: AlertDialog(
        title: const Text('插入知识引用'),
        content: SizedBox(
          width: 520,
          height: 440,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '搜索角色、世界观或模板...',
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _filterType == null,
                    onSelected: (_) => setState(() => _filterType = null),
                  ),
                  for (final type in EntityType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      selected: _filterType == type,
                      onSelected: (_) => setState(() => _filterType = type),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('没有找到匹配的知识库条目'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return ListTile(
                            title: Text(entry.entity.displayName),
                            subtitle: Text(
                              entry.entity.toContextString.replaceAll(
                                '\n',
                                ' ',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Chip(label: Text(entry.type.label)),
                            onTap: () => _insert(entry.entity),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_KnowledgeEntry> _loadEntries(WidgetRef ref) {
    final entries = <_KnowledgeEntry>[];
    final characters =
        ref.watch(characterCardNotifierProvider).asData?.value ?? const [];
    final settings =
        ref.watch(worldSettingNotifierProvider).asData?.value ?? const [];
    final skills =
        ref.watch(skillListNotifierProvider).asData?.value ?? const [];
    entries.addAll(
      characters.map((entity) => _KnowledgeEntry(entity, EntityType.character)),
    );
    entries.addAll(
      settings.map((entity) => _KnowledgeEntry(entity, EntityType.setting)),
    );
    entries.addAll(
      skills.map((entity) => _KnowledgeEntry(entity, EntityType.skill)),
    );
    return entries;
  }

  List<_KnowledgeEntry> _filter(List<_KnowledgeEntry> entries) {
    final query = _query.toLowerCase();
    final filtered = entries.where((entry) {
      if (_filterType != null && entry.type != _filterType) return false;
      if (query.isEmpty) return true;
      return entry.entity.allNames.any(
        (name) => name.toLowerCase().contains(query),
      );
    }).toList();

    filtered.sort((a, b) {
      final aExact = a.entity.allNames.any(
        (name) => name.toLowerCase() == query,
      );
      final bExact = b.entity.allNames.any(
        (name) => name.toLowerCase() == query,
      );
      if (aExact != bExact) return aExact ? -1 : 1;
      return a.entity.displayName.length.compareTo(b.entity.displayName.length);
    });
    return filtered;
  }

  void _insert(KnowledgeEntity entity) {
    final editor = ref.read(editorProvider);
    final selection = editor?.composer.selection;
    if (editor == null || selection == null) {
      Navigator.of(context).pop();
      return;
    }

    final position = selection.extent;
    if (!selection.isCollapsed) {
      editor.execute([DeleteContentRequest(documentRange: selection)]);
    }
    editor.execute([
      InsertTextRequest(
        documentPosition: position,
        textToInsert: entity.displayName,
        attributions: {},
      ),
    ]);
    Navigator.of(context).pop();
  }
}

class _KnowledgeEntry {
  final KnowledgeEntity entity;
  final EntityType type;

  const _KnowledgeEntry(this.entity, this.type);
}
