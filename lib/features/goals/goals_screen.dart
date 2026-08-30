import 'package:flutter/material.dart';

import 'captures_tab.dart';
import 'health_targets_tab.dart';
import 'notes_tab.dart';
import 'todos_tab.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Goals'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Captures'),
              Tab(text: 'Notes'),
              Tab(text: 'Health'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TodosTab(), CapturesTab(), NotesTab(), HealthTargetsTab()],
        ),
      ),
    );
  }
}
