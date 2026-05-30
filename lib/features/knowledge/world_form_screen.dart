import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'world_model.dart';
import 'world_service.dart';
import 'location_form_dialog.dart';
import 'organization_form_dialog.dart';

/// 世界观表单屏幕
class WorldFormScreen extends StatefulWidget {
  final WorldModel? world;

  const WorldFormScreen({super.key, this.world});

  @override
  State<WorldFormScreen> createState() => _WorldFormScreenState();
}

class _WorldFormScreenState extends State<WorldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _worldTypeController;
  late final TextEditingController _eraController;
  late final TextEditingController _magicSystemController;
  late final TextEditingController _technologyController;
  late final TextEditingController _geographyController;
  late final TextEditingController _historyController;
  late final TextEditingController _notesController;
  final List<String> _rules = [];
  final List<String> _tags = [];
  final List<Location> _locations = [];
  final List<Organization> _organizations = [];
  final TextEditingController _ruleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.world?.name ?? '');
    _worldTypeController =
        TextEditingController(text: widget.world?.worldType ?? '奇幻');
    _eraController = TextEditingController(text: widget.world?.era ?? '');
    _magicSystemController =
        TextEditingController(text: widget.world?.magicSystem ?? '');
    _technologyController =
        TextEditingController(text: widget.world?.technology ?? '');
    _geographyController =
        TextEditingController(text: widget.world?.geography ?? '');
    _historyController =
        TextEditingController(text: widget.world?.history ?? '');
    _notesController = TextEditingController(text: widget.world?.notes ?? '');

    if (widget.world != null) {
      _rules.addAll(widget.world!.rules);
      _tags.addAll(widget.world!.tags);
      _locations.addAll(widget.world!.locations);
      _organizations.addAll(widget.world!.organizations);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _worldTypeController.dispose();
    _eraController.dispose();
    _magicSystemController.dispose();
    _technologyController.dispose();
    _geographyController.dispose();
    _historyController.dispose();
    _notesController.dispose();
    _ruleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addRule() {
    if (_ruleController.text.isNotEmpty) {
      setState(() {
        _rules.add(_ruleController.text);
        _ruleController.clear();
      });
    }
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
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

  void _addLocation() {
    showDialog(
      context: context,
      builder: (context) => LocationFormDialog(
        onSave: (location) {
          setState(() {
            _locations.add(location);
          });
        },
      ),
    );
  }

  void _editLocation(Location location) {
    showDialog(
      context: context,
      builder: (context) => LocationFormDialog(
        location: location,
        onSave: (updated) {
          setState(() {
            final index = _locations.indexWhere((l) => l.id == updated.id);
            if (index != -1) {
              _locations[index] = updated;
            }
          });
        },
      ),
    );
  }

  void _removeLocation(String id) {
    setState(() {
      _locations.removeWhere((l) => l.id == id);
    });
  }

  void _addOrganization() {
    showDialog(
      context: context,
      builder: (context) => OrganizationFormDialog(
        onSave: (org) {
          setState(() {
            _organizations.add(org);
          });
        },
      ),
    );
  }

  void _editOrganization(Organization org) {
    showDialog(
      context: context,
      builder: (context) => OrganizationFormDialog(
        organization: org,
        onSave: (updated) {
          setState(() {
            final index = _organizations.indexWhere((o) => o.id == updated.id);
            if (index != -1) {
              _organizations[index] = updated;
            }
          });
        },
      ),
    );
  }

  void _removeOrganization(String id) {
    setState(() {
      _organizations.removeWhere((o) => o.id == id);
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final service = context.read<WorldService>();

      if (widget.world != null) {
        // 更新现有世界观
        final updated = widget.world!.copyWith(
          name: _nameController.text,
          worldType: _worldTypeController.text,
          era: _eraController.text,
          magicSystem: _magicSystemController.text,
          technology: _technologyController.text,
          geography: _geographyController.text,
          history: _historyController.text,
          rules: _rules,
          tags: _tags,
          locations: _locations,
          organizations: _organizations,
          notes: _notesController.text,
        );
        await service.updateWorld(updated);
      } else {
        // 创建新世界观
        await service.createWorld(
          name: _nameController.text,
          worldType: _worldTypeController.text,
          era: _eraController.text,
          magicSystem: _magicSystemController.text,
          technology: _technologyController.text,
          geography: _geographyController.text,
          history: _historyController.text,
          rules: _rules,
          tags: _tags,
          locations: _locations,
          organizations: _organizations,
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
    final isEditing = widget.world != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑世界观' : '创建世界观'),
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
                labelText: '世界名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入世界名称' : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _worldTypeController,
              decoration: const InputDecoration(
                labelText: '世界类型',
                border: OutlineInputBorder(),
                hintText: '如：奇幻、科幻、现实、历史',
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _eraController,
              decoration: const InputDecoration(
                labelText: '时代',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // 系统设定
            TextFormField(
              controller: _magicSystemController,
              decoration: const InputDecoration(
                labelText: '魔法体系',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _technologyController,
              decoration: const InputDecoration(
                labelText: '科技水平',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // 环境和历史
            TextFormField(
              controller: _geographyController,
              decoration: const InputDecoration(
                labelText: '地理环境',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _historyController,
              decoration: const InputDecoration(
                labelText: '历史背景',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // 世界规则
            const Text('世界规则', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ruleController,
                    decoration: const InputDecoration(
                      hintText: '添加规则',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addRule(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRule,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._rules.map((rule) => ListTile(
                  title: Text(rule),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeRule(_rules.indexOf(rule)),
                  ),
                )),

            const SizedBox(height: 16),

            // 地点
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('主要地点',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加地点'),
                  onPressed: _addLocation,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._locations.map((location) => ListTile(
                  title: Text(location.name),
                  subtitle: Text(location.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editLocation(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeLocation(location.id),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // 势力组织
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('主要势力',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加势力'),
                  onPressed: _addOrganization,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._organizations.map((org) => ListTile(
                  title: Text(org.name),
                  subtitle: Text(org.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editOrganization(org),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeOrganization(org.id),
                      ),
                    ],
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
