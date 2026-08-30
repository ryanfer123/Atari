import '../models/captured_item.dart';
import '../models/context_bullet.dart';
import '../models/difficulty_tier.dart';
import '../models/subtask_spec.dart';
import '../models/todo.dart';

/// Which implementation is answering — surfaced in the UI so it's always
/// obvious whether a real on-device model produced a result or the
/// deterministic placeholder did. See
/// `lib/core/services/placeholders/README.md`.
enum ModelBackend {
  /// Deterministic, rule-based stand-in. No model weights involved.
  placeholder,

  /// A real on-device model (Qwen3-4B / EmbeddingGemma / PP-OCR).
  onDevice,
}

/// Assigns a task one of the four fixed [DifficultyTier] values.
///
/// The model never emits a number — it selects from a closed set, and
/// the app maps that tier to XP deterministically (`xpForDifficulty`).
/// See Plans/PIVOT_PLAN.md §2.3.
abstract class DifficultyScorer {
  ModelBackend get backend;

  /// Returns a tier for [title] — a weight for how much this task
  /// *deserves*, not an estimate of how long it takes. Genuinely
  /// learning something scores higher; a mechanically easy chore (a
  /// routine form, a spreadsheet) scores low unless it clearly matters
  /// for the person's future, in which case it scores as if it were
  /// hard. That distinction is exactly why this is a model call rather
  /// than a keyword rule — see `OnDeviceDifficultyScorer`.
  ///
  /// [deadline] and [nearbyTasks] (other incomplete todos due near
  /// [deadline], both optional) let the scorer weigh this task against
  /// what else is already due around the same time, rather than only
  /// in isolation. Neither is required — a task with no deadline is
  /// still scored on its own text.
  ///
  /// Implementations must never throw: on any failure or malformed
  /// model output they return [fallbackDifficultyTier], because a
  /// slightly-wrong XP number is a tolerable cost (Plans/PIVOT_PLAN.md
  /// §2.4) but a crash is not.
  Future<DifficultyTier> score({
    required String title,
    String? notes,
    DateTime? deadline,
    List<Todo> nearbyTasks = const [],
  });
}

/// Breaks a task into at most [maxSubtasks] steps.
///
/// Returns `DecompositionResult.fallback(...)` — an empty subtask list —
/// rather than retrying when output is malformed or over the cap. There
/// is deliberately no retry loop; see Plans/PIVOT_PLAN.md §2.3.
abstract class TaskDecomposer {
  ModelBackend get backend;

  Future<DecompositionResult> decompose({required String title, String? notes});
}

/// Produces the single plain sentence shown with an intervention.
///
/// Fixed template, one sentence, no advice and no diagnosis — see
/// Plans/IMPLEMENTATION.md §4.3 and the ownership boundary in
/// `native/model/README.md`.
abstract class SlmExplainer {
  ModelBackend get backend;

  /// [recentActivityNote], when given, is a plain-language comparison
  /// of the last several days against the days before that — e.g. "42
  /// unlocks a day over the last 5 days, versus 28 a day the 5 days
  /// before that" (`ActivityWindow.description`). It is a distinct
  /// fact from [timeBucket] (a repeating hour-of-week pattern like
  /// "Tuesday afternoon") and from [contextBullets] (upcoming
  /// deadlines) — restated on its own line rather than forced into
  /// either.
  Future<String> explain({
    required Map<String, double> signalZScores,
    required String topSignal,
    required String timeBucket,
    List<ContextBullet> contextBullets = const [],
    String? recentActivityNote,
  });
}

/// Extracts text from a captured image region.
///
/// The real implementation is PP-OCR behind a platform channel; the
/// placeholder returns canned text so the whole capture → review → save
/// flow is testable and demoable without any model.
abstract class OcrService {
  ModelBackend get backend;

  /// [imagePath] is a file on the device. Returns raw, unstructured
  /// text — `CapturedItemParser` is what turns it into a candidate
  /// item, and the user always reviews it before saving
  /// (Plans/IMPLEMENTATION.md §4.6).
  Future<OcrResult> extractText(String imagePath);
}

class OcrResult {
  const OcrResult({
    required this.text,
    required this.confidence,
    required this.backend,
  });

  final String text;
  final double confidence;
  final ModelBackend backend;
}

/// Decides whether a line of text is a task, a note, or a health target.
///
/// A fourth masked enum in the sense of Plans/PIVOT_PLAN.md §2.3: the
/// model selects from [ItemType] and nothing else. Misfiling is cheap and
/// visible — the user sees the chosen type on a chip and can change it
/// before anything is written — which is what puts this on the
/// safe-to-automate side of §2.4.
abstract class ItemClassifier {
  ModelBackend get backend;

  /// Implementations must never throw; on any failure they return a
  /// deterministic guess so a batch of pasted lines always sorts into
  /// *something* the user can correct.
  Future<ItemType> classify(String text);
}

/// Ranks notes against a query.
///
/// The real implementation is EmbeddingGemma-300M cosine top-k; the
/// placeholder is keyword overlap. Notes are the only source that would
/// ever use embeddings — todos and health targets are structured records
/// queried by field filter (Plans/IMPLEMENTATION.md §2).
abstract class NoteSearchService {
  ModelBackend get backend;

  /// Returns note ids ranked most-relevant first, at most [k].
  Future<List<int>> topK({
    required String query,
    required Map<int, String> notesById,
    int k = 2,
  });
}
