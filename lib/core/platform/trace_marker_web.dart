import 'dart:js_interop';

/// Sets the browser tab title to a startup-step trace marker.
///
/// Used to observe Flutter web boot progress during Web debugging — the
/// title updates synchronously before the CanvasKit surface renders, so the
/// step is visible even when the canvas is blank.
@JS('document.title')
external set _documentTitle(JSString value);

void setTraceMarker(String step) {
  _documentTitle = '[$step] MuseFlow'.toJS;
}
