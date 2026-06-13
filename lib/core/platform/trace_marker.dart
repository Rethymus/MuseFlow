/// Platform-conditional startup trace marker.
///
/// Exports a single [setTraceMarker] function. On Web it writes the boot
/// step to `document.title` as a debugging trace marker; on native platforms
/// (Android/Linux/Windows/macOS) it is a no-op.
///
/// The conditional export keeps `dart:js_interop` (web-only) out of the
/// native compile — an unconditional import previously broke the Android
/// and Linux release builds (CI build-smoke failure, 2026-06-14:
/// "Dart library 'dart:js_interop' is not available on this platform").
library;

export 'trace_marker_io.dart'
    if (dart.library.js_interop) 'trace_marker_web.dart';
