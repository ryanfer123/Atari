import 'package:flutter/services.dart';

/// Dart-side client for the native `AppSwitchTracker` signal collector
/// (`android/.../AppSwitchTracker.kt`), over the `atari.dev/signals`
/// platform channel. Metadata only — a count of foreground app-switch
/// events.
///
/// Unlike `UnlockSignalService`, this source requires the user to
/// manually grant Usage access first — see [hasUsageAccess] and
/// [openUsageAccessSettings].
class AppSwitchSignalService {
  AppSwitchSignalService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/signals');

  final MethodChannel _channel;

  /// Whether the user has granted Usage access (Settings → Apps →
  /// Special access → Usage access).
  Future<bool> hasUsageAccess() async {
    final granted = await _channel.invokeMethod<bool>('hasUsageAccess');
    return granted ?? false;
  }

  /// Count of foreground app-switch transitions recorded at or after
  /// [since]. Returns 0 (not an error) if Usage access hasn't been
  /// granted — check [hasUsageAccess] to distinguish "no switches" from
  /// "no access".
  Future<int> getAppSwitchCountSince(DateTime since) async {
    final count = await _channel.invokeMethod<int>('getAppSwitchCountSince', {
      'sinceMillis': since.millisecondsSinceEpoch,
    });
    return count ?? 0;
  }

  /// Opens the OS's Usage access settings screen so the user can grant
  /// it — there is no `requestPermissions()` dialog for this permission.
  Future<void> openUsageAccessSettings() {
    return _channel.invokeMethod<void>('openUsageAccessSettings');
  }
}
