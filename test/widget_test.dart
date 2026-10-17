import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/data/task_repository.dart';
import 'package:taskflow/main.dart';
import 'package:taskflow/models/task_item.dart';

class _FakeRepository implements TaskRepository {
  _FakeRepository(this.tasks);
  List<TaskItem>? tasks;

  @override
  Future<List<TaskItem>?> readTasks() async =>
      tasks == null ? null : List.of(tasks!);

  @override
  Future<void> saveTasks(List<TaskItem> value) async {
    tasks = List.of(value);
  }
}

void main() {
  testWidgets('renders the dashboard and stored tasks', (tester) async {
    final repository = _FakeRepository([
      TaskItem(
        id: 'widget-task',
        title: 'Check TaskFlow dashboard',
        notes: 'Widget test row',
        category: 'Work',
        priority: TaskPriority.high,
        createdAt: DateTime(2026, 10, 16),
        dueDate: DateTime.now(),
        completed: false,
      ),
    ]);

    await tester.pumpWidget(TaskFlowApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Your tasks'), findsOneWidget);
    // The task title may appear in both the focus panel and task list.
    expect(find.text('Check TaskFlow dashboard'), findsWidgets);
    expect(find.text('Open tasks'), findsOneWidget);
  });
}
