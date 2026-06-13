/// Native (non-Web) no-op trace marker.
///
/// The trace marker is a Web-only debugging aid (browser tab title). Native
/// builds have no document.title to set, so this is a stub that lets the
/// rest of the app call [setTraceMarker] unconditionally without pulling in
/// `dart:js_interop`.
void setTraceMarker(String step) {}
