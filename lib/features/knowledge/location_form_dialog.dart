import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart' show Uuid;

import 'world_model.dart';

/// 地点表单对话框
class LocationFormDialog extends StatefulWidget {
  final Location? location;
  final Function(Location) onSave;

  const LocationFormDialog({
    Key? key,
    this.location,
    required this.onSave,
  }) : super(key: key);

  @override
  State<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final List<String> _relatedCharacters = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.location?.description ?? '');
    if (widget.location != null) {
      _relatedCharacters.addAll(widget.location!.relatedCharacters);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final location = Location(
        id: widget.location?.id ?? const Uuid().v4(),
        name: _nameController.text,
        description: _descriptionController.text,
        relatedCharacters: _relatedCharacters,
      );
      widget.onSave(location);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location != null ? '编辑地点' : '添加地点'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '地点名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '请输入地点名称' : null,
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
          ],
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
