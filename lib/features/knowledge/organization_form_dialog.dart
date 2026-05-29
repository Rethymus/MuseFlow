import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart' show Uuid;

import 'world_model.dart';

/// 组织表单对话框
class OrganizationFormDialog extends StatefulWidget {
  final Organization? organization;
  final Function(Organization) onSave;

  const OrganizationFormDialog({
    Key? key,
    this.organization,
    required this.onSave,
  }) : super(key: key);

  @override
  State<OrganizationFormDialog> createState() => _OrganizationFormDialogState();
}

class _OrganizationFormDialogState extends State<OrganizationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _leaderController;
  late final TextEditingController _philosophyController;
  final List<String> _members = [];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.organization?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.organization?.description ?? '');
    _leaderController =
        TextEditingController(text: widget.organization?.leader ?? '');
    _philosophyController =
        TextEditingController(text: widget.organization?.philosophy ?? '');
    if (widget.organization != null) {
      _members.addAll(widget.organization!.members);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _leaderController.dispose();
    _philosophyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final org = Organization(
        id: widget.organization?.id ?? const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text,
        leader: _leaderController.text,
        philosophy: _philosophyController.text,
        members: _members,
      );
      widget.onSave(org);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.organization != null ? '编辑组织' : '添加组织'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '组织名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? '请输入组织名称' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? '请输入描述' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _leaderController,
                decoration: const InputDecoration(
                  labelText: '领袖',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _philosophyController,
                decoration: const InputDecoration(
                  labelText: '理念/宗旨',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
