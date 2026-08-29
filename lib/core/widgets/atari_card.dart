import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/atari_theme.dart';

class AtariCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isSecondary;

  const AtariCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Atari Glassmorphism Theme Rules
    final Color baseColor = isDark ? Colors.black : AtariTheme.primaryYellow;
    final Color textColor = isDark ? AtariTheme.primaryYellow : Colors.black;
    final Color glowColor = isDark ? AtariTheme.primaryYellow : Colors.white;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            
            // Translucent interior
            color: baseColor.withOpacity(isSecondary ? 0.2 : 0.4), 
            
            // Inner glow gradient
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.transparent, 
                glowColor.withOpacity(0.15), 
              ],
            ),
            
            // Border
            border: Border.all(
              color: glowColor.withOpacity(isSecondary ? 0.2 : 0.4),
              width: 1.5,
            ),
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: textColor,
            ),
            child: IconTheme(
              data: IconThemeData(color: textColor),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
