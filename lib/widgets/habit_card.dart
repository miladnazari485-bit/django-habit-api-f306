import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import 'heatmap.dart';
import 'ring_button.dart';

class HabitNameChip extends StatelessWidget {
  const HabitNameChip({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundOn(color),
          fontWeight: FontWeight.w800,
          fontSize: 14,
          height: 1.1,
        ),
      ),
    );
  }
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.streakPill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatInt(streak),
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.local_fire_department_rounded,
            size: 15,
            color: active ? const Color(0xFFE8893A) : colors.muted,
          ),
        ],
      ),
    );
  }
}

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.day,
    required this.onOpen,
    required this.onIncrement,
    required this.onDecrement,
    required this.onLog,
  });

  final Habit habit;
  final DateTime day;
  final VoidCallback onOpen;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(habit.colorValue);
    final value = valueOn(habit, day);
    final ratio = ratioOn(habit, day);
    final done = isComplete(habit, day);
    final streak = currentStreak(habit, DateTime.now());
    final large = habit.goal >= 100;
    final showMinus = !large && value > 0;
    final today = dateOnly(DateTime.now());
    final future = dateOnly(day).isAfter(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: HabitNameChip(name: habit.name, color: color),
                        ),
                        const SizedBox(width: 8),
                        StreakPill(streak: streak),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 148),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        progressLabel(habit, day),
                        maxLines: 1,
                        style: TextStyle(
                          color: colors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  if (showMinus) ...[
                    const SizedBox(width: 4),
                    _MiniButton(
                      tooltip: 'Remove one ${habit.unit}',
                      icon: Icons.remove_rounded,
                      onPressed: future ? null : onDecrement,
                    ),
                  ],
                  const SizedBox(width: 6),
                  RingButton(
                    progress: ratio,
                    circular: large,
                    completed: done && habit.kind == HabitKind.check,
                    accent: color,
                    icon: large ? Icons.refresh_rounded : Icons.add_rounded,
                    tooltip: future
                        ? 'This day has not started'
                        : large
                        ? 'Log ${habit.unit}'
                        : habit.kind == HabitKind.check
                        ? (done ? 'Clear this day' : 'Check this day')
                        : 'Add one ${habit.unit}',
                    onPressed: future
                        ? null
                        : large
                        ? onLog
                        : onIncrement,
                    onLongPress: future ? null : onLog,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: dark ? 0.1 : 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Heatmap(
              habit: habit,
              end: dateOnly(day).isAfter(today) ? today : day,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: colors.ink),
          ),
        ),
      ),
    );
  }
}
