import 'package:flutter/material.dart';

import '../../core/models/todo.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

/// Add-a-task sheet. Difficulty is scored automatically on save — see
/// `DifficultyScorer` and Plans/PIVOT_PLAN.md §2.4 for why that one is
/// safe to automate while reminders are not.
Future<void> showTodoEditor(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _TodoEditor(),
  );
}

class _TodoEditor extends StatefulWidget {
  const _TodoEditor();

  @override
  State<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<_TodoEditor> {
  final _controller = TextEditingController();
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (!mounted) return;
    setState(
      () => _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _save() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    final services = ServiceScope.of(context);
    final navigator = Navigator.of(context);

    final deadline = _deadline;
    final nearby = deadline == null
        ? const <Todo>[]
        : await services.todos.withDeadlineNear(deadline);
    final tier = await services.difficultyScorer.score(
      title: title,
      deadline: deadline,
      nearbyTasks: nearby,
    );
    await services.todos.create(
      title: title,
      deadline: _deadline,
      difficulty: tier,
    );

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New task', style: Theme.of(context).textTheme.titleLarge),
            Gap.m,
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What needs doing?'),
              onSubmitted: (_) => _save(),
            ),
            Gap.m,
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  _deadline == null ? 'No deadline' : formatWhen(_deadline!),
                ),
                trailing: _deadline == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _deadline = null),
                      ),
                onTap: _pickDeadline,
              ),
            ),
            Gap.l,
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
