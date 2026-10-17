import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/task_repository.dart';
import 'package:taskflow/models/task_item.dart';
import 'package:taskflow/state/task_controller.dart';

class MemoryTaskRepository implements TaskRepository {
  MemoryTaskRepository([this.stored]);

  List<TaskItem>? stored;
  int saveCount = 0;

  @override
  Future<List<TaskItem>?> readTasks() async =>
      stored == null ? null : List.of(stored!);

  @override
  Future<void> saveTasks(List<TaskItem> tasks) async {
    stored = List.of(tasks);
    saveCount++;
  }
}

TaskItem task({
  String id = '1',
  String title = 'Prepare report',
  String category = 'Work',
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  bool completed = false,
}) => TaskItem(
  id: id,
  title: title,
  notes: 'Notes',
  category: category,
  priority: priority,
  createdAt: DateTime(2026, 10, 1),
  dueDate: dueDate,
  completed: completed,
);

void main() {
  group('TaskController', () {
    test(
      'seeds and persists example tasks only when storage is empty',
      () async {
        final repository = MemoryTaskRepository();
        final controller = TaskController(repository);
        await controller.load();

        expect(controller.isLoading, isFalse);
        expect(controller.tasks, isNotEmpty);
        expect(repository.saveCount, 1);
        controller.dispose();
      },
    );

    test('filters by search, category, priority and completed view', () async {
      final today = dateOnly(DateTime.now());
      final repository = MemoryTaskRepository([
        task(
          id: 'a',
          title: 'Write release notes',
          category: 'Work',
          priority: TaskPriority.high,
          dueDate: today,
        ),
        task(
          id: 'b',
          title: 'Buy groceries',
          category: 'Personal',
          priority: TaskPriority.low,
          dueDate: today.add(const Duration(days: 2)),
        ),
        task(
          id: 'c',
          title: 'Old completed task',
          category: 'Work',
          completed: true,
        ),
      ]);
      final controller = TaskController(repository);
      await controller.load();

      controller.setQuery('release');
      expect(controller.visibleTasks.map((item) => item.id), ['a']);

      controller.setQuery('');
      controller.setCategory('Personal');
      expect(controller.visibleTasks.map((item) => item.id), ['b']);

      controller.setCategory('All categories');
      controller.setPriority(TaskPriority.high);
      expect(controller.visibleTasks.map((item) => item.id), ['a']);

      controller.setPriority(null);
      controller.setView(TaskView.completed);
      expect(controller.visibleTasks.map((item) => item.id), ['c']);
      controller.dispose();
    });

    test('adds, completes, updates and deletes tasks persistently', () async {
      final repository = MemoryTaskRepository(<TaskItem>[]);
      final controller = TaskController(repository);
      await controller.load();
      final before = repository.saveCount;

      await controller.addTask(
        title: '  Ship TaskFlow  ',
        notes: 'Final check',
        category: 'Work',
        priority: TaskPriority.urgent,
      );
      expect(controller.tasks, hasLength(1));
      expect(controller.tasks.single.title, 'Ship TaskFlow');
      expect(repository.saveCount, greaterThan(before));

      final created = controller.tasks.single;
      await controller.toggleCompleted(created);
      expect(controller.tasks.single.completed, isTrue);
      expect(controller.tasks.single.completedAt, isNotNull);

      await controller.updateTask(
        controller.tasks.single.copyWith(title: 'Shipped TaskFlow'),
      );
      expect(controller.tasks.single.title, 'Shipped TaskFlow');

      await controller.deleteTask(created.id);
      expect(controller.tasks, isEmpty);
      controller.dispose();
    });

    test('does not create a task with a blank title', () async {
      final repository = MemoryTaskRepository(<TaskItem>[]);
      final controller = TaskController(repository);
      await controller.load();
      await controller.addTask(
        title: '  ',
        notes: '',
        category: 'Personal',
        priority: TaskPriority.low,
      );
      expect(controller.tasks, isEmpty);
      controller.dispose();
    });
  });
}
