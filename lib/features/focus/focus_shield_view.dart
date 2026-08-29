import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/atari_theme.dart';
import '../../engine/feedback/contextual_bandit.dart';
import '../../engine/orchestration/agent_orchestrator.dart';

/// Full-screen focus intervention view.
///
/// Displays the grounded SLM explanation, a session timer, essential
/// apps whitelist, and offline TTS playback control.
///
/// See Plans/IMPLEMENTATION.md §4.4 and Plans/frontend_prd.md §4.3.
class FocusShieldView extends StatefulWidget {
  const FocusShieldView({
    super.key,
    required this.orchestrator,
    required this.explanation,
    required this.interventionType,
  });

  final AgentOrchestrator orchestrator;
  final Explanation explanation;
  final InterventionType interventionType;

  @override
  State<FocusShieldView> createState() => _FocusShieldViewState();
}

class _FocusShieldViewState extends State<FocusShieldView> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isSpeaking = false;
  static const _sessionDurationMinutes = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
    widget.orchestrator.acceptIntervention();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _sessionDurationMinutes * 60) {
        _completeSession();
      }
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    await widget.orchestrator.completeIntervention();
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _toggleTts() async {
    if (_isSpeaking) {
      await widget.orchestrator.ttsService.stop();
      setState(() => _isSpeaking = false);
    } else {
      await widget.orchestrator.ttsService.speak(widget.explanation.sentence);
      setState(() => _isSpeaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _elapsedSeconds / (_sessionDurationMinutes * 60);
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;

    return Scaffold(
      backgroundColor: AtariTheme.deepSlate,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(flex: 1),
              _buildTimerRing(progress, '$minutes:${seconds.toString().padLeft(2, '0')}'),
              const SizedBox(height: 32),
              _buildInterventionLabel(),
              const SizedBox(height: 24),
              _buildExplanationCard(),
              const SizedBox(height: 16),
              _buildTtsButton(),
              const Spacer(flex: 2),
              _buildCompleteButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AtariTheme.electricCyan.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AtariTheme.electricCyan.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield, color: AtariTheme.electricCyan, size: 16),
              const SizedBox(width: 6),
              Text('FOCUS SHIELD',
                  style: AtariTheme.caption.copyWith(
                      color: AtariTheme.electricCyan, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _completeSession,
          icon: Icon(Icons.close, color: AtariTheme.textMuted),
          tooltip: 'End session early',
        ),
      ],
    );
  }

  Widget _buildTimerRing(double progress, String timeText) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AtariTheme.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(AtariTheme.electricCyan),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeText, style: AtariTheme.statNumber),
              Text('of $_sessionDurationMinutes:00',
                  style: AtariTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionLabel() {
    final (label, icon) = switch (widget.interventionType) {
      InterventionType.focusShield => ('Focus Shield', Icons.shield_outlined),
      InterventionType.takeABreak => ('Take a Break', Icons.coffee_outlined),
      InterventionType.breatheDeep => ('Breathe Deep', Icons.air_outlined),
      InterventionType.hydrationWalk => ('Hydration Walk', Icons.directions_walk_outlined),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AtariTheme.cyberViolet, size: 22),
        const SizedBox(width: 8),
        Text(label, style: AtariTheme.title),
      ],
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AtariTheme.accentCardDecoration(AtariTheme.cyberViolet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AtariTheme.cyberViolet, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.explanation.usedModel ? 'AI Insight' : 'Observation',
                style: AtariTheme.bodySmall.copyWith(color: AtariTheme.cyberViolet),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.explanation.sentence, style: AtariTheme.body),
          if (widget.explanation.contextBullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...widget.explanation.contextBullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AtariTheme.bodySmall.copyWith(color: AtariTheme.neonEmerald)),
                  Expanded(
                    child: Text('${b.source}: ${b.text}',
                        style: AtariTheme.bodySmall),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTtsButton() {
    return OutlinedButton.icon(
      onPressed: _toggleTts,
      icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up, size: 18),
      label: Text(_isSpeaking ? 'Stop Audio' : 'Listen'),
      style: AtariTheme.outlineButton(color: AtariTheme.electricCyan),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _completeSession,
        icon: const Icon(Icons.check_circle_outline, size: 20),
        label: const Text('Complete Session'),
        style: AtariTheme.primaryButton(color: AtariTheme.neonEmerald),
      ),
    );
  }
}
