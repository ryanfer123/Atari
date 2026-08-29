import 'dart:async';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../i_sensing_service.dart';
import 'platform_channels.dart';

/// Concrete implementation of [ISensingService] communicating with native Android sensors.
class PlatformSensingService implements ISensingService {
  PlatformSensingService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? PlatformChannels.sensing,
        _eventChannel = eventChannel ?? PlatformChannels.sensingStream;

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  @override
  Future<SignalSnapshot> getCurrentSnapshot({int windowMinutes = 15}) async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'getCurrentSnapshot',
        {'windowMinutes': windowMinutes},
      );
      if (result == null) {
        return SignalSnapshot(
          unlockCount: 0,
          appSwitchCount: 0,
          avgNotifLatencyMs: 0.0,
          windowStart: DateTime.now().subtract(Duration(minutes: windowMinutes)),
          windowEnd: DateTime.now(),
        );
      }
      return SignalSnapshot.fromJson(result);
    } catch (_) {
      return SignalSnapshot(
        unlockCount: 0,
        appSwitchCount: 0,
        avgNotifLatencyMs: 0.0,
        windowStart: DateTime.now().subtract(Duration(minutes: windowMinutes)),
        windowEnd: DateTime.now(),
      );
    }
  }

  @override
  Stream<SignalSnapshot> get snapshotStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => SignalSnapshot.fromJson(Map<String, dynamic>.from(event as Map)));
  }

  @override
  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>('checkPermissions');
      if (result == null) {
        return {'usageAccess': false, 'notificationAccess': false};
      }
      return result.map((k, v) => MapEntry(k, v as bool? ?? false));
    } catch (_) {
      return {'usageAccess': false, 'notificationAccess': false};
    }
  }

  @override
  Future<bool> requestUsagePermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestUsagePermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('requestNotificationPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> recordSimulatedUnlock() async {
    try {
      await _methodChannel.invokeMethod<bool>('recordSimulatedUnlock');
    } catch (_) {}
  }
}
