# Development

## Prerequisites

The planned toolchain includes Flutter, Dart, Android Studio, the Android SDK,
the Android NDK, CMake, Git, and a physical Android device. Exact supported
versions will be pinned when the Flutter project is initialized.

## Local setup

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate Drift code after editing lib/core/database
```

Android device setup and launch commands will be added once `backend-native`
initializes the Android host and permission flows (see `android/README.md`).

## Quality checks

- Formatting: `dart format --output=none --set-exit-if-changed lib test`
- Static analysis: `flutter analyze`
- Unit tests: `flutter test`
- Production build: not yet available — no app entrypoint exists until
  `dev/frontend` builds the app shell.

Prefer wrapper scripts in `scripts/` so local development and continuous
integration run the same commands.
