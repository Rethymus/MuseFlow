import 'package:flutter/material.dart';
import 'package:museflow/features/onboarding/domain/opening_variant.dart';

class OpeningVariantCard extends StatelessWidget {
  const OpeningVariantCard({
    super.key,
    required this.variant,
    required this.onSelect,
    this.isSelected = false,
  });

  final OpeningVariant variant;
  final VoidCallback onSelect;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PassiveTag(label: variant.style.displayLabel),
            const SizedBox(height: 12),
            Text(
              variant.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: isSelected
                  ? FilledButton(
                      onPressed: onSelect,
                      child: const Text('使用此开篇'),
                    )
                  : FilledButton.tonal(
                      onPressed: onSelect,
                      child: const Text('使用此开篇'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassiveTag extends StatelessWidget {
  const _PassiveTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
