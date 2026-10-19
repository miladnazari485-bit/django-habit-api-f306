import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final state = AppState();
  await state.load();
  runApp(HabitTrackerApp(state: state));
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key, required this.state});

  final AppState state;

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  ThemeMode? _mode;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (_mode != widget.state.themeMode) {
      setState(() => _mode = widget.state.themeMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    _mode = widget.state.themeMode;
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: widget.state.themeMode,
        themeAnimationDuration: const Duration(milliseconds: 250),
        scrollBehavior: const AppScrollBehavior(),
        home: const ResponsiveFrame(child: Shell()),
      ),
    );
  }
}

/// On a wide browser window the app sits in a phone-sized frame. On a phone
/// it fills the screen, which is how Android and iOS will show it.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) return child;
        final colors = AppColors.of(context);
        final height = math.min(constraints.maxHeight - 48, 880.0);
        return ColoredBox(
          color: colors.canvas,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: colors.ink.withValues(alpha: 0.14),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: SizedBox(width: 400, height: height, child: child),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
