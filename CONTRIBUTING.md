# Contributing

## Local Checks

Run these before opening a pull request:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
scripts/check_readme_assets.sh
scripts/check_repo_hygiene.sh
```

For release-sensitive changes, also run platform build smoke where your machine supports it:

```bash
flutter build apk --release
flutter build linux --release
```

## Pull Request Expectations

- Keep changes scoped to one behavior or release-hardening concern.
- Update `README.md` and `README.en.md` together when screenshots or platform claims change.
- Do not commit local files such as `android/local.properties`, build outputs, key stores, logs, or generated caches.
- Do not store API keys or model credentials in source, fixtures, screenshots, or documentation.
