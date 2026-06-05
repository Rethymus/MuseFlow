import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/opening_variant_card.dart';

class OpeningStepPage extends ConsumerStatefulWidget {
  const OpeningStepPage({
    super.key,
    required this.genreName,
    required this.worldDescription,
    required this.characterDescription,
    required this.onSelected,
  });

  final String genreName;
  final String worldDescription;
  final String characterDescription;
  final ValueChanged<OpeningVariant?> onSelected;

  @override
  ConsumerState<OpeningStepPage> createState() => OpeningStepPageState();
}

class OpeningStepPageState extends ConsumerState<OpeningStepPage>
    with AutomaticKeepAliveClientMixin {
  final _conceptController = TextEditingController();
  List<OpeningVariant>? _variants;
  OpeningVariant? _selectedVariant;
  bool _isGenerating = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _generateOpenings() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final service = await ref.read(openingGeneratorServiceProvider.future);
      final variants = await service.generateOpenings(
        genreName: widget.genreName.trim().isEmpty ? '通用' : widget.genreName,
        worldDescription: widget.worldDescription.trim().isEmpty
            ? '一个未知的世界'
            : widget.worldDescription,
        characterDescription: widget.characterDescription.trim().isEmpty
            ? '一个神秘的角色'
            : widget.characterDescription,
        storyConcept: _conceptController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _selectedVariant = null;
        _error = variants.isEmpty ? '没有生成可用开篇，请重试' : null;
      });
      widget.onSelected(null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _selectVariant(OpeningVariant variant) {
    setState(() => _selectedVariant = variant);
    widget.onSelected(variant);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        TextField(
          controller: _conceptController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: '补充描述你的故事概念（可选）',
            hintText: '例如：主角在雨夜发现一封来自十年前的信',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLow,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isGenerating ? null : _generateOpenings,
            icon: const Icon(Icons.auto_stories),
            label: const Text('生成开篇'),
          ),
        ),
        const SizedBox(height: 16),
        if (_isGenerating)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('正在生成开篇...'),
              ],
            ),
          )
        else if (_error != null)
          _OpeningError(message: _error!, onRetry: _generateOpenings)
        else if (_variants == null)
          Center(
            child: Text(
              '点击上方按钮生成开篇',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._variants!.map(
            (variant) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OpeningVariantCard(
                variant: variant,
                isSelected: variant == _selectedVariant,
                onSelect: () => _selectVariant(variant),
              ),
            ),
          ),
      ],
    );
  }
}

class _OpeningError extends StatelessWidget {
  const _OpeningError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
