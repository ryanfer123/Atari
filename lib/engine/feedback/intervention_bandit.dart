import 'dart:math' as math;

/// Epsilon-greedy bandit over intervention variants (e.g. "focus layer" vs.
/// "single suggested-break notification").
///
/// Epsilon-greedy, not UCB/Thompson sampling — chosen because expected
/// trial count over the build/demo window is only ~5-25 (HeartSteps
/// real-world JITAI cadence), too few for a confidence-bound or
/// posterior-sampling algorithm to earn its added complexity. See
/// Plans/IMPLEMENTATION.md §4.4.
class InterventionBandit {
  InterventionBandit({
    required this.arms,
    this.epsilon = 0.2,
    math.Random? random,
  }) : assert(arms.isNotEmpty, 'InterventionBandit needs at least one arm'),
       _random = random ?? math.Random();

  final List<String> arms;

  /// Probability of picking a uniformly random arm instead of the current
  /// best. Also effectively 1.0 for any arm that has never been pulled —
  /// every arm gets tried before averages are trusted.
  final double epsilon;

  final math.Random _random;

  final Map<String, double> _effectSums = {};
  final Map<String, int> _pulls = {};

  /// Picks an arm: explores (uniformly random) with probability [epsilon],
  /// or whenever some arm has zero pulls; otherwise exploits the arm with
  /// the highest running average effect size.
  String choose() {
    final hasUnpulledArm = arms.any((arm) => (_pulls[arm] ?? 0) == 0);
    if (hasUnpulledArm || _random.nextDouble() < epsilon) {
      return arms[_random.nextInt(arms.length)];
    }
    return arms.reduce(
      (best, arm) =>
          averageEffectFor(arm) > averageEffectFor(best) ? arm : best,
    );
  }

  /// Records one trial's outcome for [arm].
  ///
  /// [effectSize] is the fractional signal drop after the intervention,
  /// e.g. `0.08` = 8% reduction (good). A negative or near-zero
  /// [effectSize] is a legitimate outcome, not an error — it naturally
  /// down-weights that arm's running average; callers must not special-case
  /// "no effect" as a failure to discard.
  void record(String arm, double effectSize) {
    _effectSums[arm] = (_effectSums[arm] ?? 0) + effectSize;
    _pulls[arm] = (_pulls[arm] ?? 0) + 1;
  }

  /// Number of times [arm] has been recorded via [record].
  int pullsFor(String arm) => _pulls[arm] ?? 0;

  /// Running average effect size for [arm]; `0` if it has never been pulled.
  double averageEffectFor(String arm) {
    final pulls = _pulls[arm] ?? 0;
    if (pulls == 0) return 0;
    return (_effectSums[arm] ?? 0) / pulls;
  }
}
