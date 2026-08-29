import 'package:flutter/material.dart';
import '../theme/atari_theme.dart';

class AtariTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final String labelText;

  const AtariTextField({
    super.key,
    this.controller,
    required this.hintText,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Atari Glassmorphism Theme Rules
    final Color textColor = isDark ? AtariTheme.primaryYellow : Colors.black;
    final Color glowColor = isDark ? AtariTheme.primaryYellow : Colors.white;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: glowColor.withOpacity(0.5),
        width: 1.5,
      ),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: glowColor,
        width: 2.0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            color: glowColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
            enabledBorder: border,
            focusedBorder: focusedBorder,
            fillColor: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
