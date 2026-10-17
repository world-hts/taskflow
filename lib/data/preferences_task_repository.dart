import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import 'task_repository.dart';

class PreferencesTaskRepository implements TaskRepository {
  PreferencesTaskRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'taskflow.tasks.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<TaskItem>?> readTasks() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskItem.fromJson)
          .toList(growable: true);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveTasks(List<TaskItem> tasks) async {
    final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await _preferences.setString(_storageKey, encoded);
  }
}
