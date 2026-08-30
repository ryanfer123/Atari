import '../../core/models/agent_state.dart';
import '../../core/models/overload_event.dart';
import '../../core/services/model_services.dart';
import '../feedback/intervention_bandit.dart';
import '../orchestration/orchestrator.dart';
import 'decision_point.dart';
import 'intervention_option.dart';
import 'intervention_spec.dart';
import 'tailoring_variables.dart';

/// The single decision-rule layer every decision point feeds into.
///
/// This is the structural answer to "why is overload detection
/// different from the rest of the app": it isn't. Capture completion, a
/// due-soon todo, an overload signal and a manual check all arrive here
/// and are resolved by the same deterministic guards plus the same
/// bandit — none of them gets a private pipeline
/// (Plans/ARCHITECTURE.md §2, §4).
///
/// Two layers, in order:
/// 1. **Deterministic** — `Orchestrator`'s state machine and cooldown
///    can veto outright. No model is consulted if the answer is already
///    "not now".
/// 2. **Model-assisted** — only ever a masked, schema-validated,
///    single-shot selection from a closed enum, with a deterministic
///    fallback. Never open generation, never a retry loop.
class DecisionEngine {
  DecisionEngine({
    required Orchestrator orchestrator,
    required InterventionBandit bandit,
    required SlmExplainer explainer,
    DateTime Function() now = DateTime.now,
  }) : _orchestrator = orchestrator,
       _bandit = bandit,
       _explainer = explainer,
       _now = now;

  final Orchestrator _orchestrator;
  final InterventionBandit _bandit;
  final SlmExplainer _explainer;
  final DateTime Function() _now;

  AgentState get agentState => _orchestrator.state;

  /// Resolves one decision point into a proposal.
  Future<InterventionSpec> decide(TailoringVariables variables) async {
    final at = _now();

    return switch (variables.decisionPoint) {
      // A. The user just confirmed a capture. They are already engaged
      // and asked for this, so no cooldown gate applies — proposing a
      // reminder here is continuing their action, not interrupting.
      DecisionPoint.captureCompleted => _proposeForTask(
        variables,
        at,
        InterventionOption.setReminder,
      ),

      // B. A deadline is approaching. Same reasoning: time-bound and
      // user-authored, so it isn't gated by the interruption cooldown.
      DecisionPoint.todoDueSoon => _proposeForTask(
        variables,
        at,
        InterventionOption.setReminder,
      ),

      // C. Unsolicited. This is the only path that can genuinely
      // interrupt, so it's the only one the Orchestrator gates.
      DecisionPoint.overloadSignal => await _decideForOverload(variables, at),

      // D. Explicitly asked for, so it always answers — that's what
      // makes it usable as the demo's fallback trigger.
      DecisionPoint.manualCheck => await _explainOverlay(
        variables,
        at,
        gated: false,
      ),
    };
  }

  InterventionSpec _proposeForTask(
    TailoringVariables variables,
    DateTime at,
    InterventionOption option,
  ) {
    final todo = variables.relatedTodo;
    return InterventionSpec(
      decisionPoint: variables.decisionPoint,
      option: option,
      decidedAt: at,
      suggestedTitle: todo?.title,
      suggestedTime: todo?.deadline,
      relatedTodoId: todo?.id,
    );
  }

  Future<InterventionSpec> _decideForOverload(
    TailoringVariables variables,
    DateTime at,
  ) async {
    final severity = variables.severity;
    if (severity == null) {
      return InterventionSpec.defer(
        decisionPoint: variables.decisionPoint,
        decidedAt: at,
        reason: 'no overload event: signals stayed under threshold',
      );
    }

    // Deterministic guard first — the Orchestrator owns "may we
    // interrupt at all", including the cooldown window. A vetoed
    // decision never reaches the model.
    final mayIntervene = _orchestrator.onOverloadEvent(
      OverloadEvent(
        timestamp: at,
        signalScores: variables.signalZScores,
        severity: severity,
      ),
    );
    if (!mayIntervene) {
      return InterventionSpec.defer(
        decisionPoint: variables.decisionPoint,
        decidedAt: at,
        reason:
            'cooldown or intervention already in progress (state: ${_orchestrator.state.name})',
      );
    }

    return _explainOverlay(variables, at, gated: true);
  }

  Future<InterventionSpec> _explainOverlay(
    TailoringVariables variables,
    DateTime at, {
    required bool gated,
  }) async {
    // The bandit chooses among arms; overlay is the arm this decision
    // point can actually deliver today. Recording the choice is what
    // makes the outcome measurable later (`recordOutcome`).
    final arm = _bandit.choose();

    final explanation = await _explainer.explain(
      signalZScores: variables.signalZScores,
      topSignal: variables.topSignal ?? 'app_switches',
      timeBucket: variables.timeBucket,
      contextBullets: variables.contextBullets,
      recentActivityNote: variables.recentActivityNote,
    );

    return InterventionSpec(
      decisionPoint: variables.decisionPoint,
      option: arm == banditArmFor(InterventionOption.defer)
          ? InterventionOption.defer
          : InterventionOption.showOverlay,
      decidedAt: at,
      explanation: explanation,
      deferReason: arm == banditArmFor(InterventionOption.defer)
          ? 'bandit selected defer'
          : null,
    );
  }

  /// Closes the loop: records how an intervention actually performed so
  /// the bandit's weights update. Called by `FeedbackLoop` once the
  /// post-intervention window has been re-measured
  /// (Plans/ARCHITECTURE.md §2's outcome-logging layer).
  ///
  /// A negative or zero [effectSize] is legitimate signal, not an error.
  void recordOutcome(InterventionSpec spec, double effectSize) {
    _bandit.record(spec.banditArm, effectSize);
  }

  /// Signals that a shown intervention was dismissed or elapsed, so the
  /// state machine can leave `intervening`/`cooldown`.
  void onInterventionShown() => _orchestrator.onInterventionShown();
  void onCooldownElapsed() => _orchestrator.onCooldownElapsed();
}
