import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'character_model.dart';
import 'character_service.dart';

/// 角色表单屏幕
class CharacterFormScreen extends StatefulWidget {
  final CharacterModel? character;

  const CharacterFormScreen({Key? key, this.character}) : super(key: key);

  @override
  State<CharacterFormScreen> createState() => _CharacterFormScreenState();
}

class _CharacterFormScreenState extends State<CharacterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _appearanceController;
  late final TextEditingController _personalityController;
  late final TextEditingController _backgroundController;
  late final TextEditingController _speakingStyleController;
  late final TextEditingController _notesController;
  final List<String> _relationships = [];
  final List<String> _tags = [];
  final TextEditingController _relationshipController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character?.name ?? '');
    _ageController =
        TextEditingController(text: widget.character?.age?.toString() ?? '');
    _appearanceController =
        TextEditingController(text: widget.character?.appearance ?? '');
    _personalityController =
        TextEditingController(text: widget.character?.personality ?? '');
    _backgroundController =
        TextEditingController(text: widget.character?.background ?? '');
    _speakingStyleController =
        TextEditingController(text: widget.character?.speakingStyle ?? '');
    _notesController =
        TextEditingController(text: widget.character?.notes ?? '');
    if (widget.character != null) {
      _relationships.addAll(widget.character!.relationships);
      _tags.addAll(widget.character!.tags);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _appearanceController.dispose();
    _personalityController.dispose();
    _backgroundController.dispose();
    _speakingStyleController.dispose();
    _notesController.dispose();
    _relationshipController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addRelationship() {
    if (_relationshipController.text.isNotEmpty) {
      setState(() {
        _relationships.add(_relationshipController.text);
        _relationshipController.clear();
      });
    }
  }

  void _removeRelationship(int index) {
    setState(() {
      _relationships.removeAt(index);
    });
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<CharacterService>();

      final age = _ageController.text.isNotEmpty
          ? int.tryParse(_ageController.text)
          : null;

      if (widget.character != null) {
        // 更新现有角色
        final updated = widget.character!.copyWith(
          name: _nameController.text,
          age: age,
          appearance: _appearanceController.text,
          personality: _personalityController.text,
          background: _backgroundController.text,
          speakingStyle: _speakingStyleController.text,
          relationships: _relationships,
          tags: _tags,
          notes: _notesController.text,
        );
        await service.updateCharacter(updated);
      } else {
        // 创建新角色
        await service.createCharacter(
          name: _nameController.text,
          age: age,
          appearance: _appearanceController.text,
          personality: _personalityController.text,
          background: _backgroundController.text,
          speakingStyle: _speakingStyleController.text,
          relationships: _relationships,
          tags: _tags,
          notes: _notesController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.character != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑角色' : '创建角色'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基本信息
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入姓名' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: '年龄',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // 详细信息
            TextFormField(
              controller: _appearanceController,
              decoration: const InputDecoration(
                labelText: '外貌',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _personalityController,
              decoration: const InputDecoration(
                labelText: '性格',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _backgroundController,
              decoration: const InputDecoration(
                labelText: '背景',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _speakingStyleController,
              decoration: const InputDecoration(
                labelText: '说话风格',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 人际关系
            const Text('人际关系', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _relationshipController,
                    decoration: const InputDecoration(
                      hintText: '添加关系',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addRelationship(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRelationship,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._relationships.map((rel) => ListTile(
                  title: Text(rel),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        _removeRelationship(_relationships.indexOf(rel)),
                  ),
                )),

            const SizedBox(height: 16),

            // 标签
            const Text('标签', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(_tags.indexOf(tag)),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}
