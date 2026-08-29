import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/atari_theme.dart';

class AtariBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AtariBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use the exact AtariButton styling rules as requested:
    // Dark Theme: Black interior, Yellow text/glow
    // Light Theme: Yellow interior, Black text, White glow
    final Color baseColor = isDark ? Colors.black : AtariTheme.primaryYellow;
    final Color itemColor = isDark ? AtariTheme.primaryYellow : Colors.black;
    final Color glowColor = isDark ? AtariTheme.primaryYellow : Colors.white;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24), // Highly rounded like a pill
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Glassmorphism
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            
            // Translucent interior
            color: isDark ? baseColor.withOpacity(0.3) : baseColor.withOpacity(0.6), 
            
            // Light radiating INTO the button (Inner Glow)
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: 3.0,
              colors: [
                Colors.transparent, 
                glowColor.withOpacity(0.3), // Glow from edges
              ],
            ),
            
            // Sharp glass border matching the glow
            border: Border.all(
              color: glowColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.calendar_today_rounded, 'Today', itemColor),
              _buildNavItem(1, Icons.checklist_rtl_rounded, 'Goals', itemColor),
              _buildNavItem(2, Icons.emoji_events_rounded, 'Progress', itemColor),
              _buildNavItem(3, Icons.insights_rounded, 'Insights', itemColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color itemColor) {
    final isSelected = currentIndex == index;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // Active state highlight (a subtle pill behind the selected icon)
            color: isSelected ? itemColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? itemColor : itemColor.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? itemColor : itemColor.withOpacity(0.5),
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
