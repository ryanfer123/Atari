import 'package:flutter/services.dart';

import '../models/task_tool.dart';

/// Schedules real OS-level alarms/notifications for confirmed reminders,
/// over the `atari.dev/reminders` platform channel.
///
/// Only ever called after an explicit user confirmation — a model may
/// propose a [TaskTool], but nothing reaches the OS scheduler without a
/// tap (Plans/PIVOT_PLAN.md §2.4).
class ReminderScheduler {
  ReminderScheduler({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('atari.dev/reminders');

  final MethodChannel _channel;

  /// Whether the OS will let us post notifications and schedule exact
  /// alarms. Both are runtime-grantable on modern Android, unlike the
  /// special-access permissions the signal collectors need.
  Future<bool> hasPermissions() async {
    final granted = await _channel.invokeMethod<bool>('hasPermissions');
    return granted ?? false;
  }

  /// Requests notification permission (Android 13+) and, for alarms,
  /// sends the user to the exact-alarm settings screen if needed.
  Future<bool> requestPermissions() async {
    final granted = await _channel.invokeMethod<bool>('requestPermissions');
    return granted ?? false;
  }

  /// Schedules [id] to fire at [scheduledFor].
  ///
  /// [id] must be the persisted `Reminder.id` so a later [cancel] can
  /// target the same OS alarm. Returns false if the platform refused
  /// (e.g. permission revoked between confirm and schedule) — callers
  /// surface that rather than silently pretending it was set.
  Future<bool> schedule({
    required int id,
    required String title,
    required DateTime scheduledFor,
    required TaskTool tool,
  }) async {
    final ok = await _channel.invokeMethod<bool>('schedule', {
      'id': id,
      'title': title,
      'scheduledForMillis': scheduledFor.millisecondsSinceEpoch,
      'tool': tool.name,
    });
    return ok ?? false;
  }

  Future<void> cancel(int id) {
    return _channel.invokeMethod<void>('cancel', {'id': id});
  }
}
