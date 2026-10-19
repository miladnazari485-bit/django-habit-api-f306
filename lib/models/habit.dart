enum HabitKind { check, count }

/// A repeating habit. [log] maps `yyyy-MM-dd` to the amount recorded that day.
class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.kind,
    required this.goal,
    required this.unit,
    required this.createdAt,
    Map<String, int>? log,
  }) : log = Map<String, int>.unmodifiable(log ?? const {});

  final String id;
  final String name;
  final int colorValue;
  final HabitKind kind;
  final int goal;
  final String unit;
  final DateTime createdAt;
  final Map<String, int> log;

  Habit copyWith({
    String? id,
    String? name,
    int? colorValue,
    HabitKind? kind,
    int? goal,
    String? unit,
    DateTime? createdAt,
    Map<String, int>? log,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      kind: kind ?? this.kind,
      goal: goal ?? this.goal,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      log: log ?? this.log,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': colorValue,
      'kind': kind.name,
      'goal': goal,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'log': log,
    };
  }

  static Habit? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = raw['name'];
    final color = raw['color'];
    final kindName = raw['kind'];
    final goal = raw['goal'];
    final unit = raw['unit'];
    if (id is! String || name is! String || name.trim().isEmpty) return null;
    if (color is! num || goal is! num || unit is! String) return null;
    final kind = HabitKind.values.where((item) => item.name == kindName);
    if (kind.isEmpty) return null;
    final createdRaw = raw['createdAt'];
    final created = createdRaw is String
        ? DateTime.tryParse(createdRaw) ?? DateTime.now()
        : DateTime.now();
    return Habit(
      id: id,
      name: name.trim(),
      colorValue: color.round(),
      kind: kind.first,
      goal: goal.round().clamp(1, 1000000),
      unit: unit.trim().isEmpty ? 'time' : unit.trim(),
      createdAt: created,
      log: _readLog(raw['log']),
    );
  }

  static Map<String, int> _readLog(dynamic raw) {
    if (raw is! Map) return const {};
    final log = <String, int>{};
    raw.forEach((key, value) {
      if (key is String && value is num && value > 0) {
        log[key] = value.round();
      }
    });
    return log;
  }
}
