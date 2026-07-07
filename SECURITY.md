# Security Policy

## Supported Versions

Security fixes target the latest `main` branch and the latest published GitHub Release.

## Reporting a Vulnerability

Please report security issues privately through GitHub's private vulnerability reporting if enabled, or contact the repository owner directly. Do not open public issues for API key exposure, storage bypasses, release artifact tampering, or other exploitable findings.

## Secret Storage Policy

MuseFlow stores API keys and encryption keys through platform secure storage. Plaintext fallback storage for secrets is not allowed. If native secure storage is unavailable, the app should surface an error instead of silently weakening storage.

See `docs/platform/SECRET_STORAGE_BOUNDARY.md` for the source-level boundary,
allowed Hive metadata, and focused regression checks.
