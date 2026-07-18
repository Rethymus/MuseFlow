# MuseFlow Platform Support

Captured for v1.4 release hardening on 2026-06-09.

## Support Tiers

| Platform | Tier | Current Basis | Release Artifact Target |
| --- | --- | --- | --- |
| Android | Tier 1 | `android/` runner exists; Gradle metadata uses `com.museflow.museflow`; local `flutter build apk --release` passed on 2026-06-09; release workflow publishes APK artifacts | APK |
| Linux | Tier 1 | `linux/` runner exists; GTK desktop target; local `flutter build linux --release` passed on 2026-06-09; release workflow publishes tarball artifacts | `tar.gz` bundle |
| Windows | Tier 1 | `windows/` runner exists; GitHub Actions Windows build publishes zip artifacts | `.zip` bundle |
| Web | Testing / UAT | `web/` runner exists; `pages.yml` builds a GitHub Pages browser-workspace preview; provider keys are tab-session scoped; manuscripts use IndexedDB with backup/restore | GitHub Pages + `.zip` build output |
| macOS | Future / unsupported for this release | No `macos/` runner; signing and secure storage not validated | None |
| iOS | Future / unsupported for this release | No `ios/` runner; signing and secure storage not validated | None |

Tier 1 is release-verified through GitHub Actions: the GitHub Release contains Android, Linux, and Windows artifacts plus `SHA256SUMS.txt`, and downloaded artifacts must pass checksum verification. Web is a testing/UAT browser-workspace preview and is packaged separately without claiming production-grade browser secret storage or permanent browser data retention.

## README Policy

README platform claims must be limited to verified targets. Android, Linux, and Windows are the published release targets. Web is a GitHub Pages testing/UAT target with session-scoped BYOK and best-effort IndexedDB persistence. macOS and iOS remain future/unsupported because runners and storage behavior have not been generated and validated.

## Native Metadata Notes

- Android namespace/application ID: `com.museflow.museflow`.
- Android release currently uses the debug signing config; release notes must label Android artifacts as unsigned/debug-signed unless real signing credentials are added.
- Linux executable name: `museflow`; application ID: `com.museflow.museflow`.
- Windows executable target: `museflow`; Windows release validation must run on `windows-latest`.
