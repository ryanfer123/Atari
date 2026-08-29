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

  void _handleToggle(ThemeProvider themeProvider) async {
    // 1. Show the loading interface overlay over the entire app
    showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false, // Ensure it covers the top and bottom of the screen
      barrierColor: Colors.transparent, // We use the Scaffold inside to handle background
      builder: (dialogContext) {
        return Scaffold(
          // This Scaffold will naturally inherit the AnimatedTheme from MaterialApp,
          // so its background will smoothly crossfade from Old Theme to New Theme!
          backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
          body: Center(
            child: Lottie.asset(
              'assets/lotties/loading.json',
              width: 200,
              height: 200,
              delegates: LottieDelegates(
                values: [
                  ValueDelegate.colorFilter(
                    ['**'],
                    value: const ColorFilter.mode(Colors.grey, BlendMode.srcATop),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Give the loading animation a tiny moment to mount and appear on screen
    await Future.delayed(const Duration(milliseconds: 200));

    // 2. Perform the global theme toggle
    themeProvider.toggleTheme();
    
    // 3. Animate the toggle button (it's hidden under the loading screen, but will be right when we return)
    if (themeProvider.isDarkMode) {
      _controller.value = 0.1;
      _controller.animateTo(0.4, duration: const Duration(milliseconds: 800));
    } else {
      _controller.value = 0.6;
      _controller.animateTo(1.0, duration: const Duration(milliseconds: 800)).then((_) {
        if (mounted) _controller.value = 0.1;
      });
    }

    // 4. Wait for the background theme transition to finish, plus a little buffer
    await Future.delayed(const Duration(milliseconds: 1200));

    // 5. Dismiss the loading overlay
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
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
          'assets/lotties/toggle.json',
          controller: _controller,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
