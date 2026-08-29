import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'theme_provider.dart';

class ThemeToggleButton extends StatefulWidget {
  const ThemeToggleButton({super.key});

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Lottie Markers:
  // Day to Night: frames 20-80 (0.1 to 0.4 on a 0-200 timeline)
  // Night to Day: frames 120-200 (0.6 to 1.0 on a 0-200 timeline)

  @override
  void initState() {
    super.initState();
    // Use a slightly shorter duration so it feels snappy
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    
    // Sync initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ThemeProvider>().isDarkMode) {
        _controller.value = 0.4; // End of Day->Night
      } else {
        _controller.value = 0.1; // Start of Day->Night
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle(ThemeProvider themeProvider) {
    themeProvider.toggleTheme();
    
    if (themeProvider.isDarkMode) {
      // Transitioning to Dark Mode: Play from 0.1 to 0.4
      _controller.value = 0.1;
      _controller.animateTo(0.4, duration: const Duration(milliseconds: 800));
    } else {
      // Transitioning to Light Mode: Play from 0.6 to 1.0
      _controller.value = 0.6;
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 800)).then((_) {
        // Silently reset back to Day Idle for the next toggle
        if (mounted) _controller.value = 0.1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return GestureDetector(
      onTap: () => _handleToggle(themeProvider),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        child: Lottie.asset(
          'assets/lotties/toogle.json',
          controller: _controller,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
