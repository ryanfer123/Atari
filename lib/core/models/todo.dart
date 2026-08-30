import 'difficulty_tier.dart';

/// A user task. Created by hand, or from a confirmed capture
/// (`CapturedItemParser` → review screen → save).
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    this.deadline,
    this.difficulty,
    this.completedAt,
    this.notes,
    this.parentId,
  });

  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime? deadline;

  /// Assigned by `DifficultyScorer` (a model decision constrained to
  /// [DifficultyTier]), or null until scored. Drives the XP award on
  /// completion — see `xpForDifficulty`.
  final DifficultyTier? difficulty;

  final DateTime? completedAt;
  final String? notes;

  /// Set when this todo is a subtask created by decomposing another
  /// todo (Plans/PIVOT_PLAN.md §2.3).
  final int? parentId;

  bool get isCompleted => completedAt != null;
  bool get isSubtask => parentId != null;

  bool get isOverdue {
    final due = deadline;
    return due != null && !isCompleted && due.isBefore(DateTime.now());
  }

  Todo copyWith({
    String? title,
    DateTime? deadline,
    bool clearDeadline = false,
    DifficultyTier? difficulty,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? notes,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      difficulty: difficulty ?? this.difficulty,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      notes: notes ?? this.notes,
      parentId: parentId,
    );
  }
}
