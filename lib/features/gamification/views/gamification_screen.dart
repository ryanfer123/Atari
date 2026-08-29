import 'package:flutter/material.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('GamificationScreen')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('GamificationScreen Skeleton View'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
