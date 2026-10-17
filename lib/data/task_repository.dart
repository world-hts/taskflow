import '../models/task_item.dart';

abstract interface class TaskRepository {
  Future<List<TaskItem>?> readTasks();
  Future<void> saveTasks(List<TaskItem> tasks);
}
