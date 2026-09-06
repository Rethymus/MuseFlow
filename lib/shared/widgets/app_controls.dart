/// Apple-style controls: segmented control, text field, empty state, badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_materials.dart';
import '../theme/app_motion.dart';

/// iOS segmented control with the "bamboo-groove slot snap" (research doc
/// §7): a raised thumb glides between discrete slots on the slotSnap
/// spring (0.3s, ζ0.85 — a ~1.7% overshoot that reads as "click into
/// place"). Built directly (not on SegmentedButton) so the thumb can move
/// independently of the labels, iOS-style.
class AppSegmentedControl<T> extends StatefulWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.labelOf,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;

  /// Optional display-label resolver for non-String segment values.
  final String Function(T value)? labelOf;

  @override
  State<AppSegmentedControl<T>> createState() => _AppSegmentedControlState<T>();
}

class _AppSegmentedControlState<T> extends State<AppSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  /// Drives progress 0→1 from the previous slot toward the new slot on the
  /// slotSnap spring (unbounded so the small overshoot survives).
  late final AnimationController _progress;

  int _fromIndex = 0;
  int _toIndex = 0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController.unbounded(vsync: this, value: 1.0);
    _toIndex = widget.segments
        .indexOf(widget.selected)
        .clamp(0, widget.segments.length - 1);
    _fromIndex = _toIndex;
  }

  @override
  void didUpdateWidget(covariant AppSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.segments
        .indexOf(widget.selected)
        .clamp(0, widget.segments.length - 1);
    if (newIndex != _toIndex) {
      _fromIndex = _toIndex;
      _toIndex = newIndex;
      // The tactile half of the slot snap: a selection haptic exactly as
      // the thumb starts gliding (HIG: reinforce selection changes; no-op
      // on platforms without haptics).
      HapticFeedback.selectionClick();
      _progress
        ..value = 0.0
        ..animateWith(
          AppleSprings.simulation(
            1.0,
            response: AppleMotion.slotSnapResponse,
            dampingFraction: AppleMotion.slotSnapDampingFraction,
          ),
        );
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppFocusRing(
      radius: BorderRadius.circular(AppRadius.small),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: p.gray5,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small - 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / widget.segments.length;
              return Stack(
                children: [
                  // The spring-driven thumb gliding between slots.
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      final t = _progress.value;
                      final left =
                          (_fromIndex + (_toIndex - _fromIndex) * t) *
                          slotWidth;
                      return Positioned(
                        left: left,
                        width: slotWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.tertiarySystemBackground,
                            borderRadius: BorderRadius.circular(
                              AppRadius.small - 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < widget.segments.length; i++)
                        Expanded(
                          child: _SlotLabel(
                            label: widget.labelOf != null
                                ? widget.labelOf!(widget.segments[i])
                                : (widget.segments[i] is String
                                      ? widget.segments[i] as String
                                      : widget.segments[i].toString()),
                            selected: i == _toIndex,
                            textTheme: textTheme,
                            onTap: () =>
                                widget.onSelectionChanged(widget.segments[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// One segment label; taps route through the parent.
class _SlotLabel extends StatelessWidget {
  const _SlotLabel({
    required this.label,
    required this.selected,
    required this.textTheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: selected ? p.label : p.secondaryLabel,
            ),
          ),
        ),
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
