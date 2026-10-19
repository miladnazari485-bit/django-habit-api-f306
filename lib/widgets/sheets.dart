import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dates.dart';
import '../logic/habit_math.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';

enum ComposerKind { chooser, habit, task }

Future<void> showComposer(
  BuildContext context, {
  ComposerKind kind = ComposerKind.chooser,
  Habit? habit,
  TaskItem? task,
}) {
  final colors = AppColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _Composer(kind: kind, habit: habit, task: task),
      );
    },
  );
}

Future<void> showLogSheet(
  BuildContext context, {
  required Habit habit,
  required DateTime day,
}) {
  final colors = AppColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _LogSheet(habitId: habit.id, day: dateOnly(day)),
      );
    },
  );
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final colors = AppColors.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.badge),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

class _Composer extends StatefulWidget {
  const _Composer({required this.kind, this.habit, this.task});

  final ComposerKind kind;
  final Habit? habit;
  final TaskItem? task;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late ComposerKind _kind;
  late final TextEditingController _name;
  late final TextEditingController _goal;
  late final TextEditingController _unit;
  late int _color;
  late HabitKind _habitKind;
  late DateTime _due;
  String? _error;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    final task = widget.task;
    if (habit != null) {
      _kind = ComposerKind.habit;
    } else if (task != null) {
      _kind = ComposerKind.task;
    } else {
      _kind = widget.kind;
    }
    _name = TextEditingController(text: habit?.name ?? task?.title ?? '');
    _goal = TextEditingController(text: '${habit?.goal ?? 1}');
    _unit = TextEditingController(text: habit?.unit ?? 'time');
    _habitKind = habit?.kind ?? HabitKind.check;
    _due = task?.dueDate ?? dateOnly(DateTime.now());
    _color = habit?.colorValue ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.habit == null && _color == 0) {
      final state = AppScope.of(context);
      _color = nextHabitColor(state.habits.map((habit) => habit.colorValue));
      final selected = state.selectedDate;
      final today = dateOnly(DateTime.now());
      _due = selected.isBefore(today) ? today : selected;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final editing = widget.habit != null || widget.task != null;
    final title = _kind == ComposerKind.task
        ? (editing ? 'Edit task' : 'New task')
        : _kind == ComposerKind.habit
        ? (editing ? 'Edit habit' : 'New habit')
        : 'Add something';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _kind == ComposerKind.task
                  ? 'A task is checked once, on its due date.'
                  : _kind == ComposerKind.habit
                  ? 'A habit is checked on its own, every day you open it.'
                  : 'Habits repeat. Tasks are one-off.',
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!editing && _kind == ComposerKind.chooser) ...[
              const SizedBox(height: 16),
              _choice(
                context,
                icon: Icons.restart_alt_rounded,
                title: 'Habit',
                subtitle: 'Wake up, water, steps — logged per day',
                onTap: () => setState(() => _kind = ComposerKind.habit),
              ),
              const SizedBox(height: 8),
              _choice(
                context,
                icon: Icons.checklist_rounded,
                title: 'Task',
                subtitle: 'Something you finish once',
                onTap: () => setState(() => _kind = ComposerKind.task),
              ),
            ],
            if (_kind == ComposerKind.habit) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Habit name'),
              ),
              const SizedBox(height: 14),
              _colorRow(colors),
              const SizedBox(height: 14),
              _kindToggle(colors),
              if (_habitKind == HabitKind.count) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _goal,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Daily goal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _stepper(colors),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    hintText: 'Unit, like liters',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final unit in habitUnits) _unitChip(colors, unit),
                  ],
                ),
              ],
            ],
            if (_kind == ComposerKind.task) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Task name'),
              ),
              const SizedBox(height: 12),
              Material(
                color: colors.chip,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: const Text(
                    'Due date',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(longDateLabel(_due)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: _pickDue,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: colors.badge,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_kind != ComposerKind.chooser) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: Text(editing ? 'Save' : 'Add'),
              ),
              if (editing) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: _delete, child: const Text('Delete')),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _choice(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.chip,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: colors.ink),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  Widget _colorRow(AppColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in habitColorValues)
          GestureDetector(
            onTap: () => setState(() => _color = value),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _color == value ? colors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _kindToggle(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(
            colors,
            label: 'Once a day',
            selected: _habitKind == HabitKind.check,
            onTap: () => setState(() {
              _habitKind = HabitKind.check;
              _goal.text = '1';
              _unit.text = 'time';
            }),
          ),
          _segment(
            colors,
            label: 'Count',
            selected: _habitKind == HabitKind.count,
            onTap: () => setState(() => _habitKind = HabitKind.count),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    AppColors colors, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? colors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: colors.ink),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepper(AppColors colors) {
    return Row(
      children: [
        _mini(colors, Icons.remove_rounded, () => _bumpGoal(-1)),
        const SizedBox(width: 6),
        _mini(colors, Icons.add_rounded, () => _bumpGoal(1)),
      ],
    );
  }

  Widget _mini(AppColors colors, IconData icon, VoidCallback onTap) {
    return Material(
      color: colors.chip,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 48,
          child: Icon(icon, color: colors.ink),
        ),
      ),
    );
  }

  Widget _unitChip(AppColors colors, String unit) {
    final selected = _unit.text == unit;
    return GestureDetector(
      onTap: () => setState(() {
        _unit.text = unit;
        _goal.text = '${defaultGoalForUnit(unit)}';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.chip,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          unit,
          style: TextStyle(
            color: selected ? colors.card : colors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _bumpGoal(int direction) {
    final current = int.tryParse(_goal.text) ?? 1;
    final step = current >= 500 ? 500 : 1;
    final next = (current + direction * step).clamp(1, 1000000);
    setState(() => _goal.text = '$next');
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _due = dateOnly(picked));
  }

  void _save() {
    final state = AppScope.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give it a name.');
      return;
    }
    if (_kind == ComposerKind.task) {
      final existing = widget.task;
      final task = TaskItem(
        id: existing?.id ?? state.createId(),
        title: name,
        dueDate: _due,
        done: existing?.done ?? false,
      );
      if (existing == null) {
        state.addTask(task);
      } else {
        state.updateTask(task);
      }
      Navigator.pop(context);
      return;
    }
    final goal = _habitKind == HabitKind.check ? 1 : int.tryParse(_goal.text);
    final unit = _habitKind == HabitKind.check ? 'time' : _unit.text.trim();
    if (goal == null || goal < 1) {
      setState(() => _error = 'The daily goal needs to be at least 1.');
      return;
    }
    if (unit.isEmpty) {
      setState(() => _error = 'Add a unit, like liters or steps.');
      return;
    }
    final existing = widget.habit;
    final habit = Habit(
      id: existing?.id ?? state.createId(),
      name: name,
      colorValue: _color,
      kind: _habitKind,
      goal: goal,
      unit: unit,
      createdAt: existing?.createdAt ?? DateTime.now(),
      log: existing?.log,
    );
    if (existing == null) {
      state.addHabit(habit);
    } else {
      state.updateHabit(habit);
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final state = AppScope.of(context);
    final habit = widget.habit;
    final task = widget.task;
    final ok = await confirmDelete(
      context,
      title: habit != null ? 'Delete habit?' : 'Delete task?',
      message: habit != null
          ? 'Daily checks for ${habit.name} will be removed from this device.'
          : 'This removes the task from your list.',
    );
    if (!ok || !mounted) return;
    if (habit != null) state.deleteHabit(habit.id);
    if (task != null) state.deleteTask(task.id);
    Navigator.pop(context);
  }
}

class _LogSheet extends StatefulWidget {
  const _LogSheet({required this.habitId, required this.day});

  final String habitId;
  final DateTime day;

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  final TextEditingController _amount = TextEditingController(text: '0');
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    final habit = AppScope.of(context).habitById(widget.habitId);
    if (habit == null) return;
    _seeded = true;
    _amount.text = '${valueOn(habit, widget.day)}';
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final habit = AppScope.of(context).habitById(widget.habitId);
    if (habit == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Habit removed')),
      );
    }
    final quick = _quickAdds(habit);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              habit.name,
              style: TextStyle(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              longDateLabel(widget.day),
              style: TextStyle(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _amountButton(
                  colors,
                  Icons.remove_rounded,
                  () => _apply(habit, -_step(habit)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(suffixText: habit.unit),
                  ),
                ),
                const SizedBox(width: 8),
                _amountButton(
                  colors,
                  Icons.add_rounded,
                  () => _apply(habit, _step(habit)),
                ),
              ],
            ),
            if (quick.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final amount in quick)
                    ActionChip(
                      label: Text('+${formatInt(amount)}'),
                      onPressed: () => _apply(habit, amount),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _commit(habit),
              child: const Text('Save this day'),
            ),
            TextButton(
              onPressed: () {
                final ok = AppScope.of(context)
                    .setHabitValue(habit.id, widget.day, 0);
                if (!ok) {
                  _blocked();
                  return;
                }
                Navigator.pop(context);
              },
              child: const Text('Clear day'),
            ),
          ],
        ),
      ),
    );
  }

  int _step(Habit habit) => habit.goal >= 100 ? 500 : 1;

  List<int> _quickAdds(Habit habit) {
    if (habit.goal >= 1000) return const [500, 1000, 2000];
    if (habit.goal >= 100) return const [100, 500, 1000];
    return const [];
  }

  void _apply(Habit habit, int delta) {
    final current = int.tryParse(_amount.text) ?? 0;
    final next = (current + delta).clamp(0, 1000000);
    setState(() => _amount.text = '$next');
  }

  void _commit(Habit habit) {
    final value = int.tryParse(_amount.text) ?? 0;
    final ok = AppScope.of(context).setHabitValue(habit.id, widget.day, value);
    if (!ok) {
      _blocked();
      return;
    }
    Navigator.pop(context);
  }

  void _blocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can log a habit once that day arrives.'),
      ),
    );
  }

  Widget _amountButton(AppColors colors, IconData icon, VoidCallback onTap) {
    return Material(
      color: colors.chip,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 48, height: 48, child: Icon(icon)),
      ),
    );
  }
}
