import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';
import 'package:museflow/features/knowledge/domain/character_relationship.dart';
import 'package:uuid/uuid.dart';

/// Form for creating or editing a [CharacterCard].
///
/// Provide [cardId] for edit mode (looks up from notifier state),
/// or omit it for create mode.
class CharacterCardForm extends ConsumerStatefulWidget {
  final String? cardId;

  const CharacterCardForm({super.key, this.cardId});

  @override
  ConsumerState<CharacterCardForm> createState() => _CharacterCardFormState();
}

class _CharacterCardFormState extends ConsumerState<CharacterCardForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _personalityController;
  late final TextEditingController _appearanceController;
  late final TextEditingController _backstoryController;
  late final TextEditingController _aliasesController;
  bool _isSaving = false;

  bool get _isEditing => widget.cardId != null;

  CharacterCard? _findCard(List<CharacterCard> cards) {
    if (widget.cardId == null) return null;
    try {
      return cards.firstWhere((c) => c.id == widget.cardId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _personalityController = TextEditingController();
    _appearanceController = TextEditingController();
    _backstoryController = TextEditingController();
    _aliasesController = TextEditingController();

    // Seed controllers from notifier state if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedFromExisting();
    });
  }

  void _seedFromExisting() {
    final cards = ref.read(characterCardNotifierProvider).asData?.value ?? [];
    final card = _findCard(cards);
    if (card != null) {
      _nameController.text = card.name;
      _personalityController.text = card.personality;
      _appearanceController.text = card.appearance;
      _backstoryController.text = card.backstory;
      _aliasesController.text = card.aliases.join(', ');
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _personalityController.dispose();
    _appearanceController.dispose();
    _backstoryController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑角色卡' : '新建角色卡')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称 *',
                hintText: '角色名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入角色名称';
                }
                if (value.trim().length > 100) {
                  return '名称不能超过100个字符';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _personalityController,
              decoration: const InputDecoration(
                labelText: '性格',
                hintText: '角色的性格特征',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _appearanceController,
              decoration: const InputDecoration(
                labelText: '外貌',
                hintText: '角色的外貌描述',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _backstoryController,
              decoration: const InputDecoration(
                labelText: '背景故事',
                hintText: '角色的背景经历',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 5000,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aliasesController,
              decoration: const InputDecoration(
                labelText: '别名',
                hintText: '用逗号分隔，如：逍遥, 李大哥',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              _RelationshipsSection(cardId: widget.cardId!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? '保存修改' : '创建角色卡'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseAliases(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final aliases = _parseAliases(_aliasesController.text);
      final notifier = ref.read(characterCardNotifierProvider.notifier);

      if (_isEditing) {
        final cards =
            ref.read(characterCardNotifierProvider).asData?.value ?? [];
        final existing = _findCard(cards);
        if (existing == null) {
          throw StateError('Character card not found');
        }
        final updated = existing.copyWith(
          name: _nameController.text.trim(),
          personality: _personalityController.text.trim(),
          appearance: _appearanceController.text.trim(),
          backstory: _backstoryController.text.trim(),
          aliases: aliases,
        );
        await notifier.save(updated);
      } else {
        final card = CharacterCard(
          id: '',
          name: _nameController.text.trim(),
          personality: _personalityController.text.trim(),
          appearance: _appearanceController.text.trim(),
          backstory: _backstoryController.text.trim(),
          aliases: aliases,
          createdAt: DateTime.now(),
        );
        await notifier.add(card);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? '角色卡已更新' : '角色卡已创建')),
        );
        context.go('/knowledge');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Section for managing character relationships.
///
/// Per Phase 21 (KNOW-02): Displays existing relationships for a
/// character and provides a dialog for adding new relationships.
class _RelationshipsSection extends ConsumerWidget {
  final String cardId;

  const _RelationshipsSection({required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relsAsync = ref.watch(characterRelationshipNotifierProvider);
    final cardsAsync = ref.watch(characterCardNotifierProvider);

    return relsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (relationships) {
        final myRels = relationships
            .where((r) => r.fromCharacterId == cardId || r.toCharacterId == cardId)
            .toList();

        final otherCards = cardsAsync.asData?.value ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('角色关系',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (otherCards.length >= 2)
                  TextButton.icon(
                    onPressed: () => _showAddDialog(context, ref, otherCards),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('添加'),
                  ),
              ],
            ),
            if (myRels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '暂无关系记录',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              )
            else
              ...myRels.map((rel) => _RelationshipTile(
                    rel: rel,
                    cardId: cardId,
                    cards: otherCards,
                  )),
          ],
        );
      },
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    List<CharacterCard> cards,
  ) {
    final otherCards = cards.where((c) => c.id != cardId).toList();
    if (otherCards.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => _AddRelationshipDialog(
        fromId: cardId,
        otherCards: otherCards,
      ),
    );
  }
}

/// Tile displaying a single relationship with delete option.
class _RelationshipTile extends ConsumerWidget {
  final CharacterRelationship rel;
  final String cardId;
  final List<CharacterCard> cards;

  const _RelationshipTile({
    required this.rel,
    required this.cardId,
    required this.cards,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFrom = rel.fromCharacterId == cardId;
    final otherId = isFrom ? rel.toCharacterId : rel.fromCharacterId;
    final otherName = cards
        .where((c) => c.id == otherId)
        .map((c) => c.name)
        .firstOrNull ?? otherId;

    final prefix = isFrom ? '' : '';
    final suffix = isFrom ? '' : '';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            _typeIcon(rel.type),
            size: 16,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$prefix$otherName — ${rel.type.label}$suffix',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (rel.description.isNotEmpty)
            Flexible(
              child: Text(
                '（${rel.description}）',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref
                .read(characterRelationshipNotifierProvider.notifier)
                .delete(rel.id),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(RelationshipType type) {
    return switch (type) {
      RelationshipType.mentor => Icons.school,
      RelationshipType.enemy => Icons.shield,
      RelationshipType.family => Icons.family_restroom,
      RelationshipType.lover => Icons.favorite,
      RelationshipType.rival => Icons.emoji_events,
      RelationshipType.ally => Icons.handshake,
      RelationshipType.subordinate => Icons.corporate_fare,
      RelationshipType.friend => Icons.group,
    };
  }
}

/// Dialog for adding a new character relationship.
class _AddRelationshipDialog extends ConsumerStatefulWidget {
  final String fromId;
  final List<CharacterCard> otherCards;

  const _AddRelationshipDialog({
    required this.fromId,
    required this.otherCards,
  });

  @override
  ConsumerState<_AddRelationshipDialog> createState() =>
      _AddRelationshipDialogState();
}

class _AddRelationshipDialogState
    extends ConsumerState<_AddRelationshipDialog> {
  String? _selectedCharId;
  RelationshipType _selectedType = RelationshipType.friend;
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加角色关系'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCharId,
              decoration: const InputDecoration(
                labelText: '对方角色 *',
                border: OutlineInputBorder(),
              ),
              items: widget.otherCards
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCharId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: '关系类型',
                border: OutlineInputBorder(),
              ),
              items: RelationshipType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '补充说明关系细节',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedCharId == null) return;

    setState(() => _isSaving = true);

    try {
      final rel = CharacterRelationship(
        id: const Uuid().v4(),
        fromCharacterId: widget.fromId,
        toCharacterId: _selectedCharId!,
        type: _selectedType,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await ref
          .read(characterRelationshipNotifierProvider.notifier)
          .add(rel);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
