import '../../models/difficulty_tier.dart';
import '../../models/todo.dart';
import '../model_services.dart';

/// Deterministic stand-in for the on-device SLM's difficulty scoring.
///
/// Uses transparent keyword heuristics so its output is explainable and
/// reproducible in a demo. It is *not* an attempt to approximate a
/// language model's judgement — it can't weigh "is this mechanically
/// easy chore actually important for the future" the way the real
/// scorer is meant to, since that takes reading the task, not matching
/// words. It exists so the whole product loop works before any weights
/// are on the device. See `README.md` in this directory.
class PlaceholderDifficultyScorer implements DifficultyScorer {
  const PlaceholderDifficultyScorer();

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  /// Genuinely learning or building something — the one thing this
  /// heuristic scores high with any confidence.
  static const _learningKeywords = [
    'learn',
    'study',
    'revise',
    'research',
    'practice',
    'read',
    'understand',
    'write',
    'essay',
    'report',
    'assignment',
    'project',
    'prepare',
    'build',
    'design',
    'exam',
    'presentation',
  ];

  /// Mechanically easy paperwork — low weight on its own, but a
  /// high-stakes word alongside one of these should still win, since a
  /// visa form is not the same as a lunch order.
  static const _chOreKeywords = [
    'form',
    'excel',
    'spreadsheet',
    'submit',
    'fill',
    'upload',
    'scan',
    'sign',
  ];

  static const _highStakesKeywords = [
    'exam',
    'application',
    'admission',
    'visa',
    'tax',
    'loan',
    'scholarship',
    'deadline',
    'official',
    'bank',
    'insurance',
    'legal',
    'contract',
  ];

  static const _trivialKeywords = [
    'call',
    'text',
    'email',
    'reply',
    'buy',
    'pick up',
    'water',
    'check',
    'send',
    'pay',
    'book',
  ];

  @override
  Future<DifficultyTier> score({
    required String title,
    String? notes,
    DateTime? deadline,
    List<Todo> nearbyTasks = const [],
  }) async {
    final haystack = '$title ${notes ?? ''}'.toLowerCase();
    final highStakes = _highStakesKeywords.any(haystack.contains);

    if (_chOreKeywords.any(haystack.contains)) {
      // A chore word alone stays cheap; paired with a high-stakes word
      // it's treated as if it were genuinely hard, matching what the
      // real scorer is meant to do for "easy but matters" tasks.
      return highStakes ? DifficultyTier.heavy : DifficultyTier.light;
    }
    if (_learningKeywords.any(haystack.contains)) {
      return highStakes ? DifficultyTier.heavy : DifficultyTier.moderate;
    }
    if (_trivialKeywords.any(haystack.contains)) {
      return DifficultyTier.trivial;
    }

    // Nothing matched a keyword — fall back to length as a weak proxy
    // for how much was specified, which correlates loosely with scope.
    final wordCount = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount >= 8) return DifficultyTier.moderate;
    return DifficultyTier.light;
  }
}
