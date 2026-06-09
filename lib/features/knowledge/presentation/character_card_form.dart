import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/knowledge/domain/character_card.dart';

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
