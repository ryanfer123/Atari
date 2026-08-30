import 'task_tool.dart';

/// A scheduled, user-confirmed notification or alarm.
///
/// Nothing reaches this table without an explicit user tap — a model may
/// *propose* a [TaskTool], but only a confirmation turns it into a real
/// scheduled event, because a wrong one has a real-world cost (an alarm
/// firing at 3am). See Plans/PIVOT_PLAN.md §2.4.
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.scheduledFor,
    required this.tool,
    required this.createdAt,
    this.todoId,
    this.healthTargetId,
    this.firedAt,
    this.cancelled = false,
  });

  final int id;
  final String title;
  final DateTime scheduledFor;

  /// Which kind of event this is. Never [TaskTool.none] once persisted —
  /// "no action" means no row was written at all.
  final TaskTool tool;

  final DateTime createdAt;
  final int? todoId;

  /// Set when this is one scheduled occurrence of a health target's
  /// recurring check-in, rather than tied to a todo.
  final int? healthTargetId;

  final DateTime? firedAt;
  final bool cancelled;

  bool get isPending =>
      firedAt == null && !cancelled && scheduledFor.isAfter(DateTime.now());
  bool get isMissed =>
      firedAt == null && !cancelled && scheduledFor.isBefore(DateTime.now());
}
