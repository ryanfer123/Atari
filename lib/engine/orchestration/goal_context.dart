import '../../core/models/context_bullet.dart';

/// One note match from cosine top-k retrieval over on-device note
/// embeddings (EmbeddingGemma-300M, backend-native).
class NoteMatch {
  const NoteMatch({required this.text});
  final String text;
}

class TodoSummary {
  const TodoSummary({required this.title, required this.deadline});
  final String title;
  final DateTime deadline;
}

class HealthTargetSummary {
  const HealthTargetSummary({required this.metric, required this.threshold});
  final String metric;
  final String threshold;
}

class CalendarEventSummary {
  const CalendarEventSummary({required this.title, required this.startTime});
  final String title;
  final DateTime startTime;
}

/// A prior captured-and-organized item (§4.6), retrievable like any other
/// GoalContext source.
class CaptureHistoryEntry {
  const CaptureHistoryEntry({required this.summary});
  final String summary;
}

/// Cosine top-k over on-device note vectors. Implemented by backend-native's
/// embedder; tests and early integration supply a fake.
typedef NotesTopKLookup = Future<List<NoteMatch>> Function(String query, int k);
typedef TodosDueWithinLookup = Future<List<TodoSummary>> Function(
  DateTime now,
  Duration window,
);
typedef HealthTargetsLookup = Future<List<HealthTargetSummary>> Function();
typedef CalendarEventsWithinLookup =
    Future<List<CalendarEventSummary>> Function(DateTime now, Duration window);
typedef CaptureHistoryLookup = Future<List<CaptureHistoryEntry>> Function(
  DateTime now,
  Duration window,
);

/// Retrieval-per-source, no fusion: each source is queried independently
/// and combined only as flat text bullets right before the SLM prompt is
/// built, never as a joint embedding space.
///
/// Which sources are queried for a given call is the caller's choice — see
/// [MaskedSourceSelector] for how that choice is made safely by the model.
/// The core overload-detection loop never depends on this class at all;
/// it's an enrichment `SlmExplainer`'s prompt optionally uses.
///
/// See Plans/IMPLEMENTATION.md §0.1, §4.5, §0.4.
class GoalContext {
  GoalContext({
    required NotesTopKLookup notesTopK,
    required TodosDueWithinLookup todosDueWithin,
    required HealthTargetsLookup activeHealthTargets,
    CalendarEventsWithinLookup? calendarEventsWithin,
    CaptureHistoryLookup? captureHistoryWithin,
  }) : _notesTopK = notesTopK,
       _todosDueWithin = todosDueWithin,
       _activeHealthTargets = activeHealthTargets,
       _calendarEventsWithin = calendarEventsWithin,
       _captureHistoryWithin = captureHistoryWithin;

  final NotesTopKLookup _notesTopK;
  final TodosDueWithinLookup _todosDueWithin;
  final HealthTargetsLookup _activeHealthTargets;

  /// `null` if the user hasn't opted into calendar access — see §5.1. The
  /// nullability *is* the opt-in architecture: [retrieve] works correctly
  /// with zero, one, or all sources present.
  final CalendarEventsWithinLookup? _calendarEventsWithin;

  /// `null` if capture history retrieval isn't wired up yet.
  final CaptureHistoryLookup? _captureHistoryWithin;

  static const _notesTopKCount = 2;
  static const _todoWindow = Duration(hours: 2);
  static const _calendarWindow = Duration(hours: 1);
  static const _captureHistoryWindow = Duration(hours: 2);

  /// Retrieves flat context bullets from exactly the sources named in
  /// [sources] (typically [SourceSelection.sources] from
  /// [MaskedSourceSelector]), scoping notes by [triggerSignal] and windowed
  /// sources relative to [now].
  ///
  /// A source in [sources] that has no lookup configured (calendar/capture
  /// history when the user hasn't opted in or the integration isn't wired
  /// up yet) is silently skipped rather than treated as an error.
  Future<List<ContextBullet>> retrieve({
    required String triggerSignal,
    required DateTime now,
    required List<GoalContextSource> sources,
  }) async {
    final bullets = <ContextBullet>[];

    if (sources.contains(GoalContextSource.notes)) {
      final notes = await _notesTopK(triggerSignal, _notesTopKCount);
      bullets.addAll(
        notes.map((n) => ContextBullet(source: 'note', text: n.text)),
      );
    }
    if (sources.contains(GoalContextSource.todos)) {
      final todos = await _todosDueWithin(now, _todoWindow);
      bullets.addAll(
        todos.map(
          (t) => ContextBullet(
            source: 'todo',
            text: '${t.title} (due ${t.deadline})',
          ),
        ),
      );
    }
    if (sources.contains(GoalContextSource.healthTargets)) {
      final targets = await _activeHealthTargets();
      bullets.addAll(
        targets.map(
          (h) => ContextBullet(
            source: 'health',
            text: '${h.metric} target: ${h.threshold}',
          ),
        ),
      );
    }
    if (sources.contains(GoalContextSource.calendar) &&
        _calendarEventsWithin != null) {
      final events = await _calendarEventsWithin(now, _calendarWindow);
      bullets.addAll(
        events.map(
          (e) => ContextBullet(
            source: 'calendar',
            text: '${e.title} at ${e.startTime}',
          ),
        ),
      );
    }
    if (sources.contains(GoalContextSource.captureHistory) &&
        _captureHistoryWithin != null) {
      final captures = await _captureHistoryWithin(now, _captureHistoryWindow);
      bullets.addAll(
        captures.map((c) => ContextBullet(source: 'capture', text: c.summary)),
      );
    }

    return bullets;
  }
}
