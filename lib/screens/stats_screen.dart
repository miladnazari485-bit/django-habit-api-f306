import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/habit_card.dart';
import '../widgets/page_header.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.onMenu,
    required this.onOpenHabit,
  });

  final VoidCallback onMenu;
  final ValueChanged<String> onOpenHabit;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final today = dateOnly(DateTime.now());
    final habits = state.habits;
    final month = DateTime(today.year, today.month);
    final average = habits.isEmpty
        ? 0.0
        : habits
                  .map((habit) => monthRate(habit, month, today))
                  .reduce((a, b) => a + b) /
              habits.length;
    final percent = (average * 100).round();

    return Column(
      children: [
        PageHeader(
          title: 'Insights',
          night: state.night,
          onMenu: onMenu,
          onToggleTheme: state.toggleNight,
        ),
        Expanded(
          child: ListView(
            primary: false,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _SummaryCard(
                colors: colors,
                percent: percent,
                habitCount: habits.length,
                monthLabel: monthLong[today.month - 1],
              ),
              const SizedBox(height: 16),
              _WeekCard(colors: colors, habits: habits, today: today),
              const SizedBox(height: 18),
              Text(
                'Each habit',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              if (habits.isEmpty)
                Text(
                  'Add a habit to see streaks and how this month is going.',
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                for (final habit in _sorted(habits, today)) ...[
                  _HabitStat(
                    habit: habit,
                    today: today,
                    month: month,
                    onTap: () => onOpenHabit(habit.id),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ],
    );
  }

  List<Habit> _sorted(List<Habit> habits, DateTime today) {
    final copy = List<Habit>.of(habits);
    copy.sort((a, b) {
      final streak = currentStreak(b, today).compareTo(currentStreak(a, today));
      if (streak != 0) return streak;
      return a.name.compareTo(b.name);
    });
    return copy;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.colors,
    required this.percent,
    required this.habitCount,
    required this.monthLabel,
  });

  final AppColors colors;
  final int percent;
  final int habitCount;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent%',
            style: TextStyle(
              color: colors.ink,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            habitCount == 0
                ? 'No habits to measure yet.'
                : 'of habit goals met this month, across $habitCount ${habitCount == 1 ? 'habit' : 'habits'}.',
            style: TextStyle(color: colors.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.colors,
    required this.habits,
    required this.today,
  });

  final AppColors colors;
  final List<Habit> habits;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List<DateTime>.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 12),
            child: Text(
              'Last 7 days',
              style: TextStyle(color: colors.ink, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days) Expanded(child: _bar(colors, day)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(AppColors colors, DateTime day) {
    final rate = dayRate(habits, day);
    final isToday = isSameDay(day, today);
    final height = 8.0 + 64.0 * rate;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          habits.isEmpty || rate == 0 ? '' : '${(rate * 100).round()}',
          style: TextStyle(
            color: colors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: height,
          width: 16,
          decoration: BoxDecoration(
            color: isToday
                ? colors.ink
                : colors.weekday.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weekdayShort[sundayIndex(day)][0],
          style: TextStyle(
            color: isToday ? colors.ink : colors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _HabitStat extends StatelessWidget {
  const _HabitStat({
    required this.habit,
    required this.today,
    required this.month,
    required this.onTap,
  });

  final Habit habit;
  final DateTime today;
  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = Color(habit.colorValue);
    final streak = currentStreak(habit, today);
    final best = bestStreak(habit, today);
    final rate = monthRate(habit, month, today);
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                  const Spacer(),
                  Text(
                    '${(rate * 100).round()}%',
                    style: TextStyle(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                streak == 0
                    ? 'No current streak. Best is $best ${best == 1 ? 'day' : 'days'}.'
                    : '$streak day streak. Best is $best.',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
