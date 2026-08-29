import 'package:flutter/material.dart';

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
      home: UnlockTrackerDebugScreen(),
    );
  }
}

class UnlockTrackerDebugScreen extends StatefulWidget {
  UnlockTrackerDebugScreen({
    super.key,
    UnlockSignalService? service,
    SignalCollectionStatusService? statusService,
  }) : service = service ?? UnlockSignalService(),
       statusService = statusService ?? SignalCollectionStatusService();

  final UnlockSignalService service;
  final SignalCollectionStatusService statusService;

  @override
  State<UnlockTrackerDebugScreen> createState() =>
      _UnlockTrackerDebugScreenState();
}

class _UnlockTrackerDebugScreenState extends State<UnlockTrackerDebugScreen> {
  List<DateTime> _timestamps = const [];
  int _todayCount = 0;
  bool? _serviceRunning;
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
      final timestamps = await widget.service.getUnlockTimestamps();
      final todayCount = await widget.service.getUnlockCountSince(startOfToday);
      final serviceRunning = await widget.statusService.isRunning();
      if (!mounted) return;
      setState(() {
        _timestamps = timestamps.reversed.toList();
        _todayCount = todayCount;
        _serviceRunning = serviceRunning;
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
    return Scaffold(
      appBar: AppBar(title: const Text('UnlockTracker debug')),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading ? null : _refresh,
        child: const Icon(Icons.refresh),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Lock and unlock this phone, then pull to refresh or tap the '
              'refresh button. No permission is required for this signal.',
            ),
            const SizedBox(height: 16),
            Text(
              _serviceRunning == null
                  ? 'Background service: checking...'
                  : 'Background service: ${_serviceRunning! ? 'running' : 'NOT running'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _serviceRunning == false ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlocks today: $_todayCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Total recorded: ${_timestamps.length}'),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 16),
            const Text(
              'Recent unlocks (newest first):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (final t in _timestamps.take(50)) Text(t.toString()),
          ],
        ),
      ),
    );
  }
}
