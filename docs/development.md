# Development

## Prerequisites

The planned toolchain includes Flutter, Dart, Android Studio, the Android SDK,
the Android NDK, CMake, Git, and a physical Android device. Exact supported
versions will be pinned when the Flutter project is initialized.

## Local setup

```sh
flutter pub get
flutter build apk --debug     # or: flutter run -d <device-id>
```

NDK: `android/app/build.gradle.kts` pins `ndkVersion` explicitly rather than
using Flutter's default. On this dev machine the SDK's own installer
(`sdkmanager.bat`) crashes outright trying to auto-fetch Flutter's default
NDK version, so the pin points at whichever NDK is actually installed
(via Android Studio's SDK Manager → SDK Tools tab, not SDK Platforms).
Update the pin if you install a different NDK version.

### Keeping signal collection running with the app closed (iQOO / OriginOS)

`SignalCollectionService` runs as a foreground service specifically so
signal collectors (`UnlockTracker`, and others as they're added) keep
working when the app isn't open — see that file's doc comment for why a
plain background process or a bare `BroadcastReceiver` isn't enough on
modern Android. That gets you through the app being closed or the system
reclaiming the process under normal memory pressure.

It does **not** survive OriginOS's own background-app killer, which is
more aggressive than stock Android and has no standard API to fully
defeat. On the physical test device, this required a manual one-time step:

1. Settings → Battery → App battery usage → ATARI → **No restrictions**
   (not "Optimized"/"Restricted").
2. Settings → More settings (or Permission Manager) → Autostart →
   enable ATARI.

Do this on any real test/demo device before relying on background
collection working unattended — there's no reliable programmatic
substitute for it on this hardware.

## Quality checks

- Formatting: `dart format --output=none --set-exit-if-changed lib test`
- Static analysis: `flutter analyze`
- Unit/widget tests: `flutter test`
- Production build: `flutter build apk --release` (not yet exercised on a
  release-signed build)

Prefer wrapper scripts in `scripts/` so local development and continuous
integration run the same commands.
