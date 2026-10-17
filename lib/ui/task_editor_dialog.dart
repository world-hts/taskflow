import 'package:flutter/material.dart';

import '../models/task_item.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.notes,
    required this.category,
    required this.priority,
    required this.dueDate,
  });

  final String title;
  final String notes;
  final String category;
  final TaskPriority priority;
  final DateTime? dueDate;
}

class TaskEditorDialog extends StatefulWidget {
  const TaskEditorDialog({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _categoryController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _categoryController = TextEditingController(
      text: task?.category ?? 'Personal',
    );
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 8),
      helpText: 'Choose a due date',
    );
    if (selected != null && mounted) {
      setState(() => _dueDate = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text.trim(),
        notes: _notesController.text.trim(),
        category: _categoryController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    final width = MediaQuery.sizeOf(context).width;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width < 500 ? 20 : 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1E9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_task_rounded,
                        color: Color(0xFF185C4B),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit task' : 'Create a task',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEditing
                                ? 'Make a quick update.'
                                : 'A little progress adds up.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF78847C)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const _FieldLabel('Task name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 90,
                  decoration: const InputDecoration(
                    hintText: 'What needs to get done?',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task name.'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Notes (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 280,
                  decoration: const InputDecoration(
                    hintText: 'Add a little context…',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Category'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _categoryController,
                            maxLength: 30,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Work',
                              counterText: '',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Add a category.'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Priority'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<TaskPriority>(
                            initialValue: _priority,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                            ),
                            items: TaskPriority.values
                                .map(
                                  (priority) => DropdownMenuItem(
                                    value: priority,
                                    child: Text(priorityLabel(priority)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _FieldLabel('Due date'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE3E8E0)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 13,
                            ),
                          ),
                          onPressed: _selectDate,
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _dueDate == null
                                ? 'Choose a date'
                                : formatDate(_dueDate!),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          tooltip: 'Clear due date',
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(
                          isEditing ? Icons.check_rounded : Icons.add_rounded,
                          size: 19,
                        ),
                        label: Text(isEditing ? 'Save changes' : 'Create task'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFF29372F),
      fontSize: 13,
    ),
  );
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
