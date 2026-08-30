import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glassmorphic pill nav bar, ported from the `frontend` branch's
/// `AtariBottomNavBar`. Purely presentational — `currentIndex`/`onTap`
/// is the same shape `NavigationBar` used, so it drops into
/// `AppShell`'s existing `_index` state with no navigation-logic
/// changes.
class AtariBottomNavBar extends StatelessWidget {
  const AtariBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> destinations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? Colors.black : AppTheme.primaryYellow;
    final itemColor = isDark ? AppTheme.primaryYellow : Colors.black;
    final glowColor = isDark ? AppTheme.primaryYellow : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: baseColor.withValues(alpha: 0.6),
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 3.0,
              colors: [Colors.transparent, glowColor.withValues(alpha: 0.3)],
            ),
            border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _NavItem(
                  isSelected: currentIndex == i,
                  icon: destinations[i].$1,
                  label: destinations[i].$2,
                  color: itemColor,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : color.withValues(alpha: 0.5), size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : color.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
