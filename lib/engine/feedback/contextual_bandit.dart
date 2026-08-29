import 'dart:math';

/// Intervention types the bandit can choose between.
///
/// See Plans/IMPLEMENTATION.md §4.2 / §4.3.
enum InterventionType {
  focusShield,
  takeABreak,
  breatheDeep,
  hydrationWalk,
}

/// Record of a completed intervention and its measured effect.
class InterventionOutcome {
  const InterventionOutcome({
    required this.type,
    required this.preScore,
    required this.postScore,
    required this.timestamp,
  });

  final InterventionType type;
  final double preScore;
  final double postScore;
  final DateTime timestamp;

  /// Cohen's d effect size: positive means fragmentation went down.
  double get effectSize => preScore - postScore;
}

/// Epsilon-greedy contextual multi-armed bandit for intervention selection.
///
/// Each arm is an [InterventionType]. The bandit maintains a running average
/// reward (effect size) per arm and picks the best arm with probability
/// `1 - epsilon`, or a random arm with probability `epsilon`.
///
/// Context is the trigger signal name — the bandit maintains separate arm
/// weights per context to learn which intervention works best for each
/// pattern (e.g. high app-switching vs. high unlocks).
///
/// See Plans/IMPLEMENTATION.md §4.3.
class ContextualBandit {
  ContextualBandit({this.epsilon = 0.15});

  final double epsilon;
  final _random = Random();

  /// context → arm → (totalReward, count).
  final Map<String, Map<InterventionType, _ArmStats>> _arms = {};

  /// Select the best intervention for the given [triggerSignal] context.
  InterventionType select(String triggerSignal) {
    final contextArms = _arms[triggerSignal];

    // Cold start: explore uniformly.
    if (contextArms == null || contextArms.isEmpty) {
      return InterventionType.values[_random.nextInt(InterventionType.values.length)];
    }

    // Epsilon-greedy: explore with probability epsilon.
    if (_random.nextDouble() < epsilon) {
      return InterventionType.values[_random.nextInt(InterventionType.values.length)];
    }

    // Exploit: pick the arm with the highest average reward.
    InterventionType bestArm = InterventionType.focusShield;
    var bestReward = double.negativeInfinity;

    for (final entry in contextArms.entries) {
      final avg = entry.value.averageReward;
      if (avg > bestReward) {
        bestReward = avg;
        bestArm = entry.key;
      }
    }

    return bestArm;
  }

  /// Record the outcome of an intervention for future learning.
  void recordOutcome(InterventionOutcome outcome, String triggerSignal) {
    _arms.putIfAbsent(triggerSignal, () => {});
    final arm = _arms[triggerSignal]!;
    arm.putIfAbsent(outcome.type, () => _ArmStats());
    arm[outcome.type]!.update(outcome.effectSize);
  }

  /// Get the current average reward for each arm in a given context.
  Map<InterventionType, double> armRewards(String triggerSignal) {
    final contextArms = _arms[triggerSignal];
    if (contextArms == null) return {};
    return contextArms.map((k, v) => MapEntry(k, v.averageReward));
  }
}

class _ArmStats {
  double totalReward = 0.0;
  int count = 0;

  double get averageReward => count > 0 ? totalReward / count : 0.0;

  void update(double reward) {
    totalReward += reward;
    count++;
  }
}
