# MuseFlow Web Testing Target Design

Captured: 2026-06-09, Asia/Shanghai.

## Decision

Build a testing-friendly Flutter Web target for MuseFlow. Web is a UAT and
README journey validation target first, not a production Tier 1 platform for
secret-bearing end-user releases.

## Goals

- Add the Flutter `web/` runner so the app can compile for browsers.
- Keep Android, Linux, and Windows behavior unchanged.
- Make desktop-only window management unavailable on Web through conditional
  platform code.
- Make export behavior platform-aware: native targets keep local file writes;
  Web uses browser download semantics or an explicit Web-safe path.
- Keep secret handling conservative. Do not introduce plaintext persistent API
  key storage for Web.
- Add CI evidence for Web through `flutter build web`.
- Update README and platform docs so Web is described as a testing/UAT target,
  not a production secure-storage release target.

## Non-Goals

- Do not make Web a production Tier 1 release platform in this slice.
- Do not add real API-key persistence on Web unless a browser-specific security
  design is approved later.
- Do not replace the existing local-first Hive model for native platforms.
- Do not add broad rewrites unrelated to Web buildability and README-function
  testability.

## Architecture

- `main.dart` initializes Hive and shared app services, then delegates
  window setup to a conditional platform helper.
- `AppShellScaffold` delegates window geometry persistence to a conditional
  controller. Native desktop uses `window_manager`; Web is a no-op.
- `ExportService` remains responsible for content generation. File delivery is
  supplied by a conditional writer:
  - IO writer: `dart:io` file write with parent directory creation.
  - Web writer: browser download for the provided filename/content.
- Secure storage remains strict. Web support must not add an insecure fallback
  for API keys or Hive encryption keys.

## Verification

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`
- Existing Linux integration smoke remains part of CI.
- CI build smoke includes Web build evidence.
