import '../../core/models/context_bullet.dart';
import '../../core/models/todo.dart';
import 'decision_point.dart';

/// The structured, typed input a decision rule reasons over.
///
/// Structured data only — z-scores, bullets, tiers — never raw free text
/// handed to a model ungoverned (Plans/ARCHITECTURE.md §1). Whatever
/// text does reach a prompt goes in as [contextBullets], which are
/// source-attributed and escaped at prompt-build time.
class TailoringVariables {
  const TailoringVariables({
    required this.decisionPoint,
    required this.now,
    this.signalZScores = const {},
    this.severity,
    this.topSignal,
    this.timeBucket = '',
    this.contextBullets = const [],
    this.relatedTodo,
    this.pendingTodoCount = 0,
    this.recentActivityNote,
  });

  final DecisionPoint decisionPoint;
  final DateTime now;

  /// Per-signal z-scores from `BaselineStore`. Empty for decision points
  /// that aren't signal-driven (capture completion, manual check).
  final Map<String, double> signalZScores;

  /// Weighted severity from `OverloadClassifier`, when one fired.
  final double? severity;

  final String? topSignal;

  /// e.g. "Tuesday afternoon" — used verbatim in the explanation
  /// template.
  final String timeBucket;

  final List<ContextBullet> contextBullets;

  /// The task this decision is about, for task-scoped decision points.
  final Todo? relatedTodo;

  final int pendingTodoCount;

  /// A plain-language comparison of the last several days against the
  /// days before that (`ActivityWindow.description`) — distinct from
  /// [timeBucket]'s repeating hour-of-week pattern. Only ever populated
  /// for the manual check today; empty for the others.
  final String? recentActivityNote;
}
