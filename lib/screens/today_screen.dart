import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dates.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/habit_card.dart';
import '../widgets/month_date_strip.dart';
import '../widgets/page_header.dart';
import '../widgets/sheets.dart';
import '../widgets/task_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.onMenu,
    required this.onOpenStats,
    required this.onOpenHabit,
  });

  final VoidCallback onMenu;
  final VoidCallback onOpenStats;
  final ValueChanged<String> onOpenHabit;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late DateTime _visibleMonth;
  DateTime _trackedSelected = dateOnly(DateTime.now());
  AppState? _state;
  int _pinToken = 1;
  bool _habitsOpen = true;
  bool _sessionApplied = false;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _trackedSelected = today;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AppScope.of(context);
    if (!identical(_state, next)) {
      _state?.removeListener(_onState);
      _state = next;
      _state!.addListener(_onState);
    }
    if (!_sessionApplied) {
      _sessionApplied = true;
      _visibleMonth = DateTime(next.todayMonth.year, next.todayMonth.month);
      _trackedSelected = next.selectedDate;
      _habitsOpen = next.habitsOpen;
    }
  }

  @override
  void dispose() {
    _state?.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (!mounted || _state == null) return;
    final selected = _state!.selectedDate;
    if (isSameDay(_trackedSelected, selected)) return;
    _trackedSelected = selected;
    if (!isSameMonth(selected, _visibleMonth)) {
      final month = DateTime(selected.year, selected.month);
      setState(() => _visibleMonth = month);
      _state!.rememberTodayMonth(month);
    }
  }

  void _shiftMonth(int delta) {
    final month = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    setState(() => _visibleMonth = month);
    AppScope.of(context).rememberTodayMonth(month);
  }

  void _jumpToday() {
    final today = dateOnly(DateTime.now());
    final month = DateTime(today.year, today.month);
    final state = AppScope.of(context);
    state.selectDate(today);
    state.rememberTodayMonth(month);
    setState(() {
      _visibleMonth = month;
      _pinToken += 1;
    });
  }

  void _blocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can log a habit once that day arrives.'),
      ),
    );
  }

  Future<void> _postpone(BuildContext anchor) async {
    final state = AppScope.of(context);
    final box = anchor.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(anchor).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      origin & box.size,
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<String>(
      context: anchor,
      position: position,
      items: const [
        PopupMenuItem(value: 'today', child: Text('Today')),
        PopupMenuItem(value: 'tomorrow', child: Text('Tomorrow')),
        PopupMenuItem(value: 'week', child: Text('Next week')),
        PopupMenuItem(value: 'pick', child: Text('Pick a date')),
      ],
    );
    if (!mounted || choice == null) return;
    final today = dateOnly(DateTime.now());
    DateTime? target;
    if (choice == 'today') target = today;
    if (choice == 'tomorrow') target = today.add(const Duration(days: 1));
    if (choice == 'week') target = today.add(const Duration(days: 7));
    if (choice == 'pick') {
      final picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (picked == null || !mounted) return;
      target = dateOnly(picked);
    }
    if (target == null) return;
    state.postponeOverdueTo(target);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Postponed to ${shortMonthDay(target)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final selected = state.selectedDate;
    final today = dateOnly(DateTime.now());
    final viewingToday = isSameDay(selected, today);
    final overdue = state.overdueTasks(today);
    final showTodayJump = !viewingToday || !isSameMonth(_visibleMonth, today);

    return Column(
      children: [
        PageHeader(
          title: 'Today',
          night: state.night,
          badge: overdue.length,
          onMenu: widget.onMenu,
          onToggleTheme: state.toggleNight,
          onChart: widget.onOpenStats,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  monthYearLabel(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (showTodayJump)
                TextButton(onPressed: _jumpToday, child: const Text('Today')),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        MonthDateStrip(
          visibleMonth: _visibleMonth,
          selected: selected,
          pinToken: _pinToken,
          onSelect: (day) {
            HapticFeedback.selectionClick();
            state.selectDate(day);
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            primary: false,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (!viewingToday) _viewingBanner(colors, selected, today),
              if (viewingToday && overdue.isNotEmpty)
                _overdueBlock(context, colors, overdue),
              _habitsHeader(colors, state.habits.length),
              if (_habitsOpen && state.habits.isEmpty)
                _emptyHabits(colors)
              else if (_habitsOpen)
                for (final habit in state.habits) ...[
                  HabitCard(
                    habit: habit,
                    day: selected,
                    onOpen: () => widget.onOpenHabit(habit.id),
                    onIncrement: () => _increment(state, habit, selected),
                    onDecrement: () {
                      final ok = state.addHabitValue(habit.id, selected, -1);
                      if (!ok) _blocked();
                    },
                    onLog: () => _openLog(habit, selected),
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ],
    );
  }

  void _increment(AppState state, Habit habit, DateTime selected) {
    final ok = habit.kind == HabitKind.check
        ? state.toggleHabit(habit.id, selected)
        : state.addHabitValue(habit.id, selected, 1);
    if (!ok) _blocked();
  }

  Future<void> _openLog(Habit habit, DateTime selected) async {
    if (dateOnly(selected).isAfter(dateOnly(DateTime.now()))) {
      _blocked();
      return;
    }
    await showLogSheet(context, habit: habit, day: selected);
  }

  Widget _viewingBanner(AppColors colors, DateTime selected, DateTime today) {
    final future = selected.isAfter(today);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colors.band,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  future
                      ? '${longDateLabel(selected)} has not started.'
                      : 'Showing ${longDateLabel(selected)}.',
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: _jumpToday, child: const Text('Today')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overdueBlock(
    BuildContext context,
    AppColors colors,
    List<dynamic> overdue,
  ) {
    final state = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.band,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'About overdue',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Overdue'),
                          content: const Text(
                            'These tasks are still open after their due date. Postpone them, or check one off when it is done.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: colors.ink,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Overdue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (anchor) {
                      return Material(
                        color: colors.postpone,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _postpone(anchor),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Postpone (${overdue.length})',
                                  style: TextStyle(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Icon(
                                  Icons.expand_more_rounded,
                                  color: colors.ink,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final task in state.overdueTasks()) ...[
                TaskCard(
                  task: task,
                  onToggle: () => state.toggleTask(task.id),
                  onTap: () => showComposer(context, task: task),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _habitsHeader(AppColors colors, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.list_alt_rounded, size: 18, color: colors.ink),
          const SizedBox(width: 8),
          Text(
            'Daily Habits',
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Material(
            color: colors.chip,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final open = !_habitsOpen;
                setState(() => _habitsOpen = open);
                AppScope.of(context).rememberHabitsOpen(open);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        color: colors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      _habitsOpen
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: colors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHabits(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.spa_outlined, size: 36, color: colors.muted),
          const SizedBox(height: 10),
          Text(
            'No habits yet',
            style: TextStyle(
              color: colors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one, then check it off on each day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
