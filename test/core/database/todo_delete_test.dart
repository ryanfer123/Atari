import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/database/reminder_repository.dart';
import 'package:atari/core/database/todo_repository.dart';
import 'package:atari/core/models/task_tool.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deleting a task used to remove the task rows and leave its reminders
/// behind — pointing at a row that no longer existed, with the OS alarm
/// still scheduled. A notification for a task you deliberately deleted
/// is the worst kind, so this is covered directly.
void main() {
  late AppDatabase db;
  late TodoRepository todos;
  late ReminderRepository reminders;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    todos = TodoRepository(db);
    reminders = ReminderRepository(db);
  });
  tearDown(() => db.close());

  Future<int> reminderFor(int todoId, String title) => reminders.create(
    title: title,
    scheduledFor: DateTime.now().add(const Duration(hours: 1)),
    tool: TaskTool.setAlarm,
    todoId: todoId,
  );

  test('deleting a task removes its reminders and reports their ids', () async {
    final todoId = await todos.create(title: 'Submit the report');
    final reminderId = await reminderFor(todoId, 'Submit the report');

    final cancelled = await todos.delete(todoId);

    // The ids come back so the caller can cancel the OS alarms, which
    // live outside the database.
    expect(cancelled, [reminderId]);
    expect(await reminders.forTodo(todoId), isEmpty);
    expect(await todos.findById(todoId), isNull);
  });

  test('deleting a parent also clears reminders on its subtasks', () async {
    final parentId = await todos.create(title: 'Write the dissertation');
    final childId = await todos.create(
      title: 'Draft chapter one',
      parentId: parentId,
    );
    final parentReminder = await reminderFor(parentId, 'Dissertation');
    final childReminder = await reminderFor(childId, 'Chapter one');

    final cancelled = await todos.delete(parentId);

    expect(cancelled, containsAll([parentReminder, childReminder]));
    expect(await todos.findById(childId), isNull);
    expect(await reminders.forTodo(childId), isEmpty);
  });

  test('reminders belonging to other tasks are left alone', () async {
    final doomed = await todos.create(title: 'Delete me');
    final survivor = await todos.create(title: 'Keep me');
    await reminderFor(doomed, 'Delete me');
    final survivorReminder = await reminderFor(survivor, 'Keep me');

    final cancelled = await todos.delete(doomed);

    expect(cancelled, isNot(contains(survivorReminder)));
    expect(await reminders.forTodo(survivor), hasLength(1));
    expect(await todos.findById(survivor), isNotNull);
  });

  test('deleting a task with no reminders reports nothing to cancel', () async {
    final todoId = await todos.create(title: 'Nothing scheduled');
    expect(await todos.delete(todoId), isEmpty);
  });
}
