import 'package:flutter/services.dart';

/// Dart-side client for the native `UnlockTracker` signal collector
/// (`android/.../UnlockTracker.kt`), over the `atari.dev/signals` platform
/// channel. Metadata only — a list of device-unlock timestamps.
///
/// See Plans/IMPLEMENTATION.md §3 (Workstream: Backend — Native):
/// "Expose every capability above through the `lib/core/services`
/// platform-channel contract Sprint 0 defined, so frontend and
/// backend-engine can each swap their fakes for the real implementation
/// independently."
class UnlockSignalService {
  UnlockSignalService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/signals');

  final MethodChannel _channel;

  /// All persisted unlock timestamps, oldest first, bounded to the native
  /// side's retention window (see `UnlockTracker.MAX_STORED_TIMESTAMPS`).
  Future<List<DateTime>> getUnlockTimestamps() async {
    final raw = await _channel.invokeMethod<List<Object?>>(
      'getUnlockTimestamps',
    );
    if (raw == null) return const [];
    return raw
        .map((value) => DateTime.fromMillisecondsSinceEpoch(value! as int))
        .toList();
  }

  /// Count of unlocks recorded at or after [since].
  Future<int> getUnlockCountSince(DateTime since) async {
    final count = await _channel.invokeMethod<int>('getUnlockCountSince', {
      'sinceMillis': since.millisecondsSinceEpoch,
    });
    return count ?? 0;
  }
}
