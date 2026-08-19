/// AppListSection / AppListTile — the iOS Settings list primitives.
///
/// An inset grouped list: rounded white card with hairline separators between
/// rows, an optional uppercase footnote header above and description footer
/// below. Rows are 44pt+ tall with a colored squircle icon, title/value
/// layout, and a trailing chevron, switch or custom widget.
library;

import 'package:flutter/cupertino.dart' show CupertinoIcons, CupertinoSwitch;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// An inset grouped list with [AppListTile]-style children.
class AppListSection extends StatelessWidget {
  const AppListSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  /// Small gray text above the group (e.g. 「外观」).
  final String? header;

  /// Small gray text below the group (e.g. setting explanation).
  final String? footer;

  /// The rows; separators are drawn between them automatically.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: AppRadius.hairline,
            thickness: AppRadius.hairline,
            indent: 16,
            endIndent: 0,
            color: p.separator,
          ),
        );
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 7),
            child: Text(
              header!.toUpperCase(),
              style: groupedSectionHeader(context).copyWith(letterSpacing: 0.4),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.groupMargin,
          ),
          decoration: BoxDecoration(
            color: p.cardBackground,
            borderRadius: AppRadius.rMedium,
          ),
          child: Column(children: rows),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 7, 32, 0),
            child: Text(footer!, style: groupedSectionHeader(context)),
          ),
      ],
    );
  }
}

/// One iOS-style list row inside an [AppListSection].
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
    this.showChevron = false,
    this.horizontalPadding = 16,
  });

  /// Leading icon; when [iconColor] is set it renders in the iOS colored
  /// squircle badge (white glyph on solid tint).
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;

  /// Trailing value text (e.g. current selection), before the chevron.
  final String? value;

  /// Fully custom trailing widget (switch, checkbox…). Overrides [value].
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget? leading;
    if (icon != null) {
      leading = iconColor != null
          ? _SquircleIcon(icon: icon!, color: iconColor!)
          : Icon(icon, size: 22, color: p.accent);
    }

    Widget? trail;
    if (trailing != null) {
      trail = trailing;
    } else if (showChevron || value != null) {
      trail = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                value!,
                style: textTheme.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
          if (showChevron)
            Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: p.tertiaryLabel,
            ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: subtitle == null ? 11 : 10,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      color: destructive ? p.systemRed : p.label,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1.5),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: p.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trail != null) ...[const SizedBox(width: 8), trail],
          ],
        ),
      ),
    );
  }
}

/// The 29×29pt rounded-tint icon badge of iOS Settings rows.
class _SquircleIcon extends StatelessWidget {
  const _SquircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: Colors.white),
    );
  }
}

/// iOS-style switch row shortcut — a [CupertinoSwitch] tinted with the app
/// palette (green track on iOS; we keep the app accent for brand identity).
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: p.systemGreen,
      inactiveTrackColor: p.gray4,
    );
  }
}
