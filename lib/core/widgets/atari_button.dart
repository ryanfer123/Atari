import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/atari_theme.dart';

class AtariButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isSecondary;
  final EdgeInsetsGeometry padding;

  const AtariButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isSecondary = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Explicit Fix: 
    // Dark Theme -> Black base
    // Light Theme -> White base
    final Color baseColor = isDark 
        ? Colors.black 
        : Colors.white;

    // Dark Theme -> Yellow Text
    // Light Theme -> Black Text
    final Color textColor = isDark 
        ? AtariTheme.primaryYellow 
        : Colors.black;

    // Both themes get Yellow glow/accents for iQOO branding
    final Color glowColor = AtariTheme.primaryYellow;
    
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Rounded squares
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Proper glassmorphism
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              
              // Translucent interior
              color: baseColor.withOpacity(isSecondary ? 0.2 : 0.5), 
              
              // Light radiating INTO the button (Inner Glow)
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent, // Transparent/base color in the center
                  // Reduced opacity so the interior stays mostly dark/light and text remains legible
                  glowColor.withOpacity(0.1), 
                ],
              ),
              
              // Sharp glass border matching the glow
              border: Border.all(
                color: glowColor.withOpacity(isSecondary ? 0.3 : 0.8),
                width: 1.5,
              ),
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              child: IconTheme(
                data: IconThemeData(color: textColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
