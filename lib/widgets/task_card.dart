import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.dimmed = false,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = dateOnly(DateTime.now());
    final overdue = task.isOverdueOn(today);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.taskIcon,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: colors.taskIconInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink.withValues(alpha: dimmed ? 0.45 : 1),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                    decorationColor: colors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                shortMonthDay(task.dueDate),
                style: TextStyle(
                  color: overdue && !task.done ? colors.badge : colors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: task.done ? 'Mark as open' : 'Check task',
                child: Material(
                  color: task.done ? colors.ink : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: task.done ? colors.ink : colors.line,
                      width: 1.4,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onToggle,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: task.done ? colors.card : colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
