import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/habit_card.dart';
import '../widgets/sheets.dart';

class HabitDetailScreen extends StatefulWidget {
  const HabitDetailScreen({
    super.key,
    required this.habitId,
    required this.onBack,
  });

  final String habitId;
  final VoidCallback onBack;

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  late DateTime _month;
  bool _aligned = false;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _month = DateTime(today.year, today.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_aligned) return;
    final state = AppScope.of(context);
    final saved = state.detailMonth;
    final selected = state.selectedDate;
    final month = saved ?? selected;
    _month = DateTime(month.year, month.month);
    _aligned = true;
  }

  void _shiftMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    setState(() => _month = month);
    AppScope.of(context).rememberDetailMonth(month);
  }

  Future<void> _editDay(Habit habit, DateTime day) async {
    final today = dateOnly(DateTime.now());
    if (day.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can log a habit once that day arrives.'),
        ),
      );
      return;
    }
    final state = AppScope.of(context);
    state.selectDate(day);
    if (habit.kind == HabitKind.check) {
      state.toggleHabit(habit.id, day);
      return;
    }
    await showLogSheet(context, habit: habit, day: day);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final habit = state.habitById(widget.habitId);
    final top = MediaQuery.paddingOf(context).top;
    if (habit == null) {
      return Center(
        child: TextButton(onPressed: widget.onBack, child: const Text('Back')),
      );
    }
    final today = dateOnly(DateTime.now());
    final color = Color(habit.colorValue);
    final streak = currentStreak(habit, today);
    final best = bestStreak(habit, today);
    final rate = monthRate(habit, _month, today);
    final selected = state.selectedDate;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8, top + 6, 8, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: state.night
                    ? 'Switch to day mood'
                    : 'Switch to night mood',
                onPressed: state.toggleNight,
                icon: Icon(
                  state.night
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Edit habit',
                onPressed: () => showComposer(context, habit: habit),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            primary: false,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: HabitNameChip(name: habit.name, color: color),
                        ),
                        const SizedBox(width: 8),
                        StreakPill(streak: streak),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      progressLabel(habit, selected),
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      longDateLabel(selected),
                      style: TextStyle(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: ratioOn(habit, selected),
                        minHeight: 8,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _stat(colors, 'Streak', '$streak'),
                        _stat(colors, 'Best', '$best'),
                        _stat(colors, 'Month', '${(rate * 100).round()}%'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      monthYearLabel(_month),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              Text(
                habit.kind == HabitKind.check
                    ? 'Tap a day to check it. Each habit keeps its own days.'
                    : 'Tap a day to log it. Each habit keeps its own days.',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _monthGrid(habit, today, selected, colors),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final ok = await confirmDelete(
                    context,
                    title: 'Delete habit?',
                    message:
                        'Daily checks for ${habit.name} will be removed from this device.',
                  );
                  if (!ok || !context.mounted) return;
                  state.deleteHabit(habit.id);
                  widget.onBack();
                },
                child: Text(
                  'Delete habit',
                  style: TextStyle(color: colors.badge),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(AppColors colors, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: colors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthGrid(
    Habit habit,
    DateTime today,
    DateTime selected,
    AppColors colors,
  ) {
    final first = DateTime(_month.year, _month.month, 1);
    final lead = sundayIndex(first);
    final count = daysInMonth(_month.year, _month.month);
    final color = Color(habit.colorValue);
    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayShort)
              Expanded(
                child: Center(
                  child: Text(
                    label[0],
                    style: TextStyle(
                      color: label == 'Sun' || label == 'Sat'
                          ? colors.weekend
                          : colors.weekday,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lead + count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            if (index < lead) return const SizedBox.shrink();
            final day = DateTime(_month.year, _month.month, index - lead + 1);
            final ratio = ratioOn(habit, day);
            final future = day.isAfter(today);
            final isSelected = isSameDay(day, selected);
            return Material(
              color: ratio <= 0
                  ? colors.chip
                  : color.withValues(alpha: 0.25 + 0.75 * ratio),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _editDay(habit, day),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? Border.all(color: colors.ink, width: 1.6)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: future
                            ? colors.muted
                            : ratio > 0.65
                            ? foregroundOn(color)
                            : colors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
