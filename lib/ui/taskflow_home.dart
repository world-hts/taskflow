import 'dart:async';

import 'package:flutter/material.dart';

import '../data/task_repository.dart';
import '../models/task_item.dart';
import '../state/task_controller.dart';
import 'task_editor_dialog.dart';

const _ink = Color(0xFF22332B);
const _muted = Color(0xFF78847C);
const _green = Color(0xFF185C4B);
const _lime = Color(0xFFC8F27C);
const _line = Color(0xFFE6EBE3);

class TaskFlowHome extends StatefulWidget {
  const TaskFlowHome({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<TaskFlowHome> createState() => _TaskFlowHomeState();
}

class _TaskFlowHomeState extends State<TaskFlowHome> {
  late final TaskController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TaskController(widget.repository);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final isMobile = !isDesktop;
            return Scaffold(
              appBar: isMobile
                  ? AppBar(
                      title: const _BrandMark(compact: true),
                      titleSpacing: 18,
                      actions: [
                        IconButton(
                          tooltip: 'Search tasks',
                          onPressed: () => _showSearch(context),
                          icon: const Icon(Icons.search_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                    )
                  : null,
              bottomNavigationBar: isDesktop
                  ? null
                  : NavigationBar(
                      height: 72,
                      selectedIndex: _navigationIndex(_controller.view),
                      onDestinationSelected: (index) =>
                          _controller.setView(_viewAt(index)),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_rounded),
                          label: 'All',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.today_rounded),
                          label: 'Today',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.upcoming_rounded),
                          label: 'Upcoming',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.task_alt_rounded),
                          label: 'Done',
                        ),
                      ],
                    ),
              floatingActionButton: isDesktop
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New task'),
                    ),
              body: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        if (isDesktop)
                          _Sidebar(
                            controller: _controller,
                            onCreate: _openEditor,
                          ),
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF4F6F2),
                            child: _DashboardContent(
                              controller: _controller,
                              isDesktop: isDesktop,
                              isMobile: isMobile,
                              onCreate: _openEditor,
                              onEdit: _openEditor,
                              onSearch: () => _showSearch(context),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditor({TaskItem? task}) async {
    final draft = await showDialog<TaskDraft>(
      context: context,
      builder: (_) => TaskEditorDialog(task: task),
    );
    if (!mounted || draft == null) return;

    if (task == null) {
      await _controller.addTask(
        title: draft.title,
        notes: draft.notes,
        category: draft.category,
        priority: draft.priority,
        dueDate: draft.dueDate,
      );
    } else {
      await _controller.updateTask(
        task.copyWith(
          title: draft.title,
          notes: draft.notes,
          category: draft.category,
          priority: draft.priority,
          dueDate: draft.dueDate,
          clearDueDate: draft.dueDate == null,
        ),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(task == null ? 'Task created.' : 'Task updated.'),
        ),
      );
    }
  }

  Future<void> _showSearch(BuildContext context) async {
    final searchController = TextEditingController(text: _controller.query);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Find a task'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search title, notes or category',
          ),
          onChanged: _controller.setQuery,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.setQuery('');
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    searchController.dispose();
  }
}

int _navigationIndex(TaskView view) => switch (view) {
  TaskView.all => 0,
  TaskView.today => 1,
  TaskView.upcoming => 2,
  TaskView.completed => 3,
};

TaskView _viewAt(int index) => switch (index) {
  1 => TaskView.today,
  2 => TaskView.upcoming,
  3 => TaskView.completed,
  _ => TaskView.all,
};

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 34 : 40,
        height: compact ? 34 : 40,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.check_rounded, color: _lime, size: 25),
      ),
      const SizedBox(width: 11),
      Text(
        'TaskFlow',
        style: TextStyle(
          fontSize: compact ? 20 : 23,
          fontWeight: FontWeight.w900,
          color: _ink,
          letterSpacing: -0.7,
        ),
      ),
    ],
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.controller, required this.onCreate});

  final TaskController controller;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242,
      padding: const EdgeInsets.fromLTRB(22, 28, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: _line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 5, bottom: 40),
              child: _BrandMark(),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 17,
                    horizontal: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Create a task',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const _SmallLabel('WORKSPACE'),
            const SizedBox(height: 12),
            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'All tasks',
              count: controller.openCount,
              selected: controller.view == TaskView.all,
              onTap: () => controller.setView(TaskView.all),
            ),
            _NavItem(
              icon: Icons.today_rounded,
              label: 'Today',
              selected: controller.view == TaskView.today,
              onTap: () => controller.setView(TaskView.today),
            ),
            _NavItem(
              icon: Icons.upcoming_rounded,
              label: 'Upcoming',
              selected: controller.view == TaskView.upcoming,
              onTap: () => controller.setView(TaskView.upcoming),
            ),
            _NavItem(
              icon: Icons.task_alt_rounded,
              label: 'Completed',
              selected: controller.view == TaskView.completed,
              onTap: () => controller.setView(TaskView.completed),
            ),
            const SizedBox(height: 29),
            const _SmallLabel('CATEGORIES'),
            const SizedBox(height: 10),
            for (final category in controller.categories.where(
              (item) => item != 'All categories',
            ))
              _CategoryNavItem(
                category: category,
                selected: controller.category == category,
                onTap: () => controller.setCategory(
                  controller.category == category ? 'All categories' : category,
                ),
              ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6ED),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: _lime,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: _green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Small steps.\nSteady progress.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(controller.completionRate * 100).round()}% of your tasks completed',
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: controller.completionRate,
                      minHeight: 6,
                      backgroundColor: Colors.white,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 15, color: _muted),
                SizedBox(width: 7),
                Text(
                  'Your tasks stay on this device',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: _muted,
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Material(
      color: selected ? const Color(0xFFEAF3E9) : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: selected ? _green : _muted, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? _green : _muted,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? _green : _muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CategoryNavItem extends StatelessWidget {
  const _CategoryNavItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });
  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category.toLowerCase()) {
      'work' => Icons.work_outline_rounded,
      'finance' => Icons.account_balance_wallet_outlined,
      'personal' => Icons.person_outline_rounded,
      _ => Icons.folder_outlined,
    };
    return _NavItem(
      icon: icon,
      label: category,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.controller,
    required this.isDesktop,
    required this.isMobile,
    required this.onCreate,
    required this.onEdit,
    required this.onSearch,
  });

  final TaskController controller;
  final bool isDesktop;
  final bool isMobile;
  final VoidCallback onCreate;
  final Future<void> Function({TaskItem? task}) onEdit;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isDesktop ? 30 : 20,
        isMobile ? 16 : 32,
        34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) _TopHeader(onSearch: onSearch),
              _WelcomeHeader(isMobile: isMobile, onCreate: onCreate),
              const SizedBox(height: 26),
              _StatsRow(controller: controller, isMobile: isMobile),
              const SizedBox(height: 30),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: _TaskPanel(
                        controller: controller,
                        isMobile: false,
                        onEdit: onEdit,
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      flex: 4,
                      child: _FocusPanel(controller: controller),
                    ),
                  ],
                )
              else ...[
                _TaskPanel(
                  controller: controller,
                  isMobile: isMobile,
                  onEdit: onEdit,
                ),
                const SizedBox(height: 18),
                _FocusPanel(controller: controller),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: _muted,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Stored locally on this device. No account required.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
                  Text(
                    'TASKFLOW V4.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: _muted.withValues(alpha: .8),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 34),
    child: Row(
      children: [
        Text(
          _todayLabel(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.7,
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onSearch,
          style: OutlinedButton.styleFrom(
            foregroundColor: _muted,
            side: const BorderSide(color: _line),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Search tasks', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 14),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFDDEBE0),
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: const Text(
            'TF',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.isMobile, required this.onCreate});
  final bool isMobile;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0E4),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_sunny_outlined, size: 13, color: _green),
                  SizedBox(width: 6),
                  Text(
                    'A FRESH START',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Make room for\nwhat matters.',
              style: TextStyle(
                fontSize: isMobile ? 29 : 38,
                letterSpacing: -1.3,
                height: 1.08,
                fontWeight: FontWeight.w900,
                color: _ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A clear plan turns busy days into meaningful progress.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: _muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      if (!isMobile) ...[
        const SizedBox(width: 20),
        FilledButton.icon(
          onPressed: onCreate,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text(
            'New task',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ],
  );
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller, required this.isMobile});
  final TaskController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        'Open tasks',
        '${controller.openCount}',
        'Ready when you are',
        Icons.radio_button_unchecked_rounded,
        const Color(0xFFE9F2E6),
        _green,
      ),
      _StatData(
        'Completed',
        '${controller.completedCount}',
        'Progress in motion',
        Icons.check_circle_outline_rounded,
        const Color(0xFFE9F0FB),
        const Color(0xFF4166A8),
      ),
      _StatData(
        'Overdue',
        '${controller.overdueCount}',
        controller.overdueCount == 0
            ? 'You’re right on track'
            : 'Needs a little attention',
        Icons.schedule_rounded,
        const Color(0xFFFFF0DD),
        const Color(0xFFB66B1B),
      ),
    ];
    if (isMobile) {
      return SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 11),
          itemBuilder: (_, index) =>
              SizedBox(width: 220, child: _StatCard(data: cards[index])),
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 15),
          Expanded(child: _StatCard(data: cards[i])),
        ],
      ],
    );
  }
}

class _StatData {
  const _StatData(
    this.title,
    this.value,
    this.caption,
    this.icon,
    this.bg,
    this.fg,
  );
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data.title,
                style: const TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: data.bg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(data.icon, size: 18, color: data.fg),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          style: const TextStyle(
            fontSize: 28,
            height: 1.05,
            letterSpacing: -1,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data.caption,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 10.5),
        ),
      ],
    ),
  );
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({
    required this.controller,
    required this.isMobile,
    required this.onEdit,
  });
  final TaskController controller;
  final bool isMobile;
  final Future<void> Function({TaskItem? task}) onEdit;

  @override
  Widget build(BuildContext context) {
    final visible = controller.visibleTasks;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _viewTitle(controller.view),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${visible.length} ${visible.length == 1 ? 'task' : 'tasks'} to keep in view',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                PopupMenuButton<TaskPriority?>(
                  tooltip: 'Filter priority',
                  initialValue: controller.priority,
                  onSelected: controller.setPriority,
                  itemBuilder: (_) => [
                    const PopupMenuItem<TaskPriority?>(
                      value: null,
                      child: Text('All priorities'),
                    ),
                    ...TaskPriority.values.map(
                      (priority) => PopupMenuItem(
                        value: priority,
                        child: Text(priorityLabel(priority)),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 16, color: _muted),
                        const SizedBox(width: 7),
                        Text(
                          controller.priority == null
                              ? 'Filter'
                              : priorityLabel(controller.priority!),
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: _muted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ViewPill(
                  label: 'All',
                  selected: controller.view == TaskView.all,
                  onTap: () => controller.setView(TaskView.all),
                ),
                _ViewPill(
                  label: 'Today',
                  selected: controller.view == TaskView.today,
                  onTap: () => controller.setView(TaskView.today),
                ),
                _ViewPill(
                  label: 'Upcoming',
                  selected: controller.view == TaskView.upcoming,
                  onTap: () => controller.setView(TaskView.upcoming),
                ),
                _ViewPill(
                  label: 'Completed',
                  selected: controller.view == TaskView.completed,
                  onTap: () => controller.setView(TaskView.completed),
                ),
              ],
            ),
          ),
          if (isMobile) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value:
                            controller.categories.contains(controller.category)
                            ? controller.category
                            : 'All categories',
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        items: controller.categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.setCategory(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F6),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TaskPriority?>(
                        isExpanded: true,
                        value: controller.priority,
                        hint: const Text(
                          'All priorities',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          const DropdownMenuItem<TaskPriority?>(
                            value: null,
                            child: Text(
                              'All priorities',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...TaskPriority.values.map(
                            (priority) => DropdownMenuItem<TaskPriority?>(
                              value: priority,
                              child: Text(
                                priorityLabel(priority),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: controller.setPriority,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (controller.category != 'All categories')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_open_outlined,
                    size: 15,
                    color: _muted,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Category: ${controller.category}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => controller.setCategory('All categories'),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          if (visible.isEmpty)
            _EmptyTasks(onCreate: onEdit)
          else
            ...visible.map(
              (task) => _TaskRow(
                key: ValueKey(task.id),
                task: task,
                onToggle: () => controller.toggleCompleted(task),
                onEdit: () => onEdit(task: task),
                onDelete: () => _confirmDelete(context, controller, task),
              ),
            ),
          if (controller.completedCount > 0 &&
              controller.view == TaskView.completed)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmClearCompleted(context, controller),
                icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                label: const Text('Clear completed'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskController controller,
    TaskItem task,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('“${task.title}” will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep task'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await controller.deleteTask(task.id);
    }
  }

  Future<void> _confirmClearCompleted(
    BuildContext context,
    TaskController controller,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear completed tasks?'),
        content: const Text(
          'This removes all completed tasks stored on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (shouldClear == true) {
      await controller.clearCompleted();
    }
  }
}

String _viewTitle(TaskView view) => switch (view) {
  TaskView.all => 'Your tasks',
  TaskView.today => 'Due today',
  TaskView.upcoming => 'Coming up',
  TaskView.completed => 'What you’ve done',
};

class _ViewPill extends StatelessWidget {
  const _ViewPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _green : const Color(0xFFF6F8F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _green : _line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : _muted,
          ),
        ),
      ),
    ),
  );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final dueColor = _dueColor(task);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(10, 12, 5, 12),
      decoration: BoxDecoration(
        color: task.completed ? const Color(0xFFFAFBF9) : Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 35,
            height: 32,
            child: Checkbox(
              value: task.completed,
              onChanged: (_) => onToggle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              activeColor: _green,
              side: const BorderSide(color: Color(0xFFC8D1C7), width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: task.completed ? const Color(0xFF919A92) : _ink,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.notes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: _muted),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TinyTag(
                      label: task.category,
                      bg: const Color(0xFFF0F3ED),
                      fg: const Color(0xFF5D6C60),
                    ),
                    _TinyTag(
                      label: priorityLabel(task.priority),
                      bg: priorityColor.withValues(alpha: .12),
                      fg: priorityColor,
                      dot: true,
                    ),
                    if (task.dueDate != null)
                      _TinyTag(
                        label: _dueLabel(task),
                        bg: dueColor.withValues(alpha: .11),
                        fg: dueColor,
                        icon: Icons.calendar_today_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Task actions',
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              }
              if (value == 'delete') {
                onDelete();
              }
            },
            icon: const Icon(Icons.more_horiz_rounded, size: 20, color: _muted),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 17),
                    SizedBox(width: 9),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 17),
                    SizedBox(width: 9),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({
    required this.label,
    required this.bg,
    required this.fg,
    this.dot = false,
    this.icon,
  });
  final String label;
  final Color bg;
  final Color fg;
  final bool dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        if (icon != null) ...[
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.onCreate});
  final Future<void> Function({TaskItem? task}) onCreate;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF2E7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.done_all_rounded, color: _green, size: 25),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nothing on the list',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Enjoy the breathing room or add a new task.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: _muted),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => onCreate(),
          icon: const Icon(Icons.add_rounded, size: 17),
          label: const Text('Create a task'),
        ),
      ],
    ),
  );
}

class _FocusPanel extends StatelessWidget {
  const _FocusPanel({required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final dueToday =
        controller.tasks
            .where(
              (task) =>
                  !task.completed &&
                  task.dueDate != null &&
                  isSameDay(dateOnly(task.dueDate!), today),
            )
            .toList()
          ..sort(
            (a, b) =>
                _priorityRank(b.priority).compareTo(_priorityRank(a.priority)),
          );
    final focusTasks = dueToday.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR FOCUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: Color(0xFFCAE5D1),
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'One thing at a time.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D725E),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: _lime,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Keep today realistic. Finish what matters most before adding more.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: Color(0xFFD8E9DD),
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TODAY’S PRIORITIES',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB8D9C2),
                  ),
                ),
              ),
              Text(
                '${focusTasks.length} ${focusTasks.length == 1 ? 'task' : 'tasks'}',
                style: const TextStyle(fontSize: 10, color: Color(0xFFB8D9C2)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (focusTasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: _lime,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No tasks due today. Take a breath.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            )
          else
            ...focusTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: const Color(0xFF246552),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () => controller.toggleCompleted(task),
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF99C6A9),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.transparent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _priorityColor(task.priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: controller.completionRate,
                    color: _lime,
                    backgroundColor: const Color(0xFF397965),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(controller.completionRate * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Overall completion',
            style: TextStyle(fontSize: 10, color: Color(0xFFB8D9C2)),
          ),
        ],
      ),
    );
  }
}

int _priorityRank(TaskPriority priority) => switch (priority) {
  TaskPriority.low => 0,
  TaskPriority.medium => 1,
  TaskPriority.high => 2,
  TaskPriority.urgent => 3,
};

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => const Color(0xFF4D8A67),
  TaskPriority.medium => const Color(0xFF5074B7),
  TaskPriority.high => const Color(0xFFC57C2D),
  TaskPriority.urgent => const Color(0xFFC94E48),
};

Color _dueColor(TaskItem task) {
  final due = task.dueDate;
  if (due == null) return _muted;
  final normalized = dateOnly(due);
  final today = dateOnly(DateTime.now());
  if (normalized.isBefore(today)) return const Color(0xFFBF493F);
  if (isSameDay(normalized, today)) return const Color(0xFFB66B1B);
  return const Color(0xFF5573A8);
}

String _dueLabel(TaskItem task) {
  final due = task.dueDate;
  if (due == null) return 'No due date';
  final normalized = dateOnly(due);
  final today = dateOnly(DateTime.now());
  if (normalized.isBefore(today)) return 'Overdue · ${_shortDate(due)}';
  if (isSameDay(normalized, today)) return 'Today';
  if (isSameDay(normalized, today.add(const Duration(days: 1))))
    return 'Tomorrow';
  return _shortDate(due);
}

String _shortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}

String _todayLabel() {
  const days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  final now = DateTime.now();
  return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
}
