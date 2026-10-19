import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/page_header.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.onMenu,
    required this.onOpenDay,
  });

  final VoidCallback onMenu;
  final ValueChanged<DateTime> onOpenDay;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  bool _sessionApplied = false;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _month = DateTime(today.year, today.month);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionApplied) return;
    _sessionApplied = true;
    final saved = AppScope.of(context).calendarMonth;
    _month = DateTime(saved.year, saved.month);
  }

  void _shiftMonth(int delta) {
    final month = DateTime(_month.year, _month.month + delta);
    setState(() => _month = month);
    AppScope.of(context).rememberCalendarMonth(month);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final habits = state.habits;
    final today = dateOnly(DateTime.now());
    final first = DateTime(_month.year, _month.month, 1);
    final lead = sundayIndex(first);
    final count = daysInMonth(_month.year, _month.month);
    final cells = lead + count;

    return Column(
      children: [
        PageHeader(
          title: 'Calendar',
          night: state.night,
          onMenu: widget.onMenu,
          onToggleTheme: state.toggleNight,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
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
                    fontSize: 16,
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
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
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            primary: false,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  if (index < lead) return const SizedBox.shrink();
                  final day = DateTime(
                    _month.year,
                    _month.month,
                    index - lead + 1,
                  );
                  return _DayCell(
                    day: day,
                    today: isSameDay(day, today),
                    future: day.isAfter(today),
                    habits: habits,
                    onTap: () => widget.onOpenDay(day),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (habits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Add a habit to fill the calendar. Each dot is one habit you finished that day.',
                    style: TextStyle(
                      color: colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final habit in habits)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(habit.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              habit.name,
                              style: TextStyle(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.future,
    required this.habits,
    required this.onTap,
  });

  final DateTime day;
  final bool today;
  final bool future;
  final List<Habit> habits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final done = habits.where((habit) => isComplete(habit, day)).toList();
    final allDone =
        habits.isNotEmpty && done.length == habits.length && !future;
    return Material(
      color: allDone ? colors.chip : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: today
                ? Border.all(color: colors.weekday, width: 1.6)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: future ? colors.muted : colors.ink,
                    fontWeight: today ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    for (final habit in done.take(4))
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Color(habit.colorValue),
                          shape: BoxShape.circle,
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
