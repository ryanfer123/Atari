import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('InsightsScreen')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('InsightsScreen Skeleton View'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
