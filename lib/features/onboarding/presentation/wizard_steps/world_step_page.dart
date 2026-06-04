import 'package:flutter/material.dart';

/// World setting creation step for the onboarding wizard.
///
/// Simplified form with only name (required) and description (optional).
/// Entity creation happens in the parent OnboardingWizardPage when
/// advancing to the next step, not here.
class WorldStepPage extends StatefulWidget {
  const WorldStepPage({
    super.key,
    required this.worldNameController,
    required this.worldDescriptionController,
  });

  /// Controller for the world name field.
  final TextEditingController worldNameController;

  /// Controller for the world description field.
  final TextEditingController worldDescriptionController;

  @override
  State<WorldStepPage> createState() => WorldStepPageState();
}

/// Public state class so the parent wizard can call validate().
class WorldStepPageState extends State<WorldStepPage>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  /// Validates the form. Returns true if valid.
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          TextFormField(
            controller: widget.worldNameController,
            decoration: InputDecoration(
              labelText: '世界观名称 *',
              hintText: '为你的故事世界命名',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入世界观名称';
              }
              if (value.trim().length > 100) {
                return '名称不能超过100个字符';
              }
              return null;
            },
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.worldDescriptionController,
            decoration: InputDecoration(
              labelText: '世界简介',
              hintText: '描述你的故事背景、设定、规则等',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
    );
  }
}
