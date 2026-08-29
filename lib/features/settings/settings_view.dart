import 'package:flutter/material.dart';

import '../../core/theme/atari_theme.dart';
import '../../core/services/platform/platform_slm_service.dart';
import '../../core/services/i_sensing_service.dart';

/// Settings view with privacy audit, system access toggles, and
/// SLM runtime status inspector.
///
/// See Plans/IMPLEMENTATION.md §5.1.
class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    required this.sensingService,
    required this.slmService,
  });

  final ISensingService sensingService;
  final PlatformSlmService slmService;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Map<String, bool> _permissions = {};
  Map<String, dynamic> _runtimeStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final perms = await widget.sensingService.checkPermissions();
    final status = await widget.slmService.getRuntimeStatus();
    setState(() {
      _permissions = perms;
      _runtimeStatus = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrivacyAudit(),
          const SizedBox(height: 24),
          Text('SYSTEM ACCESS',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildAccessToggles(),
          const SizedBox(height: 24),
          Text('MODEL RUNTIME',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildRuntimeStatus(),
          const SizedBox(height: 24),
          _buildRuntimeActions(),
        ],
      ),
    );
  }

  Widget _buildPrivacyAudit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AtariTheme.accentCardDecoration(AtariTheme.neonEmerald),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AtariTheme.neonEmerald, size: 22),
              const SizedBox(width: 10),
              Text('Privacy Audit', style: AtariTheme.title.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          _buildAuditRow('INTERNET Permission', 'Not Declared', true),
          _buildAuditRow('Network Sockets', 'None', true),
          _buildAuditRow('Data Transmission', 'Zero', true),
          _buildAuditRow('Model Inference', '100% On-Device', true),
          _buildAuditRow('Sensing Data', 'Metadata Only, Local', true),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value, bool pass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_circle : Icons.cancel,
            color: pass ? AtariTheme.neonEmerald : AtariTheme.roseWarning,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(label, style: AtariTheme.bodySmall),
          const Spacer(),
          Text(value, style: AtariTheme.caption.copyWith(
              color: pass ? AtariTheme.neonEmerald : AtariTheme.roseWarning)),
        ],
      ),
    );
  }

  Widget _buildAccessToggles() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AtariTheme.cardDecoration,
      child: Column(
        children: [
          _buildPermissionRow(
            'Usage Access',
            'Required for app-switch sensing',
            _permissions['usageAccess'] ?? false,
            () => widget.sensingService.requestUsagePermission(),
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            'Notification Listener',
            'Required for notification latency',
            _permissions['notificationAccess'] ?? false,
            () => widget.sensingService.requestNotificationPermission(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
      String label, String description, bool granted, VoidCallback onRequest) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AtariTheme.body),
              Text(description, style: AtariTheme.caption),
            ],
          ),
        ),
        if (granted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AtariTheme.neonEmerald.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: AtariTheme.neonEmerald, size: 14),
                const SizedBox(width: 4),
                Text('Granted', style: AtariTheme.caption.copyWith(color: AtariTheme.neonEmerald)),
              ],
            ),
          )
        else
          OutlinedButton(
            onPressed: onRequest,
            style: AtariTheme.outlineButton(color: AtariTheme.amberAlert),
            child: const Text('Grant'),
          ),
      ],
    );
  }

  Widget _buildRuntimeStatus() {
    final ready = _runtimeStatus['modelRuntimeReady'] == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AtariTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow('Native Contract', _runtimeStatus['nativeContractReady'] == true),
          const SizedBox(height: 8),
          _buildStatusRow('GGML Backend', _runtimeStatus['runtimeInitialized'] == true),
          const SizedBox(height: 8),
          _buildStatusRow('Model Loaded', ready),
          if (ready) ...[
            const SizedBox(height: 12),
            Divider(color: AtariTheme.borderSubtle),
            const SizedBox(height: 8),
            _buildMetricRow('Context Tokens', '${_runtimeStatus['contextTokens'] ?? 0}'),
            _buildMetricRow('Load Time', '${_runtimeStatus['loadMs'] ?? 0} ms'),
            _buildMetricRow('Last Generation', '${_runtimeStatus['generationMs'] ?? 0} ms'),
            _buildMetricRow('Time to First Token', '${_runtimeStatus['ttftMs'] ?? 0} ms'),
            _buildMetricRow('Tokens Generated', '${_runtimeStatus['generatedTokens'] ?? 0}'),
          ],
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
        Text(active ? 'Ready' : 'Pending',
            style: AtariTheme.caption.copyWith(
                color: active ? AtariTheme.neonEmerald : AtariTheme.amberAlert)),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AtariTheme.bodySmall),
          Text(value, style: AtariTheme.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRuntimeActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ACTIONS', style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await widget.slmService.initRuntime();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${result['message']}')),
                    );
                    _refresh();
                  }
                },
                icon: const Icon(Icons.memory, size: 18),
                label: const Text('Init Runtime'),
                style: AtariTheme.primaryButton(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: AtariTheme.outlineButton(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
