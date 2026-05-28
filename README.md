# MuseFlow

A lightweight cross-platform note-taking application for Windows and Android.

## Features

- Cross-platform support (Windows Desktop & Android)
- Lightweight design (< 100MB)
- Native input method support
- Multiple storage backends (Hive, SQLite, JSON)

## Project Structure

```
MuseFlow/
├── lib/
│   ├── pages/          # Application pages/screens
│   ├── widgets/        # Reusable UI components
│   ├── models/         # Data models and state management
│   ├── services/       # Data services (storage, database)
│   ├── theme/          # App theming
│   └── utils/          # Utility functions
├── android/            # Android native configuration
├── windows/            # Windows native configuration
└── test/              # Test files
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- For Windows: Visual Studio 2022 with C++ desktop development tools

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate code (for Hive adapters):
   ```bash
   dart run build_runner build
   ```

4. Run the app:
   ```bash
   # Windows
   flutter run -d windows

   # Android
   flutter run -d android
   ```

## Storage Architecture

- **Hive**: Configuration data, user preferences, quick access
- **SQLite**: Structured data, tags, search history, relationships
- **JSON**: Export/Import functionality

## Development

### Code Generation
After modifying models, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Linting
```bash
flutter analyze
```

### Testing
```bash
flutter test
```

## License

MIT License
