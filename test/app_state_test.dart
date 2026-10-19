import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/logic/dates.dart';
import 'package:habit_tracker/logic/habit_math.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/task_item.dart';
import 'package:habit_tracker/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'logs are separate per habit and per day, and future days are blocked',
    () async {
      final today = DateTime(2026, 10, 4);
      final state = AppState.withData(
        selected: today,
        habits: [
          Habit(
            id: 'wake',
            name: 'Wake Up Early',
            colorValue: 0xFFF6D452,
            kind: HabitKind.check,
            goal: 1,
            unit: 'time',
            createdAt: today,
          ),
          Habit(
            id: 'water',
            name: 'Drink Water',
            colorValue: 0xFFCBC6F6,
            kind: HabitKind.count,
            goal: 6,
            unit: 'liters',
            createdAt: today,
          ),
        ],
        tasks: [
          TaskItem(
            id: 'groceries',
            title: 'Buy groceries',
            dueDate: DateTime(2026, 9, 19),
          ),
        ],
      );

      expect(
        state.setHabitValue(
          'wake',
          dateOnly(DateTime.now()).add(const Duration(days: 1)),
          1,
        ),
        isFalse,
      );
      expect(state.toggleHabit('wake', today), isTrue);
      expect(isComplete(state.habitById('wake')!, today), isTrue);
      expect(isComplete(state.habitById('water')!, today), isFalse);

      state.addHabitValue('water', today, 2);
      state.addHabitValue('water', today.subtract(const Duration(days: 1)), 6);
      expect(valueOn(state.habitById('water')!, today), 2);
      expect(
        isComplete(
          state.habitById('water')!,
          today.subtract(const Duration(days: 1)),
        ),
        isTrue,
      );

      expect(state.overdueTasks(today), hasLength(1));
      state.postponeOverdueTo(today);
      expect(state.overdueTasks(today), isEmpty);
      expect(isSameDay(state.tasks.single.dueDate, today), isTrue);

      state.toggleTask('groceries');
      expect(state.tasks.single.done, isTrue);
    },
  );

  test('day and night mood and logs survive a reload', () async {
    final first = AppState();
    await first.load();
    expect(first.habits, hasLength(3));
    expect(first.night, isFalse);
    first.setNight(true);
    final today = dateOnly(DateTime.now());
    first.setHabitValue('wake', today, 1);
    await first.settled;

    final second = AppState();
    await second.load();
    expect(second.night, isTrue);
    expect(isComplete(second.habitById('wake')!, today), isTrue);
    expect(second.habitById('training')!.log[dateKey(today)], 1698);
    expect(isSameDay(second.selectedDate, today), isTrue);
    expect(second.tab, 0);
  });

  test('each page session is restored with the saved board', () async {
    final first = AppState();
    await first.load();
    final wake = first.habitById('wake')!;
    first.selectDate(DateTime(2026, 3, 12));
    first.rememberTab(2);
    first.rememberTodayMonth(DateTime(2026, 3, 1));
    first.rememberHabitsOpen(false);
    first.rememberCalendarMonth(DateTime(2026, 2, 1));
    first.rememberDetail(wake.id);
    first.rememberDetailMonth(DateTime(2026, 1, 1));
    first.setHabitValue(wake.id, DateTime(2026, 3, 12), 1);
    await first.settled;

    final second = AppState();
    await second.load();
    expect(second.tab, 2);
    expect(isSameDay(second.selectedDate, DateTime(2026, 3, 12)), isTrue);
    expect(isSameMonth(second.todayMonth, DateTime(2026, 3, 1)), isTrue);
    expect(second.habitsOpen, isFalse);
    expect(isSameMonth(second.calendarMonth, DateTime(2026, 2, 1)), isTrue);
    expect(second.detailHabitId, wake.id);
    expect(isSameMonth(second.detailMonth!, DateTime(2026, 1, 1)), isTrue);
    expect(isComplete(second.habitById(wake.id)!, DateTime(2026, 3, 12)), isTrue);
  });

  test('an older save without a session still opens on today', () async {
    SharedPreferences.setMockInitialValues({
      storageKey: jsonEncode({
        'night': true,
        'habits': <Object>[],
        'tasks': <Object>[],
      }),
    });
    final state = AppState();
    await state.load();
    expect(state.night, isTrue);
    expect(state.habits, isEmpty);
    expect(isSameDay(state.selectedDate, dateOnly(DateTime.now())), isTrue);
    expect(state.tab, 0);
    expect(state.habitsOpen, isTrue);
    expect(state.detailHabitId, isNull);
    expect(isSameMonth(state.todayMonth, DateTime.now()), isTrue);
    expect(isSameMonth(state.calendarMonth, DateTime.now()), isTrue);
  });

  test('a saved habit page is dropped when that habit is gone', () async {
    SharedPreferences.setMockInitialValues({
      storageKey: jsonEncode({
        'night': false,
        'habits': <Object>[],
        'tasks': <Object>[],
        'session': {
          'tab': 1,
          'detailHabitId': 'missing',
          'detailMonth': '2026-04',
        },
      }),
    });
    final state = AppState();
    await state.load();
    expect(state.tab, 1);
    expect(state.detailHabitId, isNull);
    expect(isSameMonth(state.detailMonth!, DateTime(2026, 4)), isTrue);
  });
}
