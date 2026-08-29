import 'package:flutter/services.dart';

/// Dart-side client for whether the native foreground
/// `SignalCollectionService` (`android/.../SignalCollectionService.kt`) is
/// currently running — the service that keeps signal collectors alive
/// when the app itself is closed. Shares the `atari.dev/signals` channel
/// with the per-tracker services (e.g. `UnlockSignalService`).
class SignalCollectionStatusService {
  SignalCollectionStatusService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/signals');

  final MethodChannel _channel;

  Future<bool> isRunning() async {
    final running = await _channel.invokeMethod<bool>(
      'isCollectionServiceRunning',
    );
    return running ?? false;
  }
}
