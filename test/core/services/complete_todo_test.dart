import 'package:atari/core/database/app_database.dart';
import 'package:atari/core/models/task_tool.dart';
import 'package:atari/core/services/service_locator.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A finished task must not go on to notify about itself — completing
/// it has to cancel whatever reminder or alarm was still pending for
/// it, both the database row and (best-effort) the real OS alarm.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const remindersChannel = MethodChannel('atari.dev/reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final cancelledIds = <int>[];

  setUp(() {
    cancelledIds.clear();
    messenger.setMockMethodCallHandler(remindersChannel, (call) async {
      switch (call.method) {
        case 'hasPermissions':
        case 'schedule':
          return true;
        case 'cancel':
          cancelledIds.add((call.arguments as Map)['id'] as int);
          return null;
        default:
          return null;
      }
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(remindersChannel, null));

  late AppServices services;

  setUp(() {
    services = AppServices(database: AppDatabase(NativeDatabase.memory()));
  });
  tearDown(() => services.dispose());

  test('completing a todo cancels its pending reminder', () async {
    final todoId = await services.todos.create(title: 'Submit the report');
    final scheduled = await services.scheduleReminder(
      title: 'Submit the report',
      scheduledFor: DateTime.now().add(const Duration(hours: 1)),
      tool: TaskTool.setReminder,
      todoId: todoId,
    );
    expect(scheduled, isTrue);

    await services.completeTodo(todoId, completed: true);

    final reminder = (await services.reminders.forTodo(todoId)).single;
    expect(reminder.cancelled, isTrue);
    expect(cancelledIds, contains(reminder.id));
  });

  test('un-completing a todo does not resurrect a cancelled reminder', () async {
    final todoId = await services.todos.create(title: 'Submit the report');
    await services.scheduleReminder(
      title: 'Submit the report',
      scheduledFor: DateTime.now().add(const Duration(hours: 1)),
      tool: TaskTool.setReminder,
      todoId: todoId,
    );
    await services.completeTodo(todoId, completed: true);
    cancelledIds.clear();

    await services.completeTodo(todoId, completed: false);

    final reminder = (await services.reminders.forTodo(todoId)).single;
    expect(reminder.cancelled, isTrue);
    // Un-completing shouldn't even attempt to touch the OS side again.
    expect(cancelledIds, isEmpty);
  });

  test('a reminder that already fired is left alone, not double-cancelled', () async {
    final todoId = await services.todos.create(title: 'Submit the report');
    await services.scheduleReminder(
      title: 'Submit the report',
      scheduledFor: DateTime.now().add(const Duration(hours: 1)),
      tool: TaskTool.setReminder,
      todoId: todoId,
    );
    final firedId = (await services.reminders.forTodo(todoId)).single.id;
    await services.reminders.markFired(firedId);

    await services.completeTodo(todoId, completed: true);

    expect(cancelledIds, isEmpty);
  });

  test('completing a todo with no reminder does nothing extra', () async {
    final todoId = await services.todos.create(title: 'No reminder here');
    await services.completeTodo(todoId, completed: true);
    expect(cancelledIds, isEmpty);
  });
}
