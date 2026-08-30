import 'package:flutter/material.dart';

import '../../core/services/screen_capture_service.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';

/// Sets up and triggers Circle-to-Search capture.
///
/// The circling itself happens in a system overlay owned by
/// `CaptureOverlayService`, not here — that's what lets it work over any
/// app. This screen handles the two permissions it needs, turns the
/// floating bubble on, and routes the resulting crop into the review
/// step (Plans/ARCHITECTURE.md §3).
class CircleCaptureScreen extends StatefulWidget {
  const CircleCaptureScreen({super.key});

  @override
  State<CircleCaptureScreen> createState() => _CircleCaptureScreenState();
}

class _CircleCaptureScreenState extends State<CircleCaptureScreen>
    with WidgetsBindingObserver {
  late final ScreenCaptureService _capture = ServiceScope.of(context)
      .screenCapture;

  bool _canDrawOverlays = false;
  bool _enabled = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Both permissions are granted on a settings screen we can't observe,
    // so re-check whenever we come back.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final overlays = await _safe(() => _capture.canDrawOverlays()) ?? false;
    final enabled = await _safe(() => _capture.isEnabled()) ?? false;
    if (!mounted) return;
    setState(() {
      _canDrawOverlays = overlays;
      _enabled = enabled;
    });
  }

  Future<T?> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      return null;
    }
  }

  Future<void> _enable() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final granted = await _safe(() => _capture.enable()) ?? false;
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!granted) {
        _error = 'Screen capture needs your permission to read the screen.';
      }
    });
    await _refresh();
  }

  Future<void> _disable() async {
    await _safe(() => _capture.disable());
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Circle to capture')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Gap.s,
                  const Text(
                    '1. A small floating button sits on top of your other apps.\n'
                    '2. Open anything — a timetable, a message, a web page.\n'
                    '3. Tap the button. The screen freezes.\n'
                    '4. Circle what you want. Only that part is read.',
                  ),
                  Gap.s,
                  Text(
                    'A single frame is captured each time and the projection is stopped '
                    'immediately after — nothing is recorded continuously.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          Gap.m,

          _StepTile(
            index: 1,
            title: 'Allow drawing over other apps',
            subtitle: _canDrawOverlays
                ? 'Granted'
                : 'Needed for the floating button and the circle overlay',
            done: _canDrawOverlays,
            action: _canDrawOverlays
                ? null
                : FilledButton(
                    onPressed: () async {
                      await _capture.requestOverlayPermission();
                    },
                    child: const Text('Grant'),
                  ),
          ),
          _StepTile(
            index: 2,
            title: 'Turn on circle to capture',
            subtitle: _enabled
                ? 'The floating button is active'
                : 'Android will ask to allow screen capture',
            done: _enabled,
            action: _enabled
                ? TextButton(onPressed: _disable, child: const Text('Turn off'))
                : FilledButton(
                    onPressed: _canDrawOverlays && !_busy ? _enable : null,
                    child: Text(_busy ? 'Starting…' : 'Turn on'),
                  ),
          ),

          if (_error != null) ...[
            Gap.m,
            Text(_error!, style: TextStyle(color: scheme.error)),
          ],

          if (_enabled) ...[
            Gap.l,
            FilledButton.icon(
              onPressed: () async {
                await _safe(() => _capture.captureNow());
              },
              icon: const Icon(Icons.crop_free),
              label: const Text('Capture what is behind this app'),
            ),
            Gap.s,
            Text(
              'Or just tap the floating button from wherever you are.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          Gap.xl,
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.done,
    this.action,
  });

  final int index;
  final String title;
  final String subtitle;
  final bool done;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: done
              ? scheme.primary
              : scheme.surfaceContainerHighest,
          foregroundColor: done ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: done ? const Icon(Icons.check, size: 18) : Text('$index'),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: action,
      ),
    );
  }
}
