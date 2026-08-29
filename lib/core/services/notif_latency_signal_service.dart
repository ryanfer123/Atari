import 'package:flutter/services.dart';

/// Dart-side client for the native `NotifLatencyTracker` signal collector
/// (`android/.../NotifLatencyTracker.kt`), over the `atari.dev/signals`
/// platform channel. Metadata only — per-notification latency
/// (milliseconds until dismissed or the next unlock, whichever is
/// first), never notification content.
///
/// Like `AppSwitchSignalService`, this source requires the user to
/// manually grant access first — see [hasNotificationAccess] and
/// [openNotificationAccessSettings].
class NotifLatencySignalService {
  NotifLatencySignalService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/signals');

  final MethodChannel _channel;

  /// Whether the user has granted Notification access (Settings → Apps →
  /// Special access → Notification access).
  Future<bool> hasNotificationAccess() async {
    final granted = await _channel.invokeMethod<bool>('hasNotificationAccess');
    return granted ?? false;
  }

  /// Latency (as [Duration]s) for each notification posted at or after
  /// [since]. Empty if Notification access hasn't been granted — check
  /// [hasNotificationAccess] to distinguish "no notifications" from "no
  /// access".
  Future<List<Duration>> getLatenciesSince(DateTime since) async {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'getNotifLatenciesSince',
      {'sinceMillis': since.millisecondsSinceEpoch},
    );
    if (raw == null) return const [];
    return raw.map((value) => Duration(milliseconds: value! as int)).toList();
  }

  /// Opens the OS's Notification access settings screen so the user can
  /// grant it — there is no `requestPermissions()` dialog for this
  /// permission.
  Future<void> openNotificationAccessSettings() {
    return _channel.invokeMethod<void>('openNotificationAccessSettings');
  }
}
