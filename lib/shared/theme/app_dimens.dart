/// Apple HIG dimension tokens for MuseFlow.
///
/// A single source of truth for corner radii, spacing, margins and stroke
/// widths, following the 8-point grid Apple's interfaces are built on.
/// Feature code must reference these tokens instead of raw doubles so the
/// whole app stays visually coherent when values are tuned.
library;

import 'package:flutter/material.dart';

/// Corner radii (logical px).
///
/// Apple surfaces: 8 for small controls and inputs, 12 for cards and list
/// groups, 16–20 for large sheets and hero surfaces, stadium for pills.
abstract final class AppRadius {
  /// Small controls, text fields, thumbnails.
  static const double small = 8;

  /// Standard cards, inset grouped lists, menus.
  static const double medium = 12;

  /// Large cards, popovers, dialogs.
  static const double large = 14;

  /// Bottom sheets and hero surfaces.
  static const double xLarge = 20;

  /// Hairline separator thickness (iOS separators are 0.5pt).
  static const double hairline = 0.5;

  /// Fully rounded pill shape.
  static final BorderRadius pill = BorderRadius.circular(999);

  static final BorderRadius rSmall = BorderRadius.circular(small);
  static final BorderRadius rMedium = BorderRadius.circular(medium);
  static final BorderRadius rLarge = BorderRadius.circular(large);
  static final BorderRadius rXLarge = BorderRadius.circular(xLarge);
}

/// Spacing steps on the 4pt grid.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard iOS horizontal page margin.
  static const double pageMargin = 20;

  /// Inset grouped list horizontal margin (iOS Settings uses 16).
  static const double groupMargin = 16;
}

/// Minimum tap target (44pt, Apple HIG).
const double kMinTapTarget = 44;
