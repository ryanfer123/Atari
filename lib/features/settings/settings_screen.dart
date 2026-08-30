import 'package:flutter/material.dart';

import '../../core/services/app_switch_signal_service.dart';
import '../../core/services/model_registry.dart';
import '../../core/services/model_slot_service.dart';
import '../../core/services/notif_latency_signal_service.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/signal_collection_status_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_store.dart';
import '../../core/widgets/common.dart';
import 'model_slot_screen.dart';

/// Settings: model slots, permissions, and what the app collects.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _models = ModelSlotService();
  final _appSwitch = AppSwitchSignalService();
  final _notif = NotifLatencySignalService();
  final _collection = SignalCollectionStatusService();

  Map<ModelSlot, ModelSlotStatus> _modelStatuses = const {};
  bool _hasUsageAccess = false;
  bool _hasNotificationAccess = false;
  bool _hasReminderPermissions = false;
  bool _serviceRunning = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final services = ServiceScope.of(context);

    // Read independently so one unavailable channel can't blank the page.
    final statuses =
        await _safe(() => _models.allStatuses()) ??
        const <ModelSlot, ModelSlotStatus>{};
    final usage = await _safe(() => _appSwitch.hasUsageAccess()) ?? false;
    final notif = await _safe(() => _notif.hasNotificationAccess()) ?? false;
    final running = await _safe(() => _collection.isRunning()) ?? false;
    final reminders =
        await _safe(() => services.reminderScheduler.hasPermissions()) ?? false;

    if (!mounted) return;
    setState(() {
      _modelStatuses = statuses;
      _hasUsageAccess = usage;
      _hasNotificationAccess = notif;
      _serviceRunning = running;
      _hasReminderPermissions = reminders;
      _loading = false;
    });
  }

  /// Fills any slot whose expected file is already sitting in the models
  /// directory, so a pushed file doesn't also need its path typed in.
  Future<void> _scanForModels() async {
    setState(() => _loading = true);
    final found = await _safe(() => _models.autoDetectAll()) ?? 0;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          found == 0
              ? 'No new model files found in the app\'s models folder.'
              : 'Found $found model ${found == 1 ? 'file' : 'files'}.',
        ),
      ),
    );
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    final required = modelRegistry
        .where((s) => s.requirement == ModelRequirement.recommended)
        .toList();
    final stretch = modelRegistry
        .where((s) => s.requirement == ModelRequirement.stretch)
        .toList();
    final filled = required
        .where((s) => _modelStatuses[s.slot]?.isFilled ?? false)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionHeader(title: 'Appearance'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _ThemeModePicker(),
          ),

          const SectionHeader(title: 'Models'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: scheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$filled of ${required.length} models added',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Gap.xs,
                    Text(
                      filled == 0
                          ? 'The app works fully without them — every model-backed feature falls back to a '
                                'deterministic placeholder, and says so wherever it shows a result.'
                          : 'Slots without a model keep using their placeholder.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Gap.s,
                    Text(
                      'Only one model is ever loaded at a time, never several at once.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    Gap.m,
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _scanForModels,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan for model files'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Gap.s,
          for (final spec in required)
            _ModelSlotTile(
              spec: spec,
              status: _modelStatuses[spec.slot],
              onChanged: _refresh,
              service: _models,
            ),

          const SectionHeader(title: 'Optional upgrades'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Not needed for the core flow. The app crops to the box you draw, which is enough to read text.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Gap.s,
          for (final spec in stretch)
            _ModelSlotTile(
              spec: spec,
              status: _modelStatuses[spec.slot],
              onChanged: _refresh,
              service: _models,
            ),

          const SectionHeader(title: 'Reminders'),
          SwitchListTile(
            value: _hasReminderPermissions,
            onChanged: (_) async {
              await services.reminderScheduler.requestPermissions();
              await _refresh();
            },
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications and alarms'),
            subtitle: Text(
              _hasReminderPermissions
                  ? 'Granted — confirmed reminders will fire'
                  : 'Not granted — reminders you confirm may not fire',
            ),
          ),

          const SectionHeader(title: 'Background signals'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Optional. These power the background overload trigger, which is one of four decision '
              'points — the app works fully without them. Metadata only: counts and timings, never '
              'notification text or screen content.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Gap.s,
          ListTile(
            leading: Icon(
              _serviceRunning
                  ? Icons.check_circle_outline
                  : Icons.pause_circle_outline,
            ),
            title: const Text('Collection service'),
            subtitle: Text(_serviceRunning ? 'Running' : 'Not running'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Usage access'),
            subtitle: Text(
              _hasUsageAccess
                  ? 'Granted'
                  : 'Not granted — app switching not counted',
            ),
            trailing: _hasUsageAccess
                ? null
                : TextButton(
                    onPressed: () => _appSwitch.openUsageAccessSettings(),
                    child: const Text('Grant'),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification access'),
            subtitle: Text(
              _hasNotificationAccess
                  ? 'Granted'
                  : 'Not granted — response timing not measured',
            ),
            trailing: _hasNotificationAccess
                ? null
                : TextButton(
                    onPressed: () => _notif.openNotificationAccessSettings(),
                    child: const Text('Grant'),
                  ),
          ),

          const SectionHeader(title: 'Privacy'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Everything stays on this device. The app requests no internet permission at all, which '
              'you can verify in Android Settings → Apps → ATARI → Permissions.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Gap.xl,
        ],
      ),
    );
  }
}

/// Light/Dark picker — no System option, so the app's own choice is
/// always the one in effect rather than deferring to the device's.
/// Reads and writes `services.themeMode` directly (a `ValueNotifier` —
/// see its doc comment on `AppServices`) rather than local state, so
/// the choice takes effect at the `MaterialApp` root immediately, and
/// persists it to disk so it survives a restart.
class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: services.themeMode,
      builder: (context, mode, _) {
        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            final chosen = selection.first;
            services.themeMode.value = chosen;
            const ThemeModeStore().write(chosen);
          },
        );
      },
    );
  }
}

class _ModelSlotTile extends StatelessWidget {
  const _ModelSlotTile({
    required this.spec,
    required this.status,
    required this.onChanged,
    required this.service,
  });

  final ModelSpec spec;
  final ModelSlotStatus? status;
  final Future<void> Function() onChanged;
  final ModelSlotService service;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = status?.isFilled ?? false;

    return ListTile(
      leading: Icon(
        filled ? Icons.check_circle : Icons.add_circle_outline,
        color: filled ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(spec.title),
      subtitle: Text(
        '${spec.modelName} · ${spec.approxSize}\n${status?.label ?? 'Not added yet'}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ModelSlotScreen(spec: spec, service: service),
          ),
        );
        await onChanged();
      },
    );
  }
}
