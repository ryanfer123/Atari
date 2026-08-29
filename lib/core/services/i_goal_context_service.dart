import '../models/note.dart';
import '../models/todo_item.dart';
import '../models/health_target.dart';
import '../models/calendar_event.dart';

abstract class IGoalContextService {
  Future<List<Note>> getAllNotes();
  Future<Note> createNote(String text);
  Future<Note> updateNote(String id, String text);
  Future<void> deleteNote(String id);

  Future<List<TodoItem>> getAllTodos();
  Future<List<TodoItem>> getTodosDueWithin(Duration window);
  Future<TodoItem> createTodo({required String title, String? description, DateTime? deadline});
  Future<TodoItem> updateTodo(TodoItem updated);
  Future<void> completeTodo(String id);
  Future<void> deleteTodo(String id);

  Future<List<HealthTarget>> getActiveTargets();
  Future<HealthTarget> createTarget({required String metric, required double threshold});
  Future<HealthTarget> updateTarget(HealthTarget updated);
  Future<void> deleteTarget(String id);

  Future<bool> get isCalendarConnected;
  Future<void> connectCalendar();
  Future<void> disconnectCalendar();
  Future<List<CalendarEvent>> getEventsWithin(Duration window);
}
