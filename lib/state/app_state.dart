import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../logic/dates.dart';
import '../models/habit.dart';
import '../models/task_item.dart';

const storageKey = 'habit_tracker.v1';

/// In-memory board plus the on-device JSON copy.
class AppState extends ChangeNotifier {
  AppState() : _habits = [], _tasks = [];

  AppState.withData({
    List<Habit>? habits,
    List<TaskItem>? tasks,
    DateTime? selected,
    bool night = false,
    int tab = 0,
    DateTime? todayMonth,
    bool habitsOpen = true,
    DateTime? calendarMonth,
    String? detailHabitId,
    DateTime? detailMonth,
  }) : _habits = List<Habit>.of(habits ?? const []),
       _tasks = List<TaskItem>.of(tasks ?? const []),
       _selectedDate = dateOnly(selected ?? DateTime.now()),
       _ready = true {
    _night = night;
    _tab = tab < 0 || tab > 3 ? 0 : tab;
    _habitsOpen = habitsOpen;
    _detailHabitId = detailHabitId;
    final anchor = _selectedDate;
    _todayMonth = DateTime(
      (todayMonth ?? anchor).year,
      (todayMonth ?? anchor).month,
    );
    _calendarMonth = DateTime(
      (calendarMonth ?? anchor).year,
      (calendarMonth ?? anchor).month,
    );
    if (detailMonth != null) {
      _detailMonth = DateTime(detailMonth.year, detailMonth.month);
    }
  }

  final List<Habit> _habits;
  final List<TaskItem> _tasks;
  DateTime _selectedDate = dateOnly(DateTime.now());
  bool _night = false;
  int _tab = 0;
  bool _habitsOpen = true;
  DateTime _todayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String? _detailHabitId;
  DateTime? _detailMonth;
  bool _ready = false;
  bool _loading = false;
  Future<void> _queue = Future<void>.value();
  int _idSequence = 0;

  bool get ready => _ready;
  bool get night => _night;
  ThemeMode get themeMode => _night ? ThemeMode.dark : ThemeMode.light;
  DateTime get selectedDate => _selectedDate;
  int get tab => _tab;
  bool get habitsOpen => _habitsOpen;
  DateTime get todayMonth => _todayMonth;
  DateTime get calendarMonth => _calendarMonth;
  String? get detailHabitId => _detailHabitId;
  DateTime? get detailMonth => _detailMonth;
  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  List<TaskItem> get tasks => List<TaskItem>.unmodifiable(_tasks);

  /// Completes after the latest scheduled write finishes.
  Future<void> get settled => _queue;

  List<TaskItem> overdueTasks([DateTime? today]) {
    final day = dateOnly(today ?? DateTime.now());
    final items = _tasks.where((task) => task.isOverdueOn(day)).toList();
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  Habit? habitById(String id) {
    for (final habit in _habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Future<void> load() async {
    if (_ready || _loading) return;
    _loading = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    final decoded = raw == null ? null : _decode(raw);
    if (decoded == null) {
      final seed = buildSeed(DateTime.now());
      _habits
        ..clear()
        ..addAll(seed.habits);
      _tasks
        ..clear()
        ..addAll(seed.tasks);
    } else {
      _night = decoded.night;
      _habits
        ..clear()
        ..addAll(decoded.habits);
      _tasks
        ..clear()
        ..addAll(decoded.tasks);
      _applySession(decoded.session);
    }
    if (_detailHabitId != null && habitById(_detailHabitId!) == null) {
      _detailHabitId = null;
    }
    _ready = true;
    _loading = false;
    notifyListeners();
    if (decoded == null) _scheduleSave();
  }

  void selectDate(DateTime day) {
    final next = dateOnly(day);
    if (isSameDay(next, _selectedDate)) return;
    _selectedDate = next;
    notifyListeners();
    _scheduleSave();
  }

  void rememberTab(int index) {
    if (index < 0 || index > 3 || _tab == index) return;
    _tab = index;
    _scheduleSave();
  }

  void rememberHabitsOpen(bool value) {
    if (_habitsOpen == value) return;
    _habitsOpen = value;
    _scheduleSave();
  }

  void rememberTodayMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (isSameMonth(_todayMonth, next)) return;
    _todayMonth = next;
    _scheduleSave();
  }

  void rememberCalendarMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (isSameMonth(_calendarMonth, next)) return;
    _calendarMonth = next;
    _scheduleSave();
  }

  /// Remembers which habit page is open. Pass null when the user leaves it.
  void rememberDetail(String? id) {
    if (_detailHabitId == id) return;
    _detailHabitId = id;
    _scheduleSave();
  }

  void rememberDetailMonth(DateTime month) {
    final next = DateTime(month.year, month.month);
    if (_detailMonth != null && isSameMonth(_detailMonth!, next)) return;
    _detailMonth = next;
    _scheduleSave();
  }

  void setNight(bool value) {
    if (_night == value) return;
    _night = value;
    notifyListeners();
    _scheduleSave();
  }

  void toggleNight() => setNight(!_night);

  bool setHabitValue(String id, DateTime day, int value) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(day);
    if (target.isAfter(today)) return false;
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index < 0) return false;
    final habit = _habits[index];
    final log = Map<String, int>.from(habit.log);
    if (value <= 0) {
      log.remove(dateKey(target));
    } else {
      log[dateKey(target)] = value;
    }
    _habits[index] = habit.copyWith(log: log);
    notifyListeners();
    _scheduleSave();
    return true;
  }

  bool addHabitValue(String id, DateTime day, int delta) {
    final habit = habitById(id);
    if (habit == null) return false;
    final next = valueOnSafe(habit, day) + delta;
    return setHabitValue(id, day, next);
  }

  bool toggleHabit(String id, DateTime day) {
    final habit = habitById(id);
    if (habit == null) return false;
    final done = valueOnSafe(habit, day) >= habit.goal;
    return setHabitValue(id, day, done ? 0 : habit.goal);
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
    _scheduleSave();
  }

  void updateHabit(Habit habit) {
    final index = _habits.indexWhere((item) => item.id == habit.id);
    if (index < 0) return;
    _habits[index] = habit.copyWith(log: _habits[index].log);
    notifyListeners();
    _scheduleSave();
  }

  void deleteHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);
    if (_detailHabitId == id) _detailHabitId = null;
    notifyListeners();
    _scheduleSave();
  }

  void addTask(TaskItem task) {
    _tasks.add(task);
    notifyListeners();
    _scheduleSave();
  }

  void updateTask(TaskItem task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    notifyListeners();
    _scheduleSave();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    final task = _tasks[index];
    _tasks[index] = task.copyWith(done: !task.done);
    notifyListeners();
    _scheduleSave();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    notifyListeners();
    _scheduleSave();
  }

  void postponeOverdueTo(DateTime day) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(day);
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (!task.isOverdueOn(today)) continue;
      _tasks[i] = task.copyWith(dueDate: target);
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _scheduleSave();
  }

  void postponeTask(String id, DateTime day) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(dueDate: dateOnly(day));
    notifyListeners();
    _scheduleSave();
  }

  String createId() {
    _idSequence += 1;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}$_idSequence';
  }

  void _scheduleSave() {
    if (!_ready) return;
    _queue = _queue.then((_) => _write());
  }

  Future<void> _write() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(_snapshot()));
  }

  Map<String, dynamic> _snapshot() {
    return {
      'night': _night,
      'habits': _habits.map((habit) => habit.toJson()).toList(),
      'tasks': _tasks.map((task) => task.toJson()).toList(),
      'session': {
        'tab': _tab,
        'selectedDate': dateKey(_selectedDate),
        'todayMonth': monthKey(_todayMonth),
        'habitsOpen': _habitsOpen,
        'calendarMonth': monthKey(_calendarMonth),
        'detailHabitId': _detailHabitId,
        'detailMonth': _detailMonth == null ? null : monthKey(_detailMonth!),
      },
    };
  }

  void _applySession(Map<String, dynamic>? session) {
    if (session == null) return;
    final tab = session['tab'];
    if (tab is int && tab >= 0 && tab <= 3) _tab = tab;
    final selected = session['selectedDate'];
    if (selected is String) {
      final parsed = tryParseDateKey(selected);
      if (parsed != null) _selectedDate = parsed;
    }
    final todayMonth = session['todayMonth'];
    if (todayMonth is String) {
      final parsed = tryParseMonthKey(todayMonth);
      if (parsed != null) _todayMonth = parsed;
    }
    final habitsOpen = session['habitsOpen'];
    if (habitsOpen is bool) _habitsOpen = habitsOpen;
    final calendarMonth = session['calendarMonth'];
    if (calendarMonth is String) {
      final parsed = tryParseMonthKey(calendarMonth);
      if (parsed != null) _calendarMonth = parsed;
    }
    final detail = session['detailHabitId'];
    _detailHabitId = detail is String && detail.isNotEmpty ? detail : null;
    final detailMonth = session['detailMonth'];
    if (detailMonth is String) {
      _detailMonth = tryParseMonthKey(detailMonth);
    }
  }

  static _Decoded? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final habits = <Habit>[];
      final habitRaw = value['habits'];
      if (habitRaw is List) {
        for (final item in habitRaw) {
          final habit = Habit.tryParse(item);
          if (habit != null) habits.add(habit);
        }
      }
      final tasks = <TaskItem>[];
      final taskRaw = value['tasks'];
      if (taskRaw is List) {
        for (final item in taskRaw) {
          final task = TaskItem.tryParse(item);
          if (task != null) tasks.add(task);
        }
      }
      final sessionRaw = value['session'];
      return _Decoded(
        night: value['night'] == true,
        habits: habits,
        tasks: tasks,
        session: sessionRaw is Map
            ? Map<String, dynamic>.from(sessionRaw)
            : null,
      );
    } on FormatException {
      return null;
    }
  }
}

int valueOnSafe(Habit habit, DateTime day) => habit.log[dateKey(day)] ?? 0;

class _Decoded {
  const _Decoded({
    required this.night,
    required this.habits,
    required this.tasks,
    required this.session,
  });

  final bool night;
  final List<Habit> habits;
  final List<TaskItem> tasks;
  final Map<String, dynamic>? session;
}
