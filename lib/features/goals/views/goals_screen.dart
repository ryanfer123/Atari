import 'package:flutter/material.dart';
import '../../../core/widgets/atari_card.dart';
import '../../../core/widgets/atari_button.dart';
import '../../../core/widgets/atari_text_field.dart';
import '../../../core/theme/atari_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDark ? AtariTheme.primaryYellow : Colors.white;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Goals'),
          bottom: TabBar(
            indicatorColor: glowColor,
            labelColor: glowColor,
            unselectedLabelColor: glowColor.withOpacity(0.5),
            dividerColor: glowColor.withOpacity(0.2),
            tabs: const [
              Tab(text: 'Tasks'),
              Tab(text: 'Notes'),
              Tab(text: 'Health'),
            ],
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 160),
          child: TabBarView(
            children: [
              _TasksTabView(),
              _NotesTabView(),
              _HealthTabView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasksTabView extends StatefulWidget {
  const _TasksTabView();
  @override
  State<_TasksTabView> createState() => _TasksTabViewState();
}

class _TasksTabViewState extends State<_TasksTabView> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AtariTextField(
                  labelText: 'What needs doing?',
                  hintText: 'Enter task...',
                ),
                const SizedBox(height: 16),
                AtariCard(
                  isSecondary: true,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 12),
                      Text('No deadline', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AtariButton(
                  onPressed: () => setState(() => _isAdding = false),
                  child: const Center(child: Text('Add task')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.checklist, size: 64),
        const SizedBox(height: 16),
        const Text('No tasks yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Capture a photo of something to do, or add a task by hand.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Add a task')),
          ),
        ),
      ],
    );
  }
}

class _NotesTabView extends StatefulWidget {
  const _NotesTabView();
  @override
  State<_NotesTabView> createState() => _NotesTabViewState();
}

class _NotesTabViewState extends State<_NotesTabView> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AtariTextField(
                  labelText: '', // No label above this one in the screenshot
                  hintText: 'Anything worth remembering',
                ),
                const SizedBox(height: 24),
                AtariButton(
                  onPressed: () => setState(() => _isAdding = false),
                  child: const Center(child: Text('Save')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sticky_note_2_outlined, size: 64),
        const SizedBox(height: 16),
        const Text('No notes yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Notes give the app context about what matters to you right now.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Write a note')),
          ),
        ),
      ],
    );
  }
}

class _HealthTabView extends StatefulWidget {
  const _HealthTabView();
  @override
  State<_HealthTabView> createState() => _HealthTabViewState();
}

class _HealthTabViewState extends State<_HealthTabView> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('New health target', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AtariTextField(
                  labelText: 'Metric',
                  hintText: 'steps, water, sleep',
                ),
                const SizedBox(height: 16),
                const AtariTextField(
                  labelText: 'Target',
                  hintText: '',
                ),
                const SizedBox(height: 24),
                AtariButton(
                  onPressed: () => setState(() => _isAdding = false),
                  child: const Center(child: Text('Add target')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite_border, size: 64),
        const SizedBox(height: 16),
        const Text('No health targets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Simple goals like "steps -> 8000". Marking one met earns XP.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Add a target')),
          ),
        ),
      ],
    );
  }
}
