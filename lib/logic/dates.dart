// Calendar helpers that stay independent of Flutter so they can be tested
// as plain Dart.

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String dateKey(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final dayText = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayText';
}

String monthKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  return '${value.year}-$month';
}

DateTime? tryParseMonthKey(String key) {
  final parts = key.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null || month < 1 || month > 12) return null;
  return DateTime(year, month);
}

DateTime? tryParseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }
  return parsed;
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Sunday is 0, matching the week strip in the app.
int sundayIndex(DateTime day) => day.weekday % 7;

const weekdayShort = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const weekdayLong = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const monthLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String shortMonthDay(DateTime day) => '${monthShort[day.month - 1]} ${day.day}';

String monthYearLabel(DateTime day) =>
    '${monthLong[day.month - 1]} ${day.year}';

String longDateLabel(DateTime day) {
  return '${weekdayLong[sundayIndex(day)]}, ${monthLong[day.month - 1]} ${day.day}';
}

String formatInt(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return negative ? '-$buffer' : buffer.toString();
}

bool isWeekend(DateTime day) {
  return day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
}
