import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/seed_data.dart';
import 'package:habit_tracker/logic/dates.dart';
import 'package:habit_tracker/logic/habit_math.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/task_item.dart';

void main() {
  test('date keys round-trip and reject invalid days', () {
    final day = DateTime(2026, 10, 4);
    expect(dateKey(day), '2026-10-04');
    expect(tryParseDateKey('2026-10-04'), DateTime(2026, 10, 4));
    expect(tryParseDateKey('2026-02-31'), isNull);
    expect(isSameDay(DateTime(2026, 10, 4, 23), day), isTrue);
    expect(sundayIndex(DateTime(2026, 10, 4)), 0);
  });

  test('streak counts through today and keeps yesterday if today is open', () {
    final habit = Habit(
      id: 'a',
      name: 'Read',
      colorValue: 0xFF000000,
      kind: HabitKind.check,
      goal: 1,
      unit: 'time',
      createdAt: DateTime(2026, 10, 1),
      log: const {'2026-10-01': 1, '2026-10-02': 1, '2026-10-03': 1},
    );
    expect(currentStreak(habit, DateTime(2026, 10, 3)), 3);
    expect(currentStreak(habit, DateTime(2026, 10, 4)), 3);
    expect(bestStreak(habit, DateTime(2026, 10, 4)), 3);

    final broken = habit.copyWith(
      log: const {'2026-10-01': 1, '2026-10-03': 1},
    );
    expect(currentStreak(broken, DateTime(2026, 10, 3)), 1);
    expect(bestStreak(broken, DateTime(2026, 10, 4)), 1);
  });

  test('progress label and month rate ignore future days', () {
    final habit = Habit(
      id: 'b',
      name: 'Water',
      colorValue: 0xFFCBC6F6,
      kind: HabitKind.count,
      goal: 6,
      unit: 'liters',
      createdAt: DateTime(2026, 10, 1),
      log: const {'2026-10-01': 6, '2026-10-02': 3},
    );
    expect(progressLabel(habit, DateTime(2026, 10, 2)), '3 / 6 liters');
    expect(ratioOn(habit, DateTime(2026, 10, 2)), closeTo(0.5, 0.001));
    final rate = monthRate(habit, DateTime(2026, 10, 1), DateTime(2026, 10, 2));
    expect(rate, closeTo(0.5, 0.001));
    expect(formatInt(1698), '1,698');
    expect(formatInt(10000), '10,000');
  });

  test('seed matches the opening board and does not fake a streak', () {
    final today = DateTime(2026, 10, 4);
    final seed = buildSeed(today);
    expect(seed.habits.map((habit) => habit.name), [
      'Wake Up Early',
      'Drink Water',
      'Training',
    ]);
    final training = seed.habits[2];
    expect(training.log[dateKey(today)], 1698);
    expect(training.goal, 10000);
    expect(currentStreak(training, today), 0);
    expect(
      valueOn(training, today.subtract(const Duration(days: 1))),
      lessThan(10000),
    );
    expect(isComplete(seed.habits[0], today), isFalse);
    expect(seed.tasks.single.title, 'Buy groceries');
    expect(seed.tasks.single.isOverdueOn(today), isTrue);
    expect(seed.tasks.single.dueDate, DateTime(2026, 9, 19));

    final parsed = Habit.tryParse(training.toJson());
    expect(parsed, isNotNull);
    expect(parsed!.log[dateKey(today)], 1698);
    final task = TaskItem.tryParse(seed.tasks.single.toJson());
    expect(task?.title, 'Buy groceries');
    expect(task?.done, isFalse);
  });
}
