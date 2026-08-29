import 'package:flutter/foundation.dart';
import '../../../core/models/view_state.dart';
import '../../../core/models/note.dart';
import '../../../core/models/todo_item.dart';
import '../../../core/models/health_target.dart';
import '../../../core/services/i_goal_context_service.dart';

class GoalsViewModel extends ChangeNotifier {
  final IGoalContextService _goalContextService;

  GoalsViewModel({
    required IGoalContextService goalContextService,
  }) : _goalContextService = goalContextService;

  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  List<TodoItem> _todos = [];
  List<TodoItem> get todos => _todos;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  List<HealthTarget> _healthTargets = [];
  List<HealthTarget> get healthTargets => _healthTargets;

  String? _error;
  String? get error => _error;

  void init() async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      _todos = await _goalContextService.getAllTodos();
      _notes = await _goalContextService.getAllNotes();
      _healthTargets = await _goalContextService.getActiveTargets();
      _state = ViewState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = ViewState.error;
    }
    notifyListeners();
  }

  Future<void> addTodo({
    required String title,
    String? description,
    DateTime? deadline,
  }) async {
    try {
      final newTodo = await _goalContextService.createTodo(
        title: title,
        description: description,
        deadline: deadline,
      );
      _todos = [..._todos, newTodo];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTodo(String id) async {
    try {
      final index = _todos.indexWhere((t) => t.id == id);
      if (index != -1) {
        final current = _todos[index];
        final updated = current.copyWith(isCompleted: !current.isCompleted);
        await _goalContextService.updateTodo(updated);
        _todos[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await _goalContextService.deleteTodo(id);
      _todos.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addNote(String text) async {
    try {
      final newNote = await _goalContextService.createNote(text);
      _notes = [newNote, ..._notes];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _goalContextService.deleteNote(id);
      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addHealthTarget({
    required String metric,
    required double threshold,
  }) async {
    try {
      final newTarget = await _goalContextService.createTarget(
        metric: metric,
        threshold: threshold,
      );
      _healthTargets = [..._healthTargets, newTarget];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHealthTarget(String id) async {
    try {
      await _goalContextService.deleteTarget(id);
      _healthTargets.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
