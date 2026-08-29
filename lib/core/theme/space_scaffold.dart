import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SpaceScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const SpaceScaffold({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensures Scaffold doesn't paint over the stack
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer (Marble White or Dark Slate)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          
          // Lottie Space Background
          Lottie.asset(
            'assets/lotties/background1.json',
            fit: BoxFit.cover,
            delegates: LottieDelegates(
              values: isDarkMode
                  ? []
                  : [
                      // srcIn will color ONLY the drawn lines grey, leaving transparent areas transparent
                      ValueDelegate.colorFilter(
                        ['**'],
                        value: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                      ),
                    ],
            ),
          ),
          
          // Foreground Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
