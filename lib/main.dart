import 'dart:async';
import 'package:flutter/material.dart';
import 'core/models/models.dart';
import 'core/services/platform/platform_capture_service.dart';
import 'core/services/platform/platform_sensing_service.dart';
import 'core/services/platform/platform_slm_service.dart';
import 'core/services/platform/platform_tts_service.dart';

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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFFFF6B6B),
          surface: Color(0xFF1B1E2E),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1B1E2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E334D), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _sensingService = PlatformSensingService();
  final _slmService = PlatformSlmService();
  final _ttsService = PlatformTtsService();
  final _captureService = PlatformCaptureService();

  SignalSnapshot _snapshot = SignalSnapshot(
    unlockCount: 0,
    appSwitchCount: 0,
    avgNotifLatencyMs: 0.0,
    windowStart: DateTime.now().subtract(const Duration(minutes: 15)),
    windowEnd: DateTime.now(),
  );

  Map<String, bool> _permissions = {'usageAccess': false, 'notificationAccess': false};
  Explanation? _lastExplanation;
  SourceSelection? _lastSelection;
  CaptureResult? _lastCapture;
  AgentState _agentState = AgentState.normal;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final snapshot = await _sensingService.getCurrentSnapshot(windowMinutes: 15);
    final perms = await _sensingService.checkPermissions();
    if (mounted) {
      setState(() {
        _snapshot = snapshot;
        _permissions = perms;
      });
    }
  }

  Future<void> _triggerExplanation() async {
    setState(() => _isLoading = true);
    final event = OverloadEvent(
      timestamp: DateTime.now(),
      signalScores: {
        'app_switches': (_snapshot.appSwitchCount > 5) ? 3.1 : 1.2,
        'unlocks': (_snapshot.unlockCount > 3) ? 2.4 : 0.8,
        'notif_latency_ms': -0.3,
      },
      severity: 2.8,
      topSignal: 'app_switches',
      baselineContext: 'Saturday afternoon',
    );

    final bullets = [
      const ContextBullet(source: 'todo', text: 'CS 301 Lab Assignment (due 4:00 PM)'),
      const ContextBullet(source: 'health', text: 'Hydration target: 4 of 8 glasses'),
    ];

    final explanation = await _slmService.generateExplanation(event, contextBullets: bullets);
    if (mounted) {
      setState(() {
        _lastExplanation = explanation;
        _agentState = AgentState.overloadDetected;
        _isLoading = false;
      });
    }
  }

  Future<void> _runAgenticTooling() async {
    setState(() => _isLoading = true);
    final selection = await _slmService.selectSources(
      triggerSignal: 'app_switches',
      topSignal: 'app_switches',
      allowedSources: GoalContextSource.values,
      maxCalls: 3,
    );

    if (mounted) {
      setState(() {
        _lastSelection = selection;
        _isLoading = false;
      });
    }
  }

  Future<void> _speakExplanation() async {
    if (_lastExplanation != null) {
      await _ttsService.speak(_lastExplanation!.sentence);
    }
  }

  Future<void> _testCapture() async {
    setState(() => _isLoading = true);
    final result = await _captureService.capture(
      scribblePoints: [
        {'dx': 40.0, 'dy': 60.0},
        {'dx': 220.0, 'dy': 180.0},
      ],
      sourceImagePath: '/sdcard/sample_schedule.png',
      origin: 'camera',
    );

    if (mounted) {
      setState(() {
        _lastCapture = result;
        _isLoading = false;
      });
    }
  }

  Color _getStateColor(AgentState state) {
    switch (state) {
      case AgentState.normal:
        return const Color(0xFF4CAF50);
      case AgentState.overloadDetected:
        return const Color(0xFFFF9800);
      case AgentState.intervening:
        return const Color(0xFFF44336);
      case AgentState.cooldown:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor(_agentState);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: const Text('ATARI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'On-Device Agent',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white70),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: stateColor),
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: stateColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    _agentState.name.toUpperCase(),
                    style: TextStyle(color: stateColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Privacy proof banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF4ADE80), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% On-Device · Zero INTERNET Permission Declared',
                      style: TextStyle(color: Color(0xFFF1F5F9), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Signal Cards
            const Text(
              'LIVE BEHAVIOURAL SENSING (METADATA ONLY)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'App Switches',
                    value: '${_snapshot.appSwitchCount}',
                    subtitle: '15-min window',
                    icon: Icons.swap_horiz,
                    color: const Color(0xFF818CF8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Unlocks',
                    value: '${_snapshot.unlockCount}',
                    subtitle: '15-min window',
                    icon: Icons.lock_open,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Notif Latency',
                    value: _snapshot.avgNotifLatencyMs > 0 ? '${_snapshot.avgNotifLatencyMs.toInt()}ms' : 'N/A',
                    subtitle: 'Avg response',
                    icon: Icons.notifications_active_outlined,
                    color: const Color(0xFFF472B6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Permission Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.security, color: Color(0xFF6C63FF), size: 20),
                        SizedBox(width: 8),
                        Text('System Access Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPermChip('Usage Access', _permissions['usageAccess'] ?? false, () {
                          _sensingService.requestUsagePermission();
                        }),
                        _buildPermChip('Notification Listener', _permissions['notificationAccess'] ?? false, () {
                          _sensingService.requestNotificationPermission();
                        }),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Simulate Unlock', style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await _sensingService.recordSimulatedUnlock();
                            await _refreshData();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // On-Device SLM Explanation Section
            const Text(
              'ON-DEVICE SLM EXPLANATION & TTS (QWEN3-4B / GEMMA)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.bolt, size: 18),
                          label: const Text('Generate Explanation'),
                          onPressed: _isLoading ? null : _triggerExplanation,
                        ),
                        if (_lastExplanation != null)
                          IconButton.filledTonal(
                            icon: const Icon(Icons.volume_up, color: Color(0xFF6C63FF)),
                            tooltip: 'Speak Aloud (Offline TTS)',
                            onPressed: _speakExplanation,
                          ),
                      ],
                    ),
                    if (_lastExplanation != null) ...[
                      const Divider(height: 24, color: Color(0xFF2E334D)),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131622),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2E334D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SLM GENERATED EXPLANATION (1-SENTENCE BOUNDED):',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"${_lastExplanation!.sentence}"',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE2E8F0)),
                            ),
                            const SizedBox(height: 10),
                            const Text('Grounded Context Bullets:', style: TextStyle(fontSize: 11, color: Colors.white60)),
                            const SizedBox(height: 4),
                            ..._lastExplanation!.contextBullets.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('• [${b.source}] ${b.text}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Masked Agentic Source Selection Section
            const Text(
              'MASKED AGENTIC TOOL SELECTION (§4.8)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.psychology_outlined, size: 18),
                          label: const Text('Run Masked Tool Selector'),
                          onPressed: _isLoading ? null : _runAgenticTooling,
                        ),
                      ],
                    ),
                    if (_lastSelection != null) ...[
                      const Divider(height: 24, color: Color(0xFF2E334D)),
                      Text(
                        _lastSelection!.reasoning,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _lastSelection!.sources.map((s) {
                          return Chip(
                            backgroundColor: const Color(0xFF6C63FF).withAlpha(50),
                            side: const BorderSide(color: Color(0xFF6C63FF)),
                            label: Text(s.wireName, style: const TextStyle(fontSize: 12, color: Colors.white)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // On-Device Capture Pipeline Showcase
            const Text(
              'ON-DEVICE VISION CAPTURE & OCR PIPELINE (§4.6)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.crop_free, size: 18),
                      label: const Text('Test Scribble Crop + PP-OCR'),
                      onPressed: _isLoading ? null : _testCapture,
                    ),
                    if (_lastCapture != null) ...[
                      const Divider(height: 24, color: Color(0xFF2E334D)),
                      Text(
                        'Extracted Text: "${_lastCapture!.ocrText}"',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confidence: ${(_lastCapture!.ocrConfidence * 100).toStringAsFixed(1)}% · Rectified Image: ${_lastCapture!.rectifiedImagePath}',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermChip(String title, bool granted, VoidCallback onGrant) {
    return InkWell(
      onTap: onGrant,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: granted ? const Color(0xFF4CAF50).withAlpha(40) : const Color(0xFFF44336).withAlpha(40),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: granted ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(granted ? Icons.check_circle : Icons.warning_amber, size: 14, color: granted ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: granted ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
            ),
          ],
        ),
      ),
    );
  }
}
