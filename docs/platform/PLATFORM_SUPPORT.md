# MuseFlow Platform Support

Captured for v1.4 release hardening on 2026-06-09.

## Support Tiers

| Platform | Tier | Current Basis | Release Artifact Target |
| --- | --- | --- | --- |
| Android | Tier 1 | `android/` runner exists; Gradle metadata uses `com.museflow.museflow`; local `flutter build apk --release` passed on 2026-06-09; release workflow published APK for `v0.1.0` | APK |
| Linux | Tier 1 | `linux/` runner exists; GTK desktop target; local `flutter build linux --release` passed on 2026-06-09; release workflow published tarball for `v0.1.0` | `tar.gz` bundle |
| Windows | Tier 1 | `windows/` runner exists; GitHub Actions Windows build passed and published zip for `v0.1.0` | `.zip` bundle |
| Web | Future / unsupported for this release | No `web/` runner; storage behavior not validated | None |
| macOS | Future / unsupported for this release | No `macos/` runner; signing and secure storage not validated | None |
| iOS | Future / unsupported for this release | No `ios/` runner; signing and secure storage not validated | None |

Tier 1 is release-verified for `v0.1.0`: the GitHub Release contains Android, Linux, and Windows artifacts plus `SHA256SUMS.txt`, and downloaded artifacts passed checksum verification.

## README Policy

README platform claims must be limited to verified targets. For `v0.1.0`, Android, Linux, and Windows are the published release targets. Web, macOS, and iOS remain future/unsupported because runners and storage behavior have not been generated and validated.

## Native Metadata Notes

- Android namespace/application ID: `com.museflow.museflow`.
- Android release currently uses the debug signing config; release notes must label Android artifacts as unsigned/debug-signed unless real signing credentials are added.
- Linux executable name: `museflow`; application ID: `com.museflow.museflow`.
- Windows executable target: `museflow`; Windows release validation must run on `windows-latest`.
