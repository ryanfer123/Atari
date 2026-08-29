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
    // Dark Theme -> Black Buttons
    // Light Theme -> Yellow Buttons
    final Color baseColor = isDark 
        ? Colors.black 
        : AtariTheme.primaryYellow;

    // Dark Theme (Black Button) -> Yellow Text
    // Light Theme (Yellow Button) -> Black Text
    final Color textColor = isDark 
        ? AtariTheme.primaryYellow 
        : Colors.black;

    // Dark Theme (Black Button) -> Yellow Glow
    // Light Theme (Yellow Button) -> White Glow
    final Color glowColor = isDark
        ? AtariTheme.primaryYellow
        : Colors.white;
    
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
                  glowColor.withOpacity(0.3), // Light radiating inward from edges
                ],
              ),
              
              // Sharp glass border matching the glow
              border: Border.all(
                color: glowColor.withOpacity(isSecondary ? 0.3 : 0.6),
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
