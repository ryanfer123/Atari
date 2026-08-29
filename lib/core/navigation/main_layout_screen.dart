import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/space_scaffold.dart';
import '../theme/atari_theme.dart';
import '../widgets/atari_bottom_nav_bar.dart';
import '../widgets/draggable_cat_button.dart';

class MainLayoutScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return SpaceScaffold(
      child: Stack(
        children: [
          // 1. The nested router content
          // Each screen inside the router must use Scaffold(backgroundColor: Colors.transparent)
          // so the SpaceScaffold background shows through.
          Positioned.fill(child: navigationShell),

          // 2. Draggable Cat (replaces Capture FAB)
          DraggableCatButton(
            onTap: () => context.go('/capture'),
          ),

          // 3. Custom Glassmorphic Bottom Navigation Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: AtariBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
