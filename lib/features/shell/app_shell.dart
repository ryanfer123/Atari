import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/widgets/atari_bottom_nav_bar.dart';
import '../capture/circle_capture_screen.dart';
import '../capture/quick_add_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../gamification/progress_screen.dart';
import '../goals/goals_screen.dart';
import '../insights/insights_screen.dart';

/// Root navigation. Four destinations, plus Add and Capture as their
/// own buttons on the right — capture is the product's primary action
/// (Plans/PIVOT_PLAN.md §2.6 priority 1), so it stays a direct button
/// rather than buried in a tab.
///
/// The Atari space background and glass nav bar are UI ported from the
/// `frontend` branch (design only — that branch's MVVM scaffold and
/// fake services are not part of this app). Everything underneath is
/// unchanged: the same four real screens, the same `Navigator.push`
/// calls into capture.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _index = 0;

  static const _destinations = <(IconData, String)>[
    (Icons.today_rounded, 'Today'),
    (Icons.checklist_rtl_rounded, 'Goals'),
    (Icons.emoji_events_rounded, 'Progress'),
    (Icons.insights_rounded, 'Insights'),
  ];

  // Stretched to several times the animation's natural duration — the
  // lines are meant to sit quietly behind the content, not draw the
  // eye. `Lottie.asset` has no direct speed knob; this is the
  // documented way to slow one down, by driving it with a controller
  // whose duration is a multiple of the composition's own.
  static const _backgroundSlowdown = 4;

  late final _backgroundController = AnimationController(vsync: this);

  // Built once so the animation never remounts or drops frames on a
  // rebuild triggered by tab switches.
  late final Widget _background = Lottie.asset(
    'assets/lotties/background1.json',
    fit: BoxFit.cover,
    alignment: Alignment.bottomLeft,
    controller: _backgroundController,
    onLoaded: (composition) {
      _backgroundController
        ..duration = composition.duration * _backgroundSlowdown
        ..repeat();
    },
  );

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Theme.of(context).scaffoldBackgroundColor),
          // Full-color on the dark background, where the lines are the
          // point of the texture; greyed out and faded well down on the
          // light one, where the same saturated colour would compete
          // with the content instead of sitting behind it.
          RepaintBoundary(
            child: Opacity(
              opacity: isDark ? 1 : 0.25,
              child: isDark
                  ? _background
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcATop),
                      child: _background,
                    ),
            ),
          ),

          IndexedStack(
            index: _index,
            children: const [
              DashboardScreen(),
              GoalsScreen(),
              ProgressScreen(),
              InsightsScreen(),
            ],
          ),

          // Two ways in, because they suit different moments: circle
          // something you are looking at, or type a handful of things
          // you are holding in your head. Small FABs, stacked well
          // clear of the floating nav bar below.
          Positioned(
            right: 16,
            bottom: 196,
            child: FloatingActionButton.small(
              heroTag: 'quickAdd',
              tooltip: 'Type several things at once',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickAddScreen(),
                  fullscreenDialog: true,
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 140,
            child: FloatingActionButton.small(
              heroTag: 'capture',
              tooltip: 'Capture',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CircleCaptureScreen(),
                  fullscreenDialog: true,
                ),
              ),
              child: const Icon(Icons.center_focus_strong),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: AtariBottomNavBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                destinations: _destinations,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
