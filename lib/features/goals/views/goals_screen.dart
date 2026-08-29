import 'package:flutter/material.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('GoalsScreen')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('GoalsScreen Skeleton View'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
