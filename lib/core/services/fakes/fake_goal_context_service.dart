import 'dart:async';
import '../i_goal_context_service.dart';
import '../../models/note.dart';
import '../../models/todo_item.dart';
import '../../models/health_target.dart';
import '../../models/calendar_event.dart';

class FakeGoalContextService implements IGoalContextService {
  @override
  Future<List<Note>> getAllNotes() async => [];
  
  @override
  Future<Note> createNote(String text) async => Note(id: '1', text: text, createdAt: DateTime.now(), updatedAt: DateTime.now());
  
  @override
  Future<Note> updateNote(String id, String text) async => Note(id: id, text: text, createdAt: DateTime.now(), updatedAt: DateTime.now());
  
  @override
  Future<void> deleteNote(String id) async {}

  @override
  Future<List<TodoItem>> getAllTodos() async => [
    TodoItem(id: '1', title: 'Study session', isCompleted: false, createdAt: DateTime.now(), deadline: DateTime.now().add(const Duration(hours: 2)))
  ];
  
  @override
  Future<List<TodoItem>> getTodosDueWithin(Duration window) async => await getAllTodos();
  
  @override
  Future<TodoItem> createTodo({required String title, String? description, DateTime? deadline}) async {
    return TodoItem(id: '2', title: title, description: description, deadline: deadline, isCompleted: false, createdAt: DateTime.now());
  }
  
  @override
  Future<TodoItem> updateTodo(TodoItem updated) async => updated;
  
  @override
  Future<void> completeTodo(String id) async {}
  
  @override
  Future<void> deleteTodo(String id) async {}

  @override
  Future<List<HealthTarget>> getActiveTargets() async => [
    const HealthTarget(id: '1', metric: 'Steps', threshold: 8000, current: 5000, isMet: false)
  ];
  
  @override
  Future<HealthTarget> createTarget({required String metric, required double threshold}) async {
    return HealthTarget(id: '2', metric: metric, threshold: threshold, isMet: false);
  }
  
  @override
  Future<HealthTarget> updateTarget(HealthTarget updated) async => updated;
  
  @override
  Future<void> deleteTarget(String id) async {}

  @override
  Future<bool> get isCalendarConnected async => false;
  
  @override
  Future<void> connectCalendar() async {}
  
  @override
  Future<void> disconnectCalendar() async {}
  
  @override
  Future<List<CalendarEvent>> getEventsWithin(Duration window) async => [];
}
