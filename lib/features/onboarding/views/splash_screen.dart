import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for the animation to play or data to load
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The user requested the background to be the mobile default theme background
    // and the loading line to be grey.
    return Scaffold(
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
  }
}
