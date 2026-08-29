/// Population-default prior mean/std per signal, used to blend a personal
/// baseline during cold start (`SignalBucketStats.blendedMean`/`zScore`) and
/// as the standalone std for buckets with fewer than five observations.
///
/// There is no published number for these — nothing in RESEARCH.md's
/// literature review provides phone-overload-signal population baselines.
/// These are placeholder defaults pending real dogfooding data and are the
/// project's own empirical contribution, not a cited figure. Replace each
/// value once enough personal usage data has been collected to estimate it
/// properly, and note the replacement in RESEARCH.md's coverage-gap list.
///
/// See Plans/IMPLEMENTATION.md §4.1.
class PopulationPrior {
  const PopulationPrior({required this.mean, required this.std});

  final double mean;
  final double std;
}

/// Keyed by signal name (`unlocks`, `app_switches`, `notif_latency_ms`).
const Map<String, PopulationPrior> defaultPopulationPriors = {
  // Unlocks per rolling hour-bucket window. Placeholder: a handful of
  // unlocks per waking hour is unremarkable; dogfooding should replace this.
  'unlocks': PopulationPrior(mean: 3, std: 2),

  // Foreground app-switch count per rolling window (see
  // AppSwitchTracker/backend-native). Placeholder pending real data.
  'app_switches': PopulationPrior(mean: 8, std: 5),

  // Milliseconds between a notification posting and the next unlock/
  // dismissal. Placeholder pending real data; wide std reflects that
  // notification-response latency is naturally high-variance.
  'notif_latency_ms': PopulationPrior(mean: 45000, std: 60000),
};
