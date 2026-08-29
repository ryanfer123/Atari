import '../models/models.dart';

/// Contract for Android behavioural sensing and permission telemetry.
abstract class ISensingService {
  /// Fetches the latest signal snapshot in the specified sliding window.
  Future<SignalSnapshot> getCurrentSnapshot({int windowMinutes = 15});

  /// Real-time stream of periodic behavioural snapshots from Android native sensors.
  Stream<SignalSnapshot> get snapshotStream;

  /// Checks grant statuses for special system permissions (Usage Access & Notification Access).
  Future<Map<String, bool>> checkPermissions();

  /// Launches Android System Settings to grant Usage Access.
  Future<bool> requestUsagePermission();

  /// Launches Android System Settings to grant Notification Listener Access.
  Future<bool> requestNotificationPermission();

  /// Injects a synthetic unlock event for debugging / test harness.
  Future<void> recordSimulatedUnlock();
}
