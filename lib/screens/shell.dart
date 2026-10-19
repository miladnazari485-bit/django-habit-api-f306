import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/sheets.dart';
import 'calendar_screen.dart';
import 'habit_detail_screen.dart';
import 'stats_screen.dart';
import 'tasks_screen.dart';
import 'today_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  String? _detailId;
  bool _sessionApplied = false;

  void _setTab(int index) {
    setState(() {
      _tab = index;
      _detailId = null;
    });
    final state = AppScope.of(context);
    state.rememberTab(index);
    state.rememberDetail(null);
  }

  void _openHabit(String id) {
    setState(() => _detailId = id);
    AppScope.of(context).rememberDetail(id);
  }

  void _closeHabit() {
    setState(() => _detailId = null);
    AppScope.of(context).rememberDetail(null);
  }

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sessionApplied) {
      _sessionApplied = true;
      final saved = AppScope.of(context);
      _tab = saved.tab;
      final detail = saved.detailHabitId;
      if (detail != null && saved.habitById(detail) != null) {
        _detailId = detail;
      }
    }
    final colors = AppColors.of(context);
    final night = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: night ? Brightness.light : Brightness.dark,
        statusBarBrightness: night ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.scaffold,
        systemNavigationBarIconBrightness: night
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final colors = AppColors.of(context);
    final drawerOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    return PopScope(
      canPop: _detailId == null && !drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
          return;
        }
        if (_detailId != null) _closeHabit();
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        drawer: _AppDrawer(
          night: state.night,
          habitCount: state.habits.length,
          openTasks: state.tasks.where((task) => !task.done).length,
          onNight: state.setNight,
          onOpenTasks: () {
            Navigator.pop(context);
            _setTab(1);
          },
          onOpenStats: () {
            Navigator.pop(context);
            _setTab(3);
          },
        ),
        floatingActionButton: _detailId == null
            ? FloatingActionButton(
                tooltip: 'Add',
                backgroundColor: colors.fab,
                foregroundColor: colors.onFab,
                elevation: 2,
                shape: const CircleBorder(),
                onPressed: () {
                  if (_tab == 1) {
                    showComposer(context, kind: ComposerKind.task);
                  } else if (_tab == 0) {
                    showComposer(context);
                  } else {
                    showComposer(context, kind: ComposerKind.habit);
                  }
                },
                child: const Icon(Icons.add_rounded, size: 30),
              )
            : null,
        bottomNavigationBar: _BottomBar(index: _tab, onChanged: _setTab),
        body: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                TodayScreen(
                  onMenu: _openMenu,
                  onOpenStats: () => _setTab(3),
                  onOpenHabit: _openHabit,
                ),
                TasksScreen(onMenu: _openMenu),
                CalendarScreen(
                  onMenu: _openMenu,
                  onOpenDay: (day) {
                    state.selectDate(day);
                    _setTab(0);
                  },
                ),
                StatsScreen(onMenu: _openMenu, onOpenHabit: _openHabit),
              ],
            ),
            if (_detailId != null)
              Positioned.fill(
                child: Material(
                  color: colors.scaffold,
                  child: HabitDetailScreen(
                    habitId: _detailId!,
                    onBack: _closeHabit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const items = [
      (Icons.check_rounded, 'Today'),
      (Icons.list_alt_rounded, 'Tasks'),
      (Icons.calendar_today_rounded, 'Calendar'),
      (Icons.bar_chart_rounded, 'Insights'),
    ];
    return Material(
      color: colors.scaffold,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 64,
          height: 48,
          child: Icon(
            icon,
            size: selected ? 28 : 26,
            color: selected ? colors.ink : colors.muted.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.night,
    required this.habitCount,
    required this.openTasks,
    required this.onNight,
    required this.onOpenTasks,
    required this.onOpenStats,
  });

  final bool night;
  final int habitCount;
  final int openTasks;
  final ValueChanged<bool> onNight;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Drawer(
      backgroundColor: colors.scaffold,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habit Tracker',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A separate check for every habit, every day.',
                style: TextStyle(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Mood',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.chip,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _mood(
                      colors,
                      'Day',
                      Icons.light_mode_rounded,
                      !night,
                      () => onNight(false),
                    ),
                    _mood(
                      colors,
                      'Night',
                      Icons.dark_mode_rounded,
                      night,
                      () => onNight(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                '$habitCount ${habitCount == 1 ? 'habit' : 'habits'} · $openTasks open ${openTasks == 1 ? 'task' : 'tasks'}',
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.list_alt_rounded),
                title: const Text(
                  'Tasks',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: onOpenTasks,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bar_chart_rounded),
                title: const Text(
                  'Insights',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: onOpenStats,
              ),
              const Spacer(),
              Text(
                'Checks and math stay on this phone. Nothing is sent to a server.',
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

  Widget _mood(
    AppColors colors,
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: selected ? colors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: colors.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
