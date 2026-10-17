import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/models/task_item.dart';

void main() {
  group('TaskItem serialization', () {
    test('round-trips optional date and completed state', () {
      final task = TaskItem(
        id: 'task-1',
        title: 'Review portfolio',
        notes: 'Check the latest changes',
        category: 'Work',
        priority: TaskPriority.urgent,
        createdAt: DateTime(2026, 10, 16, 9, 30),
        dueDate: DateTime(2026, 10, 18),
        completed: true,
        completedAt: DateTime(2026, 10, 16, 10),
      );

      final restored = TaskItem.fromJson(task.toJson());

      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.notes, task.notes);
      expect(restored.category, task.category);
      expect(restored.priority, task.priority);
      expect(restored.createdAt, task.createdAt);
      expect(restored.dueDate, task.dueDate);
      expect(restored.completed, isTrue);
      expect(restored.completedAt, task.completedAt);
    });

    test('uses a safe medium priority for unknown saved values', () {
      final restored = TaskItem.fromJson({
        'id': 'old-task',
        'title': 'Older task',
        'priority': 'not-a-priority',
      });

      expect(restored.priority, TaskPriority.medium);
      expect(restored.completed, isFalse);
      expect(restored.notes, isEmpty);
    });
  });

  test('dateOnly removes time components', () {
    expect(dateOnly(DateTime(2026, 10, 16, 23, 58)), DateTime(2026, 10, 16));
    expect(
      isSameDay(DateTime(2026, 10, 16, 9), DateTime(2026, 10, 16, 22)),
      isTrue,
    );
  });
}
