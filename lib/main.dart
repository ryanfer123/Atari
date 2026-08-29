import 'package:flutter/material.dart';

import 'core/services/app_switch_signal_service.dart';
import 'core/services/notif_latency_signal_service.dart';
import 'core/services/signal_collection_status_service.dart';
import 'core/services/unlock_signal_service.dart';

/// Temporary debug harness for the `backend-native` workstream — exercises
/// native signal collectors directly against a real device so each one is
/// independently testable without the real app shell existing yet.
/// `frontend` will replace this entrypoint. See
/// Plans/IMPLEMENTATION.md §3 (Workstream: Backend — Native) exit
/// criterion: "each native capability... is independently testable via a
/// minimal debug harness/test screen."
void main() {
  runApp(const DebugHarnessApp());
}

class DebugHarnessApp extends StatelessWidget {
  const DebugHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATARI backend-native debug harness',
      home: SignalTrackerDebugScreen(),
    );
  }
}

class SignalTrackerDebugScreen extends StatefulWidget {
  SignalTrackerDebugScreen({
    super.key,
    UnlockSignalService? unlockService,
    AppSwitchSignalService? appSwitchService,
    NotifLatencySignalService? notifService,
    SignalCollectionStatusService? statusService,
  }) : unlockService = unlockService ?? UnlockSignalService(),
       appSwitchService = appSwitchService ?? AppSwitchSignalService(),
       notifService = notifService ?? NotifLatencySignalService(),
       statusService = statusService ?? SignalCollectionStatusService();

  final UnlockSignalService unlockService;
  final AppSwitchSignalService appSwitchService;
  final NotifLatencySignalService notifService;
  final SignalCollectionStatusService statusService;

  @override
  State<SignalTrackerDebugScreen> createState() =>
      _SignalTrackerDebugScreenState();
}

class _SignalTrackerDebugScreenState extends State<SignalTrackerDebugScreen> {
  List<DateTime> _unlockTimestamps = const [];
  int _unlocksToday = 0;
  bool? _serviceRunning;
  bool? _hasUsageAccess;
  int _appSwitchesToday = 0;
  bool? _hasNotificationAccess;
  List<Duration> _notifLatenciesToday = const [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final unlockTimestamps = await widget.unlockService.getUnlockTimestamps();
      final unlocksToday = await widget.unlockService.getUnlockCountSince(
        startOfToday,
      );
      final serviceRunning = await widget.statusService.isRunning();

      final hasUsageAccess = await widget.appSwitchService.hasUsageAccess();
      final appSwitchesToday = hasUsageAccess
          ? await widget.appSwitchService.getAppSwitchCountSince(startOfToday)
          : 0;

      final hasNotificationAccess = await widget.notifService
          .hasNotificationAccess();
      final notifLatenciesToday = hasNotificationAccess
          ? await widget.notifService.getLatenciesSince(startOfToday)
          : const <Duration>[];

      if (!mounted) return;
      setState(() {
        _unlockTimestamps = unlockTimestamps.reversed.toList();
        _unlocksToday = unlocksToday;
        _serviceRunning = serviceRunning;
        _hasUsageAccess = hasUsageAccess;
        _appSwitchesToday = appSwitchesToday;
        _hasNotificationAccess = hasNotificationAccess;
        _notifLatenciesToday = notifLatenciesToday;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boldStyle = const TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(title: const Text('Signal tracker debug')),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _refresh,
        child: const Icon(Icons.refresh),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _serviceRunning == null
                  ? 'Background service: checking...'
                  : 'Background service: ${_serviceRunning! ? 'running' : 'NOT running'}',
              style: boldStyle.copyWith(
                color: _serviceRunning == false ? Colors.red : null,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ],
            const Divider(height: 32),
            Text(
              'UnlockTracker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lock and unlock this phone, then refresh. No permission is required for this signal.',
            ),
            const SizedBox(height: 8),
            Text('Unlocks today: $_unlocksToday', style: boldStyle),
            Text('Total recorded: ${_unlockTimestamps.length}'),
            const SizedBox(height: 8),
            Text('Recent unlocks (newest first):', style: boldStyle),
            for (final t in _unlockTimestamps.take(20)) Text(t.toString()),
            const Divider(height: 32),
            Text(
              'AppSwitchTracker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Switch between a couple of apps, then refresh.'),
            const SizedBox(height: 8),
            Text(
              _hasUsageAccess == null
                  ? 'Usage access: checking...'
                  : 'Usage access: ${_hasUsageAccess! ? 'granted' : 'NOT granted'}',
              style: boldStyle.copyWith(
                color: _hasUsageAccess == false ? Colors.red : null,
              ),
            ),
            if (_hasUsageAccess == false) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    widget.appSwitchService.openUsageAccessSettings(),
                child: const Text('Grant usage access'),
              ),
            ],
            const SizedBox(height: 8),
            Text('App switches today: $_appSwitchesToday', style: boldStyle),
            const Divider(height: 32),
            Text(
              'NotifLatencyTracker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Let a notification arrive, then dismiss it or unlock your phone, then refresh.',
            ),
            const SizedBox(height: 8),
            Text(
              _hasNotificationAccess == null
                  ? 'Notification access: checking...'
                  : 'Notification access: ${_hasNotificationAccess! ? 'granted' : 'NOT granted'}',
              style: boldStyle.copyWith(
                color: _hasNotificationAccess == false ? Colors.red : null,
              ),
            ),
            if (_hasNotificationAccess == false) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    widget.notifService.openNotificationAccessSettings(),
                child: const Text('Grant notification access'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Notification latencies today: ${_notifLatenciesToday.length}',
              style: boldStyle,
            ),
            for (final d in _notifLatenciesToday.take(20))
              Text('${d.inSeconds}s'),
          ],
        ),
      ),
    );
  }
}
