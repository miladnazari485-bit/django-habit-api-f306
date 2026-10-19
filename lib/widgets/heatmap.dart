import 'package:flutter/material.dart';

import '../logic/habit_math.dart';
import '../models/habit.dart';

class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.habit,
    required this.end,
    this.rows = 7,
  });

  final Habit habit;
  final DateTime end;
  final int rows;

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final width = constraints.maxWidth;
        final columns = ((width + gap) / 12).floor().clamp(14, 36);
        final cell = (width - gap * (columns - 1)) / columns;
        final ratios = heatmapRatios(habit, end, rows * columns);
        return SizedBox(
          height: rows * cell + gap * (rows - 1),
          width: width,
          child: CustomPaint(
            painter: _HeatmapPainter(
              ratios: ratios,
              columns: columns,
              color: color,
              gap: gap,
              dark: dark,
            ),
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter({
    required this.ratios,
    required this.columns,
    required this.color,
    required this.gap,
    required this.dark,
  });

  final List<double> ratios;
  final int columns;
  final Color color;
  final double gap;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || ratios.isEmpty) return;
    final rows = (ratios.length / columns).ceil();
    final cell = (size.width - gap * (columns - 1)) / columns;
    final paint = Paint()..isAntiAlias = true;
    for (var index = 0; index < ratios.length; index++) {
      final row = index ~/ columns;
      final column = index % columns;
      if (row >= rows) break;
      final rect = Rect.fromLTWH(
        column * (cell + gap),
        row * (cell + gap),
        cell,
        cell,
      );
      paint.color = _cell(ratios[index]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.6)),
        paint,
      );
    }
  }

  Color _cell(double ratio) {
    if (ratio <= 0) {
      return color.withValues(alpha: dark ? 0.18 : 0.28);
    }
    final tone = ratio.clamp(0.0, 1.0);
    final start = color.withValues(alpha: dark ? 0.45 : 0.5);
    return Color.lerp(start, color, 0.35 + 0.65 * tone)!;
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return oldDelegate.ratios != ratios ||
        oldDelegate.columns != columns ||
        oldDelegate.color != color ||
        oldDelegate.dark != dark;
  }
}
