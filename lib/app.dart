import 'dart:async';

import 'package:flutter/material.dart';

import 'core/services/ondevice/llama_channel.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_store.dart';
import 'features/capture/capture_review_screen.dart';
import 'features/shell/app_shell.dart';

class AtariApp extends StatefulWidget {
  const AtariApp({super.key, required this.services});

  final AppServices services;

  @override
  State<AtariApp> createState() => _AtariAppState();
}

class _AtariAppState extends State<AtariApp> with WidgetsBindingObserver {
  /// Lets a capture arriving from the overlay service open the review
  /// screen without needing a BuildContext from whatever is on top.
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<String>? _captureSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listening here, at the root, rather than on the capture setup
    // screen: the whole point of the floating bubble is that the user
    // circles something from *another* app, so that screen is usually
    // not mounted when the crop comes back.
    _captureSubscription = widget.services.screenCapture.captures.listen(
      _openReview,
    );
    // Starts at ThemeMode.dark (set in AppServices); overwritten here
    // once the saved choice loads, rather than blocking first frame on
    // disk I/O.
    const ThemeModeStore().read().then((mode) {
      widget.services.themeMode.value = mode;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Qwen3-4B is ~2.5GB of mapped pages. Holding that while the user is
    // in another app is what gets a process killed, and the next call
    // reloads it anyway under the one-model-at-a-time rule
    // (Plans/PIVOT_PLAN.md §2.2), so there is nothing to save by
    // keeping it.
    if (state == AppLifecycleState.paused) {
      const LlamaChannel().unload().catchError(
        (Object e) => debugPrint('Could not unload models: $e'),
      );
    }
  }

  void _openReview(String croppedPath) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CaptureReviewScreen(
          imagePath: croppedPath,
          ocrService: widget.services.ocrService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ServiceScope(
      services: widget.services,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: widget.services.themeMode,
        builder: (context, mode, child) => MaterialApp(
          title: 'ATARI',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: child,
        ),
        child: const AppShell(),
      ),
    );
  }
}
