import 'package:flutter/material.dart';

/// Character card creation step for the onboarding wizard.
///
/// Simplified form with only name (required) and description (optional).
/// Entity creation happens in the parent OnboardingWizardPage when
/// advancing to the next step, not here.
class CharacterStepPage extends StatefulWidget {
  const CharacterStepPage({
    super.key,
    required this.characterNameController,
    required this.characterDescriptionController,
  });

  /// Controller for the character name field.
  final TextEditingController characterNameController;

  /// Controller for the character description field.
  final TextEditingController characterDescriptionController;

  @override
  State<CharacterStepPage> createState() => CharacterStepPageState();
}

/// Public state class so the parent wizard can call validate().
class CharacterStepPageState extends State<CharacterStepPage>
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
            controller: widget.characterNameController,
            decoration: InputDecoration(
              labelText: '角色名称 *',
              hintText: '主角的名字',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入角色名称';
              }
              if (value.trim().length > 50) {
                return '名称不能超过50个字符';
              }
              return null;
            },
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.characterDescriptionController,
            decoration: InputDecoration(
              labelText: '角色简介',
              hintText: '描述角色的性格、外貌、背景等',
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
