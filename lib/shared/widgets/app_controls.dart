/// Apple-style controls: segmented control, text field, empty state, badge.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// iOS segmented control built on Material's [SegmentedButton] (keeps
/// semantics and testing) with the Apple treatment: gray5 track, raised
/// selected segment, hairline borders, no ripple.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final Set<T> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.gray5,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: SegmentedButton<T>(
        segments: [
          for (final s in segments)
            ButtonSegment(
              value: s,
              label: Text(
                s is String ? s as String : s.toString(),
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.tertiarySystemBackground
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.label
                : p.secondaryLabel,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(style: BorderStyle.none),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.small - 2),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (sel) {
          if (sel.isNotEmpty) onSelectionChanged(sel.first);
        },
      ),
    );
  }
}

/// iOS-style filled text field with optional clear button.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefixIcon,
    this.suffix,
    this.showClearButton = false,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool showClearButton;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    Widget? clear;
    if (showClearButton && controller != null) {
      clear = ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller!,
        builder: (context, value, _) => value.text.isEmpty
            ? const SizedBox.shrink()
            : GestureDetector(
                onTap: () {
                  controller!.clear();
                  onChanged?.call('');
                },
                child: Icon(Icons.cancel, size: 16, color: p.tertiaryLabel),
              ),
      );
    }

    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: p.tertiaryLabel)
            : null,
        suffixIcon: suffix ?? clear,
        isDense: true,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      autofocus: autofocus,
    );
  }
}

/// Apple-style empty state: thin-lined icon, title, secondary description,
/// optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: p.gray3),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Small rounded count/status badge.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.color,
    this.subtle = false,
  });

  final String label;
  final Color? color;

  /// When true, renders as a tinted pill (accentFill bg, accent text)
  /// instead of a solid one.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final tint = color ?? p.accent;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle ? tint.withValues(alpha: 0.14) : tint,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: textTheme.labelMedium?.copyWith(
          color: subtle ? tint : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
