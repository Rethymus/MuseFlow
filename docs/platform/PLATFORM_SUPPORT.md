# MuseFlow Platform Support

Captured for v1.4 release hardening on 2026-06-09.

## Support Tiers

| Platform | Tier | Current Basis | Release Artifact Target |
| --- | --- | --- | --- |
| Android | Tier 1 candidate | `android/` runner exists; Gradle metadata uses `com.museflow.museflow`; local `flutter build apk --release` passed on 2026-06-09 | APK, optional AAB |
| Linux | Tier 1 candidate | `linux/` runner exists; GTK desktop target; local `flutter build linux --release` passed on 2026-06-09 | `tar.gz` bundle |
| Windows | Tier 1 candidate | `windows/` runner exists; local Linux host cannot build it; GitHub Actions Windows build required | `.zip` bundle |
| Web | Future / unsupported for this release | No `web/` runner; storage behavior not validated | None |
| macOS | Future / unsupported for this release | No `macos/` runner; signing and secure storage not validated | None |
| iOS | Future / unsupported for this release | No `ios/` runner; signing and secure storage not validated | None |

Tier 1 is not final until the release workflow produces artifacts and checksums for Android, Linux, and Windows. Android and Linux have local build-smoke evidence; Windows remains remote-only until GitHub Actions succeeds.

## README Policy

README platform claims must be limited to verified targets. Until CI/release artifacts exist, MuseFlow should describe Android, Linux, and Windows as release targets under validation rather than completed published support.

## Native Metadata Notes

- Android namespace/application ID: `com.museflow.museflow`.
- Android release currently uses the debug signing config; release notes must label Android artifacts as unsigned/debug-signed unless real signing credentials are added.
- Linux executable name: `museflow`; application ID: `com.museflow.museflow`.
- Windows executable target: `museflow`; Windows release validation must run on `windows-latest`.
