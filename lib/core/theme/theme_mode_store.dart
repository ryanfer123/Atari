import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Persists the user's light/dark choice as a single small file — no
/// system option, so this is the only thing controlling which theme is
/// in effect. A whole Drift migration for one enum value would be a lot
/// of ceremony for what this is, and the app already reaches for
/// `path_provider` elsewhere (see `AppDatabase`).
class ThemeModeStore {
  const ThemeModeStore();

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/theme_mode.txt');
  }

  /// Falls back to [ThemeMode.dark] for a missing file or an unreadable
  /// one — a corrupt preference should read as "no preference set", not
  /// crash the app.
  Future<ThemeMode> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return ThemeMode.dark;
      return parseThemeMode(await file.readAsString());
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  Future<void> write(ThemeMode mode) async {
    final file = await _file();
    await file.writeAsString(mode.name);
  }
}

/// Falls back to [ThemeMode.dark] for anything that isn't exactly
/// `light` or `dark` — including `system`, which the app no longer
/// offers as a choice but which [ThemeMode] still defines, so a value
/// written by an older build reads as the app's own default rather
/// than deferring to the device. Pulled out of [ThemeModeStore.read]
/// so the parsing itself is testable without going through the real
/// filesystem.
ThemeMode parseThemeMode(String raw) {
  final name = raw.trim();
  return switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.dark,
  };
}
