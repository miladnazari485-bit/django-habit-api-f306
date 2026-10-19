import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../models/task_item.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final today = dateOnly(DateTime.now());
    final open = state.tasks.where((task) => !task.done).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final overdue = open.where((task) => task.isOverdueOn(today)).toList();
    final dueToday = open
        .where((task) => isSameDay(task.dueDate, today))
        .toList();
    final upcoming = open.where((task) => task.dueDate.isAfter(today)).toList();
    final done = state.tasks.where((task) => task.done).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    return Column(
      children: [
        PageHeader(
          title: 'Tasks',
          night: state.night,
          onMenu: onMenu,
          onToggleTheme: state.toggleNight,
        ),
        Expanded(
          child: state.tasks.isEmpty
              ? _EmptyTasks(colors: colors)
              : ListView(
                  primary: false,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (overdue.isNotEmpty)
                      _TaskGroup(
                        title: 'Overdue',
                        tasks: overdue,
                        state: state,
                      ),
                    if (dueToday.isNotEmpty)
                      _TaskGroup(title: 'Today', tasks: dueToday, state: state),
                    if (upcoming.isNotEmpty)
                      _TaskGroup(
                        title: 'Upcoming',
                        tasks: upcoming,
                        state: state,
                      ),
                    if (done.isNotEmpty)
                      _TaskGroup(
                        title: 'Done',
                        tasks: done,
                        state: state,
                        dimmed: true,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({
    required this.title,
    required this.tasks,
    required this.state,
    this.dimmed = false,
  });

  final String title;
  final List<TaskItem> tasks;
  final AppState state;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: colors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          for (final task in tasks) ...[
            TaskCard(
              task: task,
              dimmed: dimmed,
              onToggle: () => state.toggleTask(task.id),
              onTap: () => showComposer(context, task: task),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 36, color: colors.muted),
            const SizedBox(height: 10),
            Text(
              'No tasks yet',
              style: TextStyle(
                color: colors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A task is a one-off, like buying groceries. Habits are the things you repeat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
