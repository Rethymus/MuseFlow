import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:museflow/core/presentation/providers.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';
import 'package:museflow/features/onboarding/presentation/opening_text_insertion.dart';
import 'package:museflow/features/onboarding/presentation/opening_variant_card.dart';

Future<void> showOpeningGeneratorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const OpeningGeneratorSheet(),
  );
}

class OpeningGeneratorSheet extends ConsumerStatefulWidget {
  const OpeningGeneratorSheet({
    super.key,
    this.genreName,
    this.worldDescription,
    this.characterDescription,
  });

  final String? genreName;
  final String? worldDescription;
  final String? characterDescription;

  @override
  ConsumerState<OpeningGeneratorSheet> createState() =>
      _OpeningGeneratorSheetState();
}

class _OpeningGeneratorSheetState extends ConsumerState<OpeningGeneratorSheet> {
  final _conceptController = TextEditingController();
  List<OpeningVariant>? _variants;
  OpeningVariant? _selectedVariant;
  bool _isGenerating = false;
  String? _error;

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
        genreName: widget.genreName ?? '通用',
        worldDescription: widget.worldDescription ?? '一个未知的世界',
        characterDescription: widget.characterDescription ?? '一个神秘的角色',
        storyConcept: _conceptController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _selectedVariant = null;
        _error = variants.isEmpty ? '没有生成可用开篇，请重试' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _selectOpening(OpeningVariant variant) {
    setState(() => _selectedVariant = variant);
    final inserted = insertOpeningText(
      ref.read(editorProvider),
      variant.text,
      onAiInserted: (text) {
        ref.read(writingStatsCollectorProvider.future).then((collector) {
          collector.recordAiInsertion(text);
        });
      },
    );
    if (inserted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('开篇生成', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _conceptController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: '补充描述你的故事概念（可选）',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _isGenerating ? null : _generateOpenings,
                icon: const Icon(Icons.auto_stories),
                label: const Text('生成开篇'),
              ),
              const SizedBox(height: 16),
              if (_isGenerating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _generateOpenings,
                      child: const Text('重试'),
                    ),
                  ],
                )
              else if (_variants != null)
                ..._variants!.map(
                  (variant) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OpeningVariantCard(
                      variant: variant,
                      isSelected: variant == _selectedVariant,
                      onSelect: () => _selectOpening(variant),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
