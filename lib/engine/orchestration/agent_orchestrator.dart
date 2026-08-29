import 'dart:async';

import '../../core/models/models.dart';
import '../../core/services/i_sensing_service.dart';
import '../../core/services/i_slm_explainer_service.dart';
import '../../core/services/i_tts_service.dart';
import '../baseline/baseline_store.dart';
import '../detection/overload_detector.dart';
import '../feedback/contextual_bandit.dart';
import '../gamification/gamification_engine.dart';
import '../retrieval/goal_context_retriever.dart';

/// Central agent controller tying together:
///
/// ```
/// sensing snapshot → baseline z-scores → detection state machine
///   → masked retrieval → SLM explanation → focus intervention
///   → feedback loop → gamification reward
/// ```
///
/// See Plans/IMPLEMENTATION.md §1 architecture diagram.
class AgentOrchestrator {
  AgentOrchestrator({
    required this.sensingService,
    required this.slmService,
    required this.ttsService,
    required this.baselineStore,
    required this.detector,
    required this.bandit,
    required this.goalRetriever,
    required this.gamification,
  });

  final ISensingService sensingService;
  final ISlmExplainerService slmService;
  final ITtsService ttsService;
  final BaselineStore baselineStore;
  final OverloadDetector detector;
  final ContextualBandit bandit;
  final GoalContextRetriever goalRetriever;
  final GamificationEngine gamification;

  final _stateController = StreamController<AgentState>.broadcast();
  final _explanationController = StreamController<Explanation>.broadcast();
  final _eventController = StreamController<GamificationEvent>.broadcast();

  /// Stream of agent state transitions.
  Stream<AgentState> get stateStream => _stateController.stream;

  /// Stream of generated explanations.
  Stream<Explanation> get explanationStream => _explanationController.stream;

  /// Stream of gamification events (XP awards).
  Stream<GamificationEvent> get gamificationStream => _eventController.stream;

  AgentState get currentState => detector.state;
  InterventionType? _currentIntervention;
  double? _preInterventionSeverity;
  StreamSubscription<SignalSnapshot>? _sensingSubscription;
  bool _isRunning = false;

  /// Start the continuous sensing and evaluation loop.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _sensingSubscription = sensingService.snapshotStream.listen(_onSnapshot);
  }

  /// Stop the sensing loop.
  void stop() {
    _isRunning = false;
    _sensingSubscription?.cancel();
    _sensingSubscription = null;
  }

  /// Process a single sensing snapshot through the full pipeline.
  Future<void> _onSnapshot(SignalSnapshot snapshot) async {
    // 1. Record observation into personal baseline.
    await detector.recordObservation(snapshot);

    // 2. Evaluate against baseline for anomaly detection.
    final newState = await detector.evaluate(snapshot);
    _stateController.add(newState);

    // 3. If overload detected, generate explanation and prepare intervention.
    if (newState == AgentState.overloadDetected && detector.currentEvent != null) {
      await _handleOverloadDetected(detector.currentEvent!);
    }
  }

  /// Triggered when the detector transitions to overloadDetected.
  Future<void> _handleOverloadDetected(OverloadEvent event) async {
    // a. Select context sources (masked agentic selection).
    final bullets = await goalRetriever.retrieveWithSelection(
      slmService,
      triggerSignal: event.topSignal,
      topSignal: event.topSignal,
      maxCalls: 3,
    );

    // b. Generate grounded explanation.
    final explanation = await slmService.generateExplanation(
      event,
      contextBullets: bullets,
    );
    _explanationController.add(explanation);

    // c. Select intervention type via bandit.
    _currentIntervention = bandit.select(event.topSignal);
    _preInterventionSeverity = event.severity;

    // d. Speak the explanation via offline TTS.
    await ttsService.speak(explanation.sentence);
  }

  /// Called by the UI when the user accepts the intervention.
  void acceptIntervention() {
    detector.beginIntervention();
    _stateController.add(detector.state);
  }

  /// Called by the UI when the intervention session is complete.
  Future<void> completeIntervention({double? postSeverity}) async {
    detector.endIntervention();
    _stateController.add(detector.state);

    // Record bandit feedback.
    if (_currentIntervention != null && _preInterventionSeverity != null) {
      final outcome = InterventionOutcome(
        type: _currentIntervention!,
        preScore: _preInterventionSeverity!,
        postScore: postSeverity ?? 0.0,
        timestamp: DateTime.now(),
      );
      bandit.recordOutcome(
        outcome,
        detector.currentEvent?.topSignal ?? 'app_switches',
      );

      // Award gamification XP if intervention had positive effect.
      if (outcome.effectSize > 0) {
        final event = gamification.award(GamificationTrigger.interventionWorked);
        _eventController.add(event);
      }
    }

    _currentIntervention = null;
    _preInterventionSeverity = null;
  }

  /// Manually trigger a single evaluation cycle (for testing / debug).
  Future<AgentState> evaluateNow() async {
    final snapshot = await sensingService.getCurrentSnapshot();
    await _onSnapshot(snapshot);
    if (detector.state != AgentState.overloadDetected) {
      detector.forceOverload(snapshot);
      _stateController.add(detector.state);
      await _handleOverloadDetected(detector.currentEvent!);
    }
    return detector.state;
  }

  /// Award XP for external actions (todo completed, capture organized, etc.).
  GamificationEvent awardXp(GamificationTrigger trigger) {
    final event = gamification.award(trigger);
    _eventController.add(event);
    return event;
  }

  void dispose() {
    stop();
    _stateController.close();
    _explanationController.close();
    _eventController.close();
  }
}
