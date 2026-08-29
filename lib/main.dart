import 'dart:async';
import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/models/models.dart';
import 'core/services/platform/platform_capture_service.dart';
import 'core/services/platform/platform_sensing_service.dart';
import 'core/services/platform/platform_slm_service.dart';
import 'core/services/platform/platform_tts_service.dart';
import 'core/theme/atari_theme.dart';
import 'engine/baseline/baseline_store.dart';
import 'engine/detection/overload_detector.dart';
import 'engine/feedback/contextual_bandit.dart';
import 'engine/gamification/gamification_engine.dart';
import 'engine/orchestration/agent_orchestrator.dart';
import 'engine/retrieval/goal_context_retriever.dart';
import 'features/dashboard/dashboard_view.dart';
import 'features/focus/focus_shield_view.dart';
import 'features/gamification/gamification_view.dart';
import 'features/goals/capture_inbox_view.dart';
import 'features/settings/settings_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AtariApp());
}

class AtariApp extends StatelessWidget {
  const AtariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATARI',
      debugShowCheckedModeBanner: false,
      theme: AtariTheme.dark,
      home: const AtariShell(),
    );
  }
}

/// Root navigation shell that wires all services, the orchestrator,
/// and the four main tabs together.
class AtariShell extends StatefulWidget {
  const AtariShell({super.key});

  @override
  State<AtariShell> createState() => _AtariShellState();
}

class _AtariShellState extends State<AtariShell> {
  // ── Services ──────────────────────────────────────────────────
  late final PlatformSensingService _sensingService;
  late final PlatformSlmService _slmService;
  late final PlatformTtsService _ttsService;
  late final PlatformCaptureService _captureService;

  // ── Engine ────────────────────────────────────────────────────
  late final AppDatabase _db;
  late final BaselineStore _baselineStore;
  late final OverloadDetector _detector;
  late final ContextualBandit _bandit;
  late final GoalContextRetriever _goalRetriever;
  late final GamificationEngine _gamification;
  late final AgentOrchestrator _orchestrator;

  int _currentIndex = 0;
  bool _engineReady = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    // 1. Platform services.
    _sensingService = PlatformSensingService();
    _slmService = PlatformSlmService();
    _ttsService = PlatformTtsService();
    _captureService = PlatformCaptureService();

    // 2. Database & baseline.
    _db = AppDatabase();
    _baselineStore = BaselineStore(_db);

    // 3. Detection engine.
    _detector = OverloadDetector(_baselineStore);

    // 4. Bandit & retrieval.
    _bandit = ContextualBandit();
    _goalRetriever = GoalContextRetriever();
    _gamification = GamificationEngine();

    // 5. Seed starter quests.
    _gamification.addQuest(Quest(
      id: 'first_focus',
      title: 'First Focus',
      description: 'Complete your first focus session',
      targetCount: 1,
      xpReward: 100,
    ));
    _gamification.addQuest(Quest(
      id: 'organize_3',
      title: 'Organized Mind',
      description: 'Capture and organize 3 items',
      targetCount: 3,
      xpReward: 150,
    ));

    // 6. Orchestrator.
    _orchestrator = AgentOrchestrator(
      sensingService: _sensingService,
      slmService: _slmService,
      ttsService: _ttsService,
      baselineStore: _baselineStore,
      detector: _detector,
      bandit: _bandit,
      goalRetriever: _goalRetriever,
      gamification: _gamification,
    );

    // 7. Listen for overload events to push Focus Shield.
    _orchestrator.explanationStream.listen(_onExplanation);

    // 8. Start the sensing loop.
    _orchestrator.start();

    // 9. Auto-initialize and load on-device SLM runtime in background.
    _slmService.initRuntime();

    setState(() => _engineReady = true);
  }

  void _onExplanation(Explanation explanation) {
    if (!mounted) return;
    // Push Focus Shield overlay.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FocusShieldView(
        orchestrator: _orchestrator,
        explanation: explanation,
        interventionType: _bandit.select(
          _detector.currentEvent?.topSignal ?? 'app_switches',
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_engineReady) {
      return const Scaffold(
        backgroundColor: AtariTheme.deepSlate,
        body: Center(child: CircularProgressIndicator(color: AtariTheme.cyberViolet)),
      );
    }

    return Scaffold(
      backgroundColor: AtariTheme.deepSlate,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardView(orchestrator: _orchestrator),
            CaptureInboxView(captureService: _captureService),
            GamificationView(orchestrator: _orchestrator),
            SettingsView(
              sensingService: _sensingService,
              slmService: _slmService,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AtariTheme.surface,
          border: Border(top: BorderSide(color: AtariTheme.borderSubtle, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Capture',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
