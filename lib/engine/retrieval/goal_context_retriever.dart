import '../../core/models/models.dart';
import '../../core/services/i_slm_explainer_service.dart';

/// A locally-stored item in one of the goal-context source categories.
class GoalItem {
  const GoalItem({
    required this.source,
    required this.text,
    this.deadline,
    this.priority = 0,
    this.isCompleted = false,
  });

  final GoalContextSource source;
  final String text;
  final DateTime? deadline;
  final int priority;
  final bool isCompleted;
}

/// Retrieves typed [ContextBullet]s from local stores filtered by the
/// model's masked source selection.
///
/// Each source type has its own retrieval strategy:
/// - **Notes**: Free-text, would use EmbeddingGemma-300M cosine top-k
///   when available; currently returns most-recent.
/// - **Todos**: Structured — direct field filter by deadline proximity
///   and incomplete status.
/// - **Health Targets**: Structured — direct field filter by active
///   targets with measurable thresholds.
/// - **Calendar**: Opt-in, time-range filter (no embed).
/// - **Capture History**: Recently organized items from the capture
///   pipeline.
///
/// Bullets from different sources are concatenated as plain text and
/// never combined in a joint embedding space — see
/// Plans/IMPLEMENTATION.md §0.1, §4.5.
class GoalContextRetriever {
  GoalContextRetriever();

  /// Local stores indexed by source type.
  final Map<GoalContextSource, List<GoalItem>> _stores = {
    for (final source in GoalContextSource.values) source: [],
  };

  /// Add a goal item to the local store.
  void addItem(GoalItem item) {
    _stores[item.source]?.add(item);
  }

  /// Remove completed items from a source.
  void removeCompleted(GoalContextSource source) {
    _stores[source]?.removeWhere((item) => item.isCompleted);
  }

  /// Clear all items from a source.
  void clearSource(GoalContextSource source) {
    _stores[source]?.clear();
  }

  /// Retrieve context bullets from the specified [sources], up to
  /// [maxBulletsPerSource] per source.
  ///
  /// This is called after the masked source selector has chosen which
  /// sources to query. Each source is retrieved independently — no
  /// cross-source fusion.
  List<ContextBullet> retrieve(
    List<GoalContextSource> sources, {
    int maxBulletsPerSource = 3,
  }) {
    final bullets = <ContextBullet>[];
    for (final source in sources) {
      final items = _retrieveFromSource(source, maxBulletsPerSource);
      bullets.addAll(items);
    }
    return bullets;
  }

  /// Full retrieval pipeline: uses [slmService] for masked source
  /// selection, then retrieves bullets from the selected sources.
  Future<List<ContextBullet>> retrieveWithSelection(
    ISlmExplainerService slmService, {
    required String triggerSignal,
    required String topSignal,
    List<GoalContextSource>? allowedSources,
    int maxCalls = 3,
    int maxBulletsPerSource = 3,
  }) async {
    final selection = await slmService.selectSources(
      triggerSignal: triggerSignal,
      topSignal: topSignal,
      allowedSources: allowedSources ?? _nonEmptySources(),
      maxCalls: maxCalls,
    );
    return retrieve(selection.sources, maxBulletsPerSource: maxBulletsPerSource);
  }

  /// Returns sources that have at least one item stored.
  List<GoalContextSource> _nonEmptySources() {
    return _stores.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  List<ContextBullet> _retrieveFromSource(GoalContextSource source, int limit) {
    final items = _stores[source] ?? [];
    switch (source) {
      case GoalContextSource.todos:
        return _retrieveTodos(items, limit);
      case GoalContextSource.healthTargets:
        return _retrieveHealthTargets(items, limit);
      case GoalContextSource.calendar:
        return _retrieveCalendar(items, limit);
      case GoalContextSource.notes:
        return _retrieveNotes(items, limit);
      case GoalContextSource.captureHistory:
        return _retrieveCaptureHistory(items, limit);
    }
  }

  /// Todos: prioritize incomplete items closest to their deadline.
  List<ContextBullet> _retrieveTodos(List<GoalItem> items, int limit) {
    final incomplete = items.where((i) => !i.isCompleted).toList();
    incomplete.sort((a, b) {
      // Items with deadlines first, sorted by deadline proximity.
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return b.priority.compareTo(a.priority);
    });
    return incomplete
        .take(limit)
        .map((i) => ContextBullet(source: 'todo', text: i.text))
        .toList();
  }

  /// Health targets: active targets with measurable thresholds.
  List<ContextBullet> _retrieveHealthTargets(List<GoalItem> items, int limit) {
    final active = items.where((i) => !i.isCompleted).toList();
    return active
        .take(limit)
        .map((i) => ContextBullet(source: 'health', text: i.text))
        .toList();
  }

  /// Calendar: time-range filter, sorted by event time.
  List<ContextBullet> _retrieveCalendar(List<GoalItem> items, int limit) {
    final now = DateTime.now();
    final upcoming = items.where((i) {
      if (i.deadline == null) return true;
      return i.deadline!.isAfter(now);
    }).toList();
    upcoming.sort((a, b) {
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      return 0;
    });
    return upcoming
        .take(limit)
        .map((i) => ContextBullet(source: 'calendar', text: i.text))
        .toList();
  }

  /// Notes: most-recent first (embedding-based top-k when available).
  List<ContextBullet> _retrieveNotes(List<GoalItem> items, int limit) {
    final sorted = List.of(items);
    sorted.sort((a, b) => (b.deadline ?? DateTime(2000)).compareTo(a.deadline ?? DateTime(2000)));
    return sorted
        .take(limit)
        .map((i) => ContextBullet(source: 'note', text: i.text))
        .toList();
  }

  /// Capture history: recently organized items.
  List<ContextBullet> _retrieveCaptureHistory(List<GoalItem> items, int limit) {
    final sorted = List.of(items);
    sorted.sort((a, b) => (b.deadline ?? DateTime(2000)).compareTo(a.deadline ?? DateTime(2000)));
    return sorted
        .take(limit)
        .map((i) => ContextBullet(source: 'capture', text: i.text))
        .toList();
  }
}
