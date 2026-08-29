import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/goals_viewmodel.dart';
import '../../../core/widgets/atari_card.dart';
import '../../../core/widgets/atari_button.dart';
import '../../../core/widgets/atari_text_field.dart';
import '../../../core/theme/atari_theme.dart';
import '../../../core/models/view_state.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final indicatorColor = AtariTheme.primaryYellow;
    final labelColor = isDark ? AtariTheme.primaryYellow : Colors.black;
    final unselectedColor = isDark ? AtariTheme.primaryYellow.withOpacity(0.5) : Colors.black54;
    final dividerColor = isDark ? AtariTheme.primaryYellow.withOpacity(0.2) : Colors.black12;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Goals'),
          bottom: TabBar(
            indicatorColor: indicatorColor,
            labelColor: labelColor,
            unselectedLabelColor: unselectedColor,
            dividerColor: dividerColor,
            tabs: const [
              Tab(text: 'Tasks'),
              Tab(text: 'Notes'),
              Tab(text: 'Health'),
            ],
          ),
        ),
        body: Consumer<GoalsViewModel>(
          builder: (context, vm, child) {
            if (vm.state == ViewState.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 160),
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _TasksTabView(vm: vm)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _NotesTabView(vm: vm)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _HealthTabView(vm: vm)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TasksTabView extends StatefulWidget {
  final GoalsViewModel vm;
  const _TasksTabView({required this.vm});

  @override
  State<_TasksTabView> createState() => _TasksTabViewState();
}

class _TasksTabViewState extends State<_TasksTabView> {
  bool _isAdding = false;
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text('New task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AtariTextField(
                  controller: _taskController,
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
                  onPressed: () {
                    if (_taskController.text.trim().isNotEmpty) {
                      widget.vm.addTodo(title: _taskController.text.trim());
                      _taskController.clear();
                    }
                    setState(() => _isAdding = false);
                  },
                  child: const Center(child: Text('Add task')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.vm.todos.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 24),
              itemCount: widget.vm.todos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final todo = widget.vm.todos[index];
                return AtariCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Checkbox(
                        value: todo.isCompleted,
                        activeColor: AtariTheme.primaryYellow,
                        onChanged: (_) => widget.vm.toggleTodo(todo.id),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Add a task')),
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
  final GoalsViewModel vm;
  const _NotesTabView({required this.vm});

  @override
  State<_NotesTabView> createState() => _NotesTabViewState();
}

class _NotesTabViewState extends State<_NotesTabView> {
  bool _isAdding = false;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text('New note', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AtariTextField(
                  controller: _noteController,
                  labelText: '',
                  hintText: 'Anything worth remembering',
                ),
                const SizedBox(height: 24),
                AtariButton(
                  onPressed: () {
                    if (_noteController.text.trim().isNotEmpty) {
                      widget.vm.addNote(_noteController.text.trim());
                      _noteController.clear();
                    }
                    setState(() => _isAdding = false);
                  },
                  child: const Center(child: Text('Save')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.vm.notes.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 24),
              itemCount: widget.vm.notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = widget.vm.notes[index];
                return AtariCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(note.text, style: const TextStyle(fontWeight: FontWeight.w500)),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Write a note')),
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
  final GoalsViewModel vm;
  const _HealthTabView({required this.vm});

  @override
  State<_HealthTabView> createState() => _HealthTabViewState();
}

class _HealthTabViewState extends State<_HealthTabView> {
  bool _isAdding = false;
  final _metricController = TextEditingController();
  final _targetController = TextEditingController();

  @override
  void dispose() {
    _metricController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text('New health target', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AtariCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AtariTextField(
                  controller: _metricController,
                  labelText: 'Metric',
                  hintText: 'steps, water, sleep',
                ),
                const SizedBox(height: 16),
                AtariTextField(
                  controller: _targetController,
                  labelText: 'Target',
                  hintText: '8000',
                ),
                const SizedBox(height: 24),
                AtariButton(
                  onPressed: () {
                    final metric = _metricController.text.trim();
                    final target = double.tryParse(_targetController.text.trim()) ?? 0.0;
                    if (metric.isNotEmpty) {
                      widget.vm.addHealthTarget(metric: metric, threshold: target);
                      _metricController.clear();
                      _targetController.clear();
                    }
                    setState(() => _isAdding = false);
                  },
                  child: const Center(child: Text('Add target')),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.vm.healthTargets.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 24),
              itemCount: widget.vm.healthTargets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final target = widget.vm.healthTargets[index];
                return AtariCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(target.metric, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${target.threshold.toInt()} target', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          AtariButton(
            onPressed: () => setState(() => _isAdding = true),
            child: const Center(child: Text('+ Add a target')),
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
