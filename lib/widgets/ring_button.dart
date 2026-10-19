import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RingButton extends StatelessWidget {
  const RingButton({
    super.key,
    required this.progress,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.onLongPress,
    this.circular = false,
    this.accent = const Color(0xFF1C1C1E),
    this.completed = false,
  });

  final double progress;
  final IconData icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String tooltip;
  final bool circular;
  final Color accent;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = circular ? 21.0 : 12.0;
    final fill = completed && !circular ? accent : Colors.transparent;
    final iconColor = completed && !circular
        ? foregroundOn(accent)
        : colors.ink;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: completed && !circular ? accent : colors.line,
              width: 1.4,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            onLongPress: onLongPress,
            child: CustomPaint(
              painter: circular
                  ? _RingPainter(
                      progress: progress,
                      color: accent,
                      track: colors.line,
                    )
                  : null,
              child: Icon(
                completed ? Icons.check_rounded : icon,
                size: 22,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.4;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, paint);
    final amount = progress.clamp(0.0, 1.0);
    if (amount <= 0) return;
    paint.color = color;
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * amount, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.track != track;
  }
}
