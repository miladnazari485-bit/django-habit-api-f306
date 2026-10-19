import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scaffold,
    required this.card,
    required this.chip,
    required this.band,
    required this.postpone,
    required this.muted,
    required this.weekday,
    required this.weekend,
    required this.ink,
    required this.badge,
    required this.line,
    required this.fab,
    required this.onFab,
    required this.taskIcon,
    required this.taskIconInk,
    required this.streakPill,
    required this.canvas,
  });

  final Color scaffold;
  final Color card;
  final Color chip;
  final Color band;
  final Color postpone;
  final Color muted;
  final Color weekday;
  final Color weekend;
  final Color ink;
  final Color badge;
  final Color line;
  final Color fab;
  final Color onFab;
  final Color taskIcon;
  final Color taskIconInk;
  final Color streakPill;
  final Color canvas;

  static const light = AppColors(
    scaffold: Color(0xFFECEAE4),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFE4E2DC),
    band: Color(0xFFE3E1DB),
    postpone: Color(0xFFD8D6D0),
    muted: Color(0xFF8E8B84),
    weekday: Color(0xFF6E62C4),
    weekend: Color(0xFF9C998F),
    ink: Color(0xFF1C1C1E),
    badge: Color(0xFFE53935),
    line: Color(0xFFD0CDC6),
    fab: Color(0xFF1C1C1E),
    onFab: Color(0xFFFFFFFF),
    taskIcon: Color(0xFFDDD7F8),
    taskIconInk: Color(0xFF5C54B5),
    streakPill: Color(0xFFF3F1EC),
    canvas: Color(0xFFD9D6CE),
  );

  static const dark = AppColors(
    scaffold: Color(0xFF121214),
    card: Color(0xFF1E1E24),
    chip: Color(0xFF2A2A32),
    band: Color(0xFF23232A),
    postpone: Color(0xFF32323C),
    muted: Color(0xFFA9A69F),
    weekday: Color(0xFFB7AFFF),
    weekend: Color(0xFF8E8B86),
    ink: Color(0xFFF5F3EE),
    badge: Color(0xFFFF5A5A),
    line: Color(0xFF3A3A44),
    fab: Color(0xFFF5F3EE),
    onFab: Color(0xFF121214),
    taskIcon: Color(0xFF3A3560),
    taskIconInk: Color(0xFFD9D4FF),
    streakPill: Color(0xFF2A2A32),
    canvas: Color(0xFF0B0B0D),
  );

  static AppColors of(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>();
    if (colors == null) {
      throw StateError('AppColors is missing from ThemeData.extensions.');
    }
    return colors;
  }

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? card,
    Color? chip,
    Color? band,
    Color? postpone,
    Color? muted,
    Color? weekday,
    Color? weekend,
    Color? ink,
    Color? badge,
    Color? line,
    Color? fab,
    Color? onFab,
    Color? taskIcon,
    Color? taskIconInk,
    Color? streakPill,
    Color? canvas,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      chip: chip ?? this.chip,
      band: band ?? this.band,
      postpone: postpone ?? this.postpone,
      muted: muted ?? this.muted,
      weekday: weekday ?? this.weekday,
      weekend: weekend ?? this.weekend,
      ink: ink ?? this.ink,
      badge: badge ?? this.badge,
      line: line ?? this.line,
      fab: fab ?? this.fab,
      onFab: onFab ?? this.onFab,
      taskIcon: taskIcon ?? this.taskIcon,
      taskIconInk: taskIconInk ?? this.taskIconInk,
      streakPill: streakPill ?? this.streakPill,
      canvas: canvas ?? this.canvas,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      band: Color.lerp(band, other.band, t)!,
      postpone: Color.lerp(postpone, other.postpone, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      weekday: Color.lerp(weekday, other.weekday, t)!,
      weekend: Color.lerp(weekend, other.weekend, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      line: Color.lerp(line, other.line, t)!,
      fab: Color.lerp(fab, other.fab, t)!,
      onFab: Color.lerp(onFab, other.onFab, t)!,
      taskIcon: Color.lerp(taskIcon, other.taskIcon, t)!,
      taskIconInk: Color.lerp(taskIconInk, other.taskIconInk, t)!,
      streakPill: Color.lerp(streakPill, other.streakPill, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
    );
  }
}

const habitColorValues = <int>[
  0xFFF6D452,
  0xFFCBC6F6,
  0xFFEF3B70,
  0xFF7DCEB0,
  0xFFF0A36B,
  0xFF8EBEF0,
  0xFFE79ABF,
  0xFFB7A0F2,
];

const habitUnits = <String>[
  'time',
  'liters',
  'steps',
  'minutes',
  'pages',
  'km',
];

Color foregroundOn(Color background) {
  return background.computeLuminance() > 0.62
      ? const Color(0xFF1B1B1C)
      : Colors.white;
}

int nextHabitColor(Iterable<int> used) {
  final taken = used.toSet();
  for (final color in habitColorValues) {
    if (!taken.contains(color)) return color;
  }
  return habitColorValues[taken.length % habitColorValues.length];
}

int defaultGoalForUnit(String unit) {
  switch (unit) {
    case 'steps':
      return 10000;
    case 'liters':
      return 6;
    case 'minutes':
      return 30;
    case 'pages':
      return 10;
    case 'km':
      return 5;
    default:
      return 1;
  }
}

ThemeData buildLightTheme() => _build(AppColors.light, Brightness.light);

ThemeData buildDarkTheme() => _build(AppColors.dark, Brightness.dark);

ThemeData _build(AppColors colors, Brightness brightness) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: colors.ink,
    onPrimary: colors.card,
    secondary: colors.weekday,
    onSecondary: colors.card,
    error: colors.badge,
    onError: Colors.white,
    surface: colors.card,
    onSurface: colors.ink,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.scaffold,
    fontFamily: 'PlusJakartaSans',
    fontFamilyFallback: const [
      'Roboto',
      'Helvetica Neue',
      'Arial',
      'sans-serif',
    ],
    extensions: [colors],
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
      fontFamily: 'PlusJakartaSans',
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.ink,
      contentTextStyle: TextStyle(
        color: colors.card,
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.ink,
        foregroundColor: colors.card,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.chip,
      hintStyle: TextStyle(color: colors.muted, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
