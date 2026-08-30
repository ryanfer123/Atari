import 'decision_point.dart';
import 'intervention_option.dart';

/// What the decision-rule layer decided to *propose*.
///
/// A proposal, never an action: except for [InterventionOption.defer],
/// nothing here has happened yet — the user must confirm first
/// (Plans/ARCHITECTURE.md §2, Plans/PIVOT_PLAN.md §2.4).
class InterventionSpec {
  const InterventionSpec({
    required this.decisionPoint,
    required this.option,
    required this.decidedAt,
    this.explanation,
    this.suggestedTitle,
    this.suggestedTime,
    this.relatedTodoId,
    this.deferReason,
  });

  /// A decision to do nothing, with the deterministic reason why —
  /// cooldown, low severity, or no model available. A defer is a real,
  /// logged outcome, not a failure to decide.
  const InterventionSpec.defer({
    required this.decisionPoint,
    required this.decidedAt,
    required String reason,
  }) : option = InterventionOption.defer,
       explanation = null,
       suggestedTitle = null,
       suggestedTime = null,
       relatedTodoId = null,
       deferReason = reason;

  final DecisionPoint decisionPoint;
  final InterventionOption option;
  final DateTime decidedAt;

  /// The one-sentence, GoalContext-grounded explanation shown alongside
  /// the proposal. Null when the option needs no explaining.
  final String? explanation;

  final String? suggestedTitle;
  final DateTime? suggestedTime;
  final int? relatedTodoId;
  final String? deferReason;

  bool get isDeferred => option == InterventionOption.defer;

  /// The arm this decision is recorded under once its outcome is
  /// measured — see `banditArmFor`.
  String get banditArm => banditArmFor(option);
}
