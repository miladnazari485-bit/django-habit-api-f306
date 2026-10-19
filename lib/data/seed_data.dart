import '../logic/dates.dart';
import '../models/habit.dart';
import '../models/task_item.dart';

class SeedData {
  const SeedData({required this.habits, required this.tasks});

  final List<Habit> habits;
  final List<TaskItem> tasks;
}

int _mix(int seed) {
  var value = seed & 0x7fffffff;
  value = (value * 1103515245 + 12345) & 0x7fffffff;
  return value;
}

/// Sample board that matches the reference layout on first launch:
/// one overdue task, two quiet habits, and a step habit with history.
SeedData buildSeed(DateTime now) {
  final today = dateOnly(now);
  final wakeLog = <String, int>{};
  final waterLog = <String, int>{};
  final trainingLog = <String, int>{};

  for (var daysAgo = 180; daysAgo >= 1; daysAgo--) {
    final day = today.subtract(Duration(days: daysAgo));
    final noise = _mix(
      day.year * 1000 + day.month * 40 + day.day * 7 + daysAgo,
    );
    final roll = noise % 100;

    if (daysAgo > 2 && roll < 12) {
      wakeLog[dateKey(day)] = 1;
    }
    if (daysAgo > 2 && roll > 78) {
      waterLog[dateKey(day)] = 1 + (noise % 3);
    }

    int steps;
    if (daysAgo <= 14) {
      steps = 4200 + (noise % 5200);
    } else if (roll < 16) {
      steps = 10000 + (noise % 2500);
    } else if (roll < 72) {
      steps = 1800 + (noise % 6400);
    } else {
      steps = noise % 700;
    }
    if (steps > 0) trainingLog[dateKey(day)] = steps;
  }
  trainingLog[dateKey(today)] = 1698;

  final created = today.subtract(const Duration(days: 180));
  final habits = [
    Habit(
      id: 'wake',
      name: 'Wake Up Early',
      colorValue: 0xFFF6D452,
      kind: HabitKind.check,
      goal: 1,
      unit: 'time',
      createdAt: created,
      log: wakeLog,
    ),
    Habit(
      id: 'water',
      name: 'Drink Water',
      colorValue: 0xFFCBC6F6,
      kind: HabitKind.count,
      goal: 6,
      unit: 'liters',
      createdAt: created,
      log: waterLog,
    ),
    Habit(
      id: 'training',
      name: 'Training',
      colorValue: 0xFFEF3B70,
      kind: HabitKind.count,
      goal: 10000,
      unit: 'steps',
      createdAt: created,
      log: trainingLog,
    ),
  ];

  var groceriesDue = DateTime(today.year, 9, 19);
  if (!groceriesDue.isBefore(today)) {
    groceriesDue = DateTime(today.year - 1, 9, 19);
  }

  return SeedData(
    habits: habits,
    tasks: [
      TaskItem(id: 'groceries', title: 'Buy groceries', dueDate: groceriesDue),
    ],
  );
}
