import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../database/health_target_repository.dart';
import '../database/capture_repository.dart';
import '../database/note_repository.dart';
import '../database/reminder_repository.dart';
import '../database/todo_repository.dart';
import '../models/task_tool.dart';
import '../../engine/feedback/intervention_bandit.dart';
import '../../engine/gamification/gamification_engine.dart';
import '../../engine/jitai/decision_engine.dart';
import '../../engine/jitai/intervention_option.dart';
import '../../engine/orchestration/orchestrator.dart';
import 'embedding_service.dart';
import 'model_services.dart';
import 'placeholders/placeholder_difficulty_scorer.dart';
import 'placeholders/placeholder_embedding_service.dart';
import 'placeholders/placeholder_item_classifier.dart';
import 'placeholders/placeholder_ocr_service.dart';
import 'placeholders/placeholder_slm_explainer.dart';
import 'placeholders/placeholder_task_decomposer.dart';
import 'reminder_scheduler.dart';
import 'screen_capture_service.dart';

/// Everything the UI needs, constructed once at startup.
///
/// **To swap a placeholder for a real on-device model**, pass the real
/// implementation here — that is the only change required; no UI or
/// engine code references a concrete implementation. See
/// `placeholders/README.md`.
class AppServices {
  AppServices({
    required this.database,
    DifficultyScorer? difficultyScorer,
    TaskDecomposer? taskDecomposer,
    SlmExplainer? slmExplainer,
    ItemClassifier? itemClassifier,
    OcrService? ocrService,
    EmbeddingService? embedder,
    ReminderScheduler? reminderScheduler,
    ScreenCaptureService? screenCapture,
  }) : embedder = embedder ?? const PlaceholderEmbeddingService(),
       todos = TodoRepository(database),
       // Notes and captures embed on write, so both repositories need
       // the embedder rather than reaching for it at query time.
       notes = NoteRepository(
         database,
         embedder ?? const PlaceholderEmbeddingService(),
       ),
       captures = CaptureRepository(
         database,
         embedder ?? const PlaceholderEmbeddingService(),
       ),
       healthTargets = HealthTargetRepository(database),
       reminders = ReminderRepository(database),
       gamification = GamificationEngine(database),
       difficultyScorer =
           difficultyScorer ?? const PlaceholderDifficultyScorer(),
       taskDecomposer = taskDecomposer ?? const PlaceholderTaskDecomposer(),
       slmExplainer = slmExplainer ?? const PlaceholderSlmExplainer(),
       itemClassifier = itemClassifier ?? const PlaceholderItemClassifier(),
       ocrService = ocrService ?? const PlaceholderOcrService(),
       reminderScheduler = reminderScheduler ?? ReminderScheduler(),
       screenCapture = screenCapture ?? ScreenCaptureService() {
    // One shared decision-rule layer for all four decision points — see
    // DecisionEngine's doc comment and Plans/ARCHITECTURE.md §2.
    decisionEngine = DecisionEngine(
      orchestrator: Orchestrator(),
      bandit: InterventionBandit(
        arms: [
          banditArmFor(InterventionOption.showOverlay),
          banditArmFor(InterventionOption.setReminder),
        ],
      ),
      explainer: this.slmExplainer,
    );
  }

  final AppDatabase database;

  final TodoRepository todos;
  final NoteRepository notes;

  /// Saved captures, embedded on write.
  final CaptureRepository captures;
  final HealthTargetRepository healthTargets;
  final ReminderRepository reminders;
  final GamificationEngine gamification;

  final DifficultyScorer difficultyScorer;
  final TaskDecomposer taskDecomposer;
  final SlmExplainer slmExplainer;

  /// Decides whether a jotted line is a task, a note, or a health target.
  final ItemClassifier itemClassifier;

  final OcrService ocrService;

  /// Turns free text into vectors so notes and captures are searchable
  /// by meaning. Only free-text sources are embedded.
  final EmbeddingService embedder;
  final ReminderScheduler reminderScheduler;

  /// Circle-to-Search capture, driven by the Android overlay service.
  final ScreenCaptureService screenCapture;

  /// The user's light/dark choice, made from Settings — no system
  /// option, so this is always the theme actually in effect rather than
  /// deferring to the device's. Starts at [ThemeMode.dark] and is
  /// overwritten once `ThemeModeStore.read()` resolves at startup — a
  /// `ValueNotifier` rather than a plain field because `AtariApp` needs
  /// to rebuild `MaterialApp.themeMode` when Settings changes it,
  /// without `ServiceScope` itself needing to notify (see its doc
  /// comment on why it deliberately doesn't).
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  /// The shared decision-rule layer. Every decision point resolves
  /// through this one object.
  late final DecisionEngine decisionEngine;

  /// Capabilities still answered by a deterministic placeholder, named
  /// in the words the user sees them by.
  ///
  /// Reported per-capability rather than all-or-nothing: slots fill in
  /// one at a time (OCR needs only ~21MB of ONNX files, the language
  /// model a 2.5GB GGUF), so a single "no models loaded" flag would
  /// have to lie in one direction or the other as soon as the first
  /// slot was filled.
  List<String> get placeholderCapabilities => [
    if (ocrService.backend == ModelBackend.placeholder) 'text extraction',
    if (itemClassifier.backend == ModelBackend.placeholder ||
        difficultyScorer.backend == ModelBackend.placeholder ||
        taskDecomposer.backend == ModelBackend.placeholder ||
        slmExplainer.backend == ModelBackend.placeholder)
      'difficulty and explanations',
    if (embedder.backend == ModelBackend.placeholder) 'semantic search',
  ];

  /// Deletes a todo, its subtasks, and their reminders — and cancels the
  /// OS alarms those reminders had scheduled.
  ///
  /// This pairing is why it lives here rather than in the repository: a
  /// repository has no business talking to AlarmManager, but deleting
  /// only the row would leave the phone still ringing for a task the
  /// user deliberately removed. Cancelling is best-effort — a failure
  /// there must not leave the row behind, because a stale alarm is
  /// recoverable and an undeletable task is not.
  Future<void> deleteTodo(int id) async {
    final cancelledReminderIds = await todos.delete(id);
    for (final reminderId in cancelledReminderIds) {
      try {
        await reminderScheduler.cancel(reminderId);
      } catch (e) {
        debugPrint('Could not cancel alarm $reminderId: $e');
      }
    }
  }

  /// Deletes a health target and cancels the OS alarms for any
  /// reminders its recurring schedule had created. Mirrors [deleteTodo]
  /// for the same reason: the row and the real-world alarm are two
  /// different things, and only removing the row would leave the phone
  /// still checking in on a target the user removed.
  Future<void> deleteHealthTarget(int id) async {
    final cancelledReminderIds = await healthTargets.delete(id);
    for (final reminderId in cancelledReminderIds) {
      try {
        await reminderScheduler.cancel(reminderId);
      } catch (e) {
        debugPrint('Could not cancel alarm $reminderId: $e');
      }
    }
  }

  /// Creates a reminder row and schedules its OS alarm, in that order —
  /// the app's own record of "this is scheduled" always exists before
  /// the alarm does, so a failure between the two leaves a recoverable
  /// "row exists but isn't scheduled" state rather than an alarm the
  /// app doesn't know about.
  ///
  /// Best-effort at the OS layer: if Android refuses (e.g. a permission
  /// revoked between confirm and schedule), the row is removed again so
  /// the reminders list only ever shows things that will actually fire.
  /// Returns whether scheduling succeeded.
  ///
  /// [TaskTool.setAlarm] still writes a row and is still cancellable —
  /// see `ReminderScheduler.schedule` for how it differs from a plain
  /// reminder at the OS level (`AlarmManager.setAlarmClock`, not the
  /// hand-off to the system Clock app that was tried and reverted).
  Future<bool> scheduleReminder({
    required String title,
    required DateTime scheduledFor,
    required TaskTool tool,
    int? todoId,
    int? healthTargetId,
  }) async {
    if (!await reminderScheduler.hasPermissions()) {
      await reminderScheduler.requestPermissions();
    }

    final id = await reminders.create(
      title: title,
      scheduledFor: scheduledFor,
      tool: tool,
      todoId: todoId,
      healthTargetId: healthTargetId,
    );

    final scheduled = await reminderScheduler.schedule(
      id: id,
      title: title,
      scheduledFor: scheduledFor,
      tool: tool,
    );

    if (!scheduled) {
      await reminders.delete(id);
      return false;
    }
    return true;
  }

  /// Re-schedules every pending reminder's OS alarm with the current
  /// process.
  ///
  /// AlarmManager entries do not survive the app being force-stopped —
  /// by the user, or by an OEM's aggressive background-app management
  /// (OriginOS notably) — or a device reboot, and the database row has
  /// no way to know that happened: it still reads as "scheduled" while
  /// the real alarm is silently gone. Calling this once at startup is
  /// what turns that into "comes back the next time the app is
  /// opened" instead of a reminder that quietly never fires again.
  /// Re-scheduling an id that's still armed just replaces it in place
  /// (the OS keys on the same id), so this is safe to run
  /// unconditionally rather than only after detecting an actual gap.
  ///
  /// Does not cover a reboot the user never reopens the app after —
  /// that would need a boot-time receiver reading the database
  /// directly in Kotlin, which is deliberately out of scope here.
  Future<void> rearmPendingReminders() async {
    try {
      final pending = await reminders.getPending();
      for (final reminder in pending) {
        try {
          await reminderScheduler.schedule(
            id: reminder.id,
            title: reminder.title,
            scheduledFor: reminder.scheduledFor,
            tool: reminder.tool,
          );
        } catch (e) {
          debugPrint('Could not re-arm reminder ${reminder.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Could not read pending reminders to re-arm: $e');
    }
  }

  /// Marks a todo completed or not, and — when completing — cancels
  /// any reminder still pending for it.
  ///
  /// A task you just finished shouldn't go on to notify you about
  /// itself; the reminder existed to prompt the work that's now done.
  /// Un-completing does not restore a cancelled reminder: the moment it
  /// was meant to catch has already passed by the time a finished task
  /// is reopened, so there is nothing to reinstate.
  Future<void> completeTodo(int id, {required bool completed, DateTime? at}) async {
    await todos.setCompleted(id, completed: completed, at: at);
    if (!completed) return;

    final owned = await reminders.forTodo(id);
    for (final reminder in owned.where((r) => r.isPending)) {
      try {
        await reminders.cancel(reminder.id);
        await reminderScheduler.cancel(reminder.id);
      } catch (e) {
        debugPrint('Could not cancel reminder ${reminder.id} on completion: $e');
      }
    }
  }

  Future<void> dispose() {
    screenCapture.dispose();
    return database.close();
  }
}

/// Makes [AppServices] available to the widget tree.
class ServiceScope extends InheritedWidget {
  const ServiceScope({super.key, required this.services, required super.child});

  final AppServices services;

  /// Deliberately does **not** register an inherited-widget dependency:
  /// [AppServices] is built once in `main()` and never replaced, so
  /// there is nothing to rebuild for. Registering one would also make
  /// this illegal to call from `initState`, which is exactly where
  /// screens need it to kick off their first load.
  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ServiceScope>();
    assert(scope != null, 'No ServiceScope found in the widget tree');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServiceScope oldWidget) => false;
}
