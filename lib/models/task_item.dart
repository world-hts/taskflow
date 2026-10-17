enum TaskPriority { low, medium, high, urgent }

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.notes,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.completed,
    this.dueDate,
    this.completedAt,
  });

  final String id;
  final String title;
  final String notes;
  final String category;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? completedAt;

  TaskItem copyWith({
    String? id,
    String? title,
    String? notes,
    String? category,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'category': category,
    'priority': priority.name,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory TaskItem.fromJson(Map<String, Object?> json) {
    final priorityName = json['priority'] as String? ?? 'medium';
    final priority = TaskPriority.values.firstWhere(
      (value) => value.name == priorityName,
      orElse: () => TaskPriority.medium,
    );

    return TaskItem(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Untitled task',
      notes: json['notes'] as String? ?? '',
      category: json['category'] as String? ?? 'Personal',
      priority: priority,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? ''),
      completed: json['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

String priorityLabel(TaskPriority priority) => switch (priority) {
  TaskPriority.low => 'Low',
  TaskPriority.medium => 'Medium',
  TaskPriority.high => 'High',
  TaskPriority.urgent => 'Urgent',
};

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
