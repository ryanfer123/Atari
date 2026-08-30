/// The only four difficulty levels a model may ever assign to a task.
///
/// A closed enum, not a free-form score: the model picks one of these or
/// the app falls back to a deterministic default — it can never invent a
/// number. Same masked-selection pattern as `GoalContextSource`
/// (Plans/IMPLEMENTATION.md §4.8), applied here per
/// Plans/PIVOT_PLAN.md §2.3.
enum DifficultyTier { trivial, light, moderate, heavy }

/// XP awarded for completing a task of each tier.
///
/// Deliberately app-side deterministic code, not something the model
/// emits — the model chooses a *tier*, the app decides what that tier is
/// worth. Keeps reward tuning a product decision rather than a model
/// output. See Plans/PIVOT_PLAN.md §2.3.
int xpForDifficulty(DifficultyTier tier) => switch (tier) {
  DifficultyTier.trivial => 5,
  DifficultyTier.light => 10,
  DifficultyTier.moderate => 20,
  DifficultyTier.heavy => 30,
};

/// Human-readable label for UI display.
String difficultyLabel(DifficultyTier tier) => switch (tier) {
  DifficultyTier.trivial => 'Trivial',
  DifficultyTier.light => 'Light',
  DifficultyTier.moderate => 'Moderate',
  DifficultyTier.heavy => 'Heavy',
};

/// Tier assigned when no model is available or its output failed
/// validation. Middle-of-the-road on purpose: a wrong guess costs only a
/// slightly-off XP number (Plans/PIVOT_PLAN.md §2.4's "safe to
/// automate" side of the line), so a neutral default is better than
/// blocking the user on a confirmation prompt.
const DifficultyTier fallbackDifficultyTier = DifficultyTier.light;
