import '../models/habit.dart';
import 'dates.dart';

int valueOn(Habit habit, DateTime day) => habit.log[dateKey(day)] ?? 0;

bool isComplete(Habit habit, DateTime day) {
  return habit.goal > 0 && valueOn(habit, day) >= habit.goal;
}

double ratioOn(Habit habit, DateTime day) {
  if (habit.goal <= 0) return 0;
  final ratio = valueOn(habit, day) / habit.goal;
  if (ratio < 0) return 0;
  if (ratio > 1) return 1;
  return ratio;
}

/// Streak ending on [today]. If today is still open, yesterday's run still
/// counts so a streak does not break before the day is over.
int currentStreak(Habit habit, DateTime today) {
  var cursor = dateOnly(today);
  if (!isComplete(habit, cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (isComplete(habit, cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
    if (streak > 5000) break;
  }
  return streak;
}

int bestStreak(Habit habit, DateTime today) {
  if (habit.log.isEmpty) return 0;
  DateTime? earliest;
  for (final key in habit.log.keys) {
    final day = tryParseDateKey(key);
    if (day == null) continue;
    if (earliest == null || day.isBefore(earliest)) earliest = day;
  }
  if (earliest == null) return 0;
  final end = dateOnly(today);
  var cursor = earliest;
  var run = 0;
  var best = 0;
  while (!cursor.isAfter(end)) {
    if (isComplete(habit, cursor)) {
      run += 1;
      if (run > best) best = run;
    } else {
      run = 0;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return best;
}

String progressLabel(Habit habit, DateTime day) {
  return '${formatInt(valueOn(habit, day))} / ${formatInt(habit.goal)} ${habit.unit}';
}

/// Share of days from the 1st through [today] (or month end) that met the goal.
double monthRate(Habit habit, DateTime month, DateTime today) {
  final last = daysInMonth(month.year, month.month);
  final endCap = dateOnly(today);
  var counted = 0;
  var done = 0;
  for (var dayNumber = 1; dayNumber <= last; dayNumber++) {
    final day = DateTime(month.year, month.month, dayNumber);
    if (day.isAfter(endCap)) break;
    counted += 1;
    if (isComplete(habit, day)) done += 1;
  }
  if (counted == 0) return 0;
  return done / counted;
}

double dayRate(List<Habit> habits, DateTime day) {
  if (habits.isEmpty) return 0;
  final done = habits.where((habit) => isComplete(habit, day)).length;
  return done / habits.length;
}

int incompleteCount(List<Habit> habits, DateTime day) {
  return habits.where((habit) => !isComplete(habit, day)).length;
}

List<double> heatmapRatios(Habit habit, DateTime end, int count) {
  final last = dateOnly(end);
  return List<double>.generate(count, (index) {
    final day = last.subtract(Duration(days: count - 1 - index));
    return ratioOn(habit, day);
  }, growable: false);
}
