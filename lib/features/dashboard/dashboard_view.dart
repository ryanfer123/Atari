import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/atari_theme.dart';
import '../../engine/orchestration/agent_orchestrator.dart';

/// Live behavioral dashboard showing real-time sensing data,
/// agent state, z-score gauges, and quick action triggers.
///
/// See Plans/frontend_prd.md §4.
class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.orchestrator});

  final AgentOrchestrator orchestrator;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  SignalSnapshot? _latestSnapshot;
  AgentState _agentState = AgentState.normal;

  @override
  void initState() {
    super.initState();
    widget.orchestrator.stateStream.listen((state) {
      if (mounted) setState(() => _agentState = state);
    });
    widget.orchestrator.sensingService.snapshotStream.listen((snap) {
      if (mounted) setState(() => _latestSnapshot = snap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPrivacyBanner(),
          const SizedBox(height: 24),
          Text('LIVE BEHAVIOURAL SENSING',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildSensingCards(),
          const SizedBox(height: 24),
          _buildAgentStateCard(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AtariTheme.cyberViolet,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('ATARI',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
        ),
        const SizedBox(width: 12),
        Text('On-Device Agent', style: AtariTheme.title),
        const Spacer(),
        _buildStateBadge(),
      ],
    );
  }

  Widget _buildStateBadge() {
    final (label, color) = switch (_agentState) {
      AgentState.normal => ('NORMAL', AtariTheme.neonEmerald),
      AgentState.overloadDetected => ('ALERT', AtariTheme.amberAlert),
      AgentState.intervening => ('FOCUS', AtariTheme.electricCyan),
      AgentState.cooldown => ('COOLDOWN', AtariTheme.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildPrivacyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AtariTheme.accentCardDecoration(AtariTheme.neonEmerald),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AtariTheme.neonEmerald, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '100% On-Device · Zero INTERNET Permission Declared',
              style: AtariTheme.body.copyWith(color: AtariTheme.neonEmerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensingCards() {
    final snap = _latestSnapshot;
    return Row(
      children: [
        Expanded(
          child: _SensingMetricCard(
            icon: Icons.swap_horiz_rounded,
            value: '${snap?.appSwitchCount ?? 0}',
            label: 'App Switches',
            sublabel: '15-min window',
            color: AtariTheme.cyberViolet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SensingMetricCard(
            icon: Icons.lock_open_rounded,
            value: '${snap?.unlockCount ?? 0}',
            label: 'Unlocks',
            sublabel: '15-min window',
            color: AtariTheme.electricCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SensingMetricCard(
            icon: Icons.notifications_active_outlined,
            value: snap != null
                ? '${(snap.avgNotifLatencyMs / 1000).toStringAsFixed(0)}s'
                : 'N/A',
            label: 'Notif Latency',
            sublabel: 'Avg response',
            color: AtariTheme.roseWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AtariTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Agent Status', style: AtariTheme.title.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          _buildStatusRow('Detection Engine', true),
          const SizedBox(height: 8),
          _buildStatusRow('Baseline Learning', true),
          const SizedBox(height: 8),
          _buildStatusRow('Contextual Bandit', true),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: widget.orchestrator.slmService.isReady(),
            builder: (_, snap) =>
                _buildStatusRow('SLM Runtime', snap.data ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool active) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? AtariTheme.neonEmerald : AtariTheme.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(label, style: AtariTheme.bodySmall),
        const Spacer(),
        Text(
          active ? 'Active' : 'Pending',
          style: AtariTheme.caption.copyWith(
              color: active ? AtariTheme.neonEmerald : AtariTheme.amberAlert),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QUICK ACTIONS',
            style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.orchestrator.evaluateNow(),
                icon: const Icon(Icons.bolt, size: 18),
                label: const Text('Evaluate Now'),
                style: AtariTheme.primaryButton(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    widget.orchestrator.sensingService.recordSimulatedUnlock(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Simulate'),
                style: AtariTheme.outlineButton(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SensingMetricCard extends StatelessWidget {
  const _SensingMetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AtariTheme.accentCardDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AtariTheme.statNumber.copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: AtariTheme.bodySmall.copyWith(fontSize: 12)),
          Text(sublabel, style: AtariTheme.caption),
        ],
      ),
    );
  }
}
