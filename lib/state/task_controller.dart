import 'package:flutter/foundation.dart';

import '../data/demo_tasks.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';

enum TaskView { all, today, upcoming, completed }

class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;
  final List<TaskItem> _tasks = [];
  bool _isLoading = true;
  String _query = '';
  TaskView _view = TaskView.all;
  String _category = 'All categories';
  TaskPriority? _priority;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String get query => _query;
  TaskView get view => _view;
  String get category => _category;
  TaskPriority? get priority => _priority;

  int get openCount => _tasks.where((task) => !task.completed).length;
  int get completedCount => _tasks.where((task) => task.completed).length;
  int get overdueCount {
    final today = dateOnly(DateTime.now());
    return _tasks.where((task) {
      final due = task.dueDate;
      return !task.completed && due != null && dateOnly(due).isBefore(today);
    }).length;
  }

  double get completionRate =>
      _tasks.isEmpty ? 0 : completedCount / _tasks.length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final stored = await _repository.readTasks();
      _tasks
        ..clear()
        ..addAll(stored ?? buildDemoTasks());
      if (stored == null) await _persist();
    } catch (_) {
      _tasks
        ..clear()
        ..addAll(buildDemoTasks());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TaskItem> get visibleTasks {
    final today = dateOnly(DateTime.now());
    final normalizedQuery = _query.trim().toLowerCase();
    final result = _tasks.where((task) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          task.title.toLowerCase().contains(normalizedQuery) ||
          task.notes.toLowerCase().contains(normalizedQuery) ||
          task.category.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          _category == 'All categories' || task.category == _category;
      final matchesPriority = _priority == null || task.priority == _priority;
      final due = task.dueDate == null ? null : dateOnly(task.dueDate!);
      final matchesView = switch (_view) {
        TaskView.all => true,
        TaskView.today =>
          !task.completed && due != null && isSameDay(due, today),
        TaskView.upcoming =>
          !task.completed && due != null && due.isAfter(today),
        TaskView.completed => task.completed,
      };
      return matchesQuery && matchesCategory && matchesPriority && matchesView;
    }).toList();

    result.sort((a, b) {
      if (a.completed != b.completed) return a.completed ? 1 : -1;
      final aDue = a.dueDate;
      final bDue = b.dueDate;
      if (aDue == null && bDue != null) return 1;
      if (aDue != null && bDue == null) return -1;
      if (aDue != null && bDue != null) {
        final dueOrder = dateOnly(aDue).compareTo(dateOnly(bDue));
        if (dueOrder != 0) return dueOrder;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return result;
  }

  List<String> get categories {
    final found =
        _tasks
            .map((task) => task.category)
            .where(
              (value) => value.trim().isNotEmpty && value != 'All categories',
            )
            .toSet()
            .toList()
          ..sort();
    return ['All categories', ...found];
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setView(TaskView value) {
    _view = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setPriority(TaskPriority? value) {
    _priority = value;
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required String notes,
    required String category,
    required TaskPriority priority,
    DateTime? dueDate,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    _tasks.insert(
      0,
      TaskItem(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        title: cleanTitle,
        notes: notes.trim(),
        category: category.trim().isEmpty ? 'Personal' : category.trim(),
        priority: priority,
        createdAt: DateTime.now(),
        dueDate: dueDate == null ? null : dateOnly(dueDate),
        completed: false,
      ),
    );
    await _persistAndNotify();
  }

  Future<void> updateTask(TaskItem updated) async {
    final index = _tasks.indexWhere((task) => task.id == updated.id);
    if (index < 0) return;
    _tasks[index] = updated;
    _ensureCategorySelection();
    await _persistAndNotify();
  }

  Future<void> toggleCompleted(TaskItem task) async {
    final updated = task.copyWith(
      completed: !task.completed,
      completedAt: task.completed ? null : DateTime.now(),
      clearCompletedAt: task.completed,
    );
    await updateTask(updated);
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    _ensureCategorySelection();
    await _persistAndNotify();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((task) => task.completed);
    _ensureCategorySelection();
    await _persistAndNotify();
  }

  void _ensureCategorySelection() {
    if (_category != 'All categories' &&
        !_tasks.any((task) => task.category == _category)) {
      _category = 'All categories';
    }
  }

  Future<void> _persistAndNotify() async {
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => _repository.saveTasks(List.unmodifiable(_tasks));
}
