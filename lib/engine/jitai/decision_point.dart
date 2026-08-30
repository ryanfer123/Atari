/// The fixed, enumerable set of moments the system may act.
///
/// "Never whenever the model feels like it" — a closed enum is what
/// makes the system's behaviour auditable. Every one of these feeds the
/// *same* decision-rule layer (`DecisionEngine`); none gets its own
/// private pipeline. See Plans/ARCHITECTURE.md §1–§2.
enum DecisionPoint {
  /// A. The user finished a capture and confirmed an item. Primary,
  /// user-initiated — this is the product's core loop.
  captureCompleted,

  /// B. A todo's deadline is approaching. Scheduled.
  todoDueSoon,

  /// C. The background overload classifier fired. Secondary — one input
  /// among four, deliberately not the headline (ARCHITECTURE §4).
  overloadSignal,

  /// D. The user (or a demo operator) asked for a check explicitly.
  /// Also the demo's fallback trigger, since live signal-triggering on
  /// stage is a risk (Plans/IMPLEMENTATION.md §6).
  manualCheck,
}

String decisionPointLabel(DecisionPoint point) => switch (point) {
  DecisionPoint.captureCompleted => 'Capture completed',
  DecisionPoint.todoDueSoon => 'Task due soon',
  DecisionPoint.overloadSignal => 'Overload signal',
  DecisionPoint.manualCheck => 'Manual check',
};
