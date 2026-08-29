import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SpaceScaffold extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const SpaceScaffold({super.key, required this.child, this.appBar});

  @override
  State<SpaceScaffold> createState() => _SpaceScaffoldState();
}

class _SpaceScaffoldState extends State<SpaceScaffold> {
  // Cache the Lottie asset to ensure it never remounts or drops frames during a theme swap
  late final Widget _backgroundLottie;

  @override
  void initState() {
    super.initState();
    _backgroundLottie = Lottie.asset(
      'assets/lotties/background1.json',
      fit: BoxFit.cover,
      alignment: Alignment.bottomLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // MaterialApp's AnimatedTheme already smoothly interpolates scaffoldBackgroundColor over 1000ms.
          // Using a regular Container avoids recursive/double animations that cause severe lag.
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          
          // Lottie Space Background (Optimized Single Instance)
          RepaintBoundary(
            child: TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 1000), // Match MaterialApp's 1000ms duration
              curve: Curves.easeInOut,
              tween: ColorTween(
                begin: isDarkMode ? Colors.grey : Colors.transparent,
                end: isDarkMode ? Colors.transparent : Colors.grey,
              ),
              builder: (context, color, child) {
                return ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    color ?? Colors.transparent,
                    BlendMode.srcATop, // Transparent leaves original colors; Grey tints them.
                  ),
                  child: child,
                );
              },
              child: _backgroundLottie, // Use the cached instance
            ),
          ),
          
          // Foreground Content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}
