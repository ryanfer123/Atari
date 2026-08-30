import '../../models/context_bullet.dart';
import '../model_services.dart';

/// Deterministic stand-in for the on-device SLM's explanation layer.
///
/// Produces the same shape the real model is meant to — a couple of
/// calm sentences naming real activity in plain pace language, no
/// advice, no diagnosis, and no judgement of the person themselves
/// (Plans/IMPLEMENTATION.md §4.3) — by filling a fixed template per
/// signal. This is also what the real path falls back to when a
/// model's output fails validation, so the wording is deliberately
/// production-quality rather than a stub.
class PlaceholderSlmExplainer implements SlmExplainer {
  const PlaceholderSlmExplainer();

  @override
  ModelBackend get backend => ModelBackend.placeholder;

  @override
  Future<String> explain({
    required Map<String, double> signalZScores,
    required String topSignal,
    required String timeBucket,
    List<ContextBullet> contextBullets = const [],
    String? recentActivityNote,
  }) async {
    // Symmetric on purpose: a calmer stretch is exactly as legitimate a
    // thing to report as a busier one — this screen exists to say when
    // it's deciding to leave the user alone too, not only when
    // something looks unusually high. Deliberately a pace word
    // ("more/less than usual"), never a character or mood label —
    // this describes what the data shows, not who the person is.
    final z = signalZScores[topSignal];
    final pace = switch (z) {
      null => 'differently than',
      > 0.3 => 'more than',
      < -0.3 => 'less than',
      _ => 'about the same as',
    };

    final phrase = switch (topSignal) {
      'tasks_completed' => "You've completed tasks $pace usual",
      'app_switches' => "You've been switching apps $pace usual",
      'unlocks' => "You've been unlocking your phone $pace usual",
      'notif_latency_ms' => "You've been checking notifications $pace usual",
      _ => 'Your phone activity has been $pace usual',
    };

    final base = timeBucket.isEmpty
        ? '$phrase right now.'
        : '$phrase, compared to your usual $timeBucket.';

    final clauses = <String>[];
    if (recentActivityNote != null && recentActivityNote.isNotEmpty) {
      // The one figure most worth stating plainly, so it leads.
      clauses.add('Specifically, $recentActivityNote.');
    }
    if (contextBullets.isNotEmpty) {
      clauses.add(
        'You have ${contextBullets.take(2).map((b) => b.text).join(' and ')} coming up.',
      );
    }

    if (clauses.isEmpty) return base;
    return '$base ${clauses.join(' ')}';
  }
}
