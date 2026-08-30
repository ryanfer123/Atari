import 'package:flutter/material.dart';

import '../../core/models/difficulty_tier.dart';
import '../../core/models/gamification_event.dart';
import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/widgets/common.dart';
import 'todo_detail_screen.dart';
import 'todo_editor.dart';

class TodosTab extends StatefulWidget {
  const TodosTab({super.key});

  @override
  State<TodosTab> createState() => _TodosTabState();
}

class _TodosTabState extends State<TodosTab> {
  // Created once — see the note in DashboardScreen on why building a
  // stream inside build() loops.
  late final Stream<List<Todo>> _todos = ServiceScope.of(context).todos
      .watchTopLevel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Todo>>(
        stream: _todos,
        builder: (context, snapshot) {
          final todos = snapshot.data ?? const <Todo>[];
          if (todos.isEmpty) {
            return EmptyState(
              icon: Icons.checklist_outlined,
              title: 'No tasks yet',
              message:
                  'Capture a photo of something to do, or add a task by hand.',
              action: FilledButton.icon(
                onPressed: () => showTodoEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Add a task'),
              ),
            );
          }

          final open = todos.where((t) => !t.isCompleted).toList();
          final done = todos.where((t) => t.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final todo in open) TodoTile(todo: todo),
              if (done.isNotEmpty) ...[
                SectionHeader(title: 'Completed (${done.length})'),
                for (final todo in done) TodoTile(todo: todo),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'add-todo',
        onPressed: () => showTodoEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoTile extends StatelessWidget {
  const TodoTile({super.key, required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Checkbox(
        value: todo.isCompleted,
        onChanged: (checked) => _setCompleted(context, checked ?? false),
      ),
      title: Text(
        todo.title,
        style: todo.isCompleted
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: todo.deadline == null
          ? null
          : Text(
              formatWhen(todo.deadline!),
              style: todo.isOverdue ? TextStyle(color: scheme.error) : null,
            ),
      trailing: todo.difficulty == null
          ? null
          : DifficultyChip(tier: todo.difficulty!, showXp: !todo.isCompleted),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TodoDetailScreen(todoId: todo.id)),
      ),
      onLongPress: () => _confirmDelete(context, services),
    );
  }

  Future<void> _setCompleted(BuildContext context, bool completed) async {
    final services = ServiceScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Not todos.setCompleted: that alone leaves a completed task's
    // reminder still armed to notify about work that's already done.
    await services.completeTodo(todo.id, completed: completed);

    // XP is awarded on completion only, and never removed on un-checking
    // — progress is non-losable by design (Plans/IMPLEMENTATION.md §4.7).
    if (completed) {
      final tier = todo.difficulty ?? fallbackDifficultyTier;
      await services.gamification.onTrigger(
        GamificationTrigger.todoCompleted,
        difficulty: tier,
      );
      messenger.showSnackBar(
        SnackBar(
          // Naming the number keeps the award auditable: it has to match
          // the difficulty chip on the same row.
          content: Text('Task completed — ${xpForDifficulty(tier)} XP'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppServices services,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        // Names the reminders explicitly: cancelling a confirmed alarm
        // is a consequence the user should see before agreeing to it,
        // not something they discover when it fails to go off.
        content: Text(
          '"${todo.title}", any of its subtasks, and any reminders or '
          'alarms set for them will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    // Not todos.delete: that removes the rows but leaves any alarm the
    // user confirmed still scheduled with the OS.
    if (confirmed ?? false) await services.deleteTodo(todo.id);
  }
}
