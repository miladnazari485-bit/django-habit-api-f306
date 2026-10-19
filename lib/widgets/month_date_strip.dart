import 'package:flutter/material.dart';

import '../logic/dates.dart';
import '../theme/app_theme.dart';

class MonthDateStrip extends StatefulWidget {
  const MonthDateStrip({
    super.key,
    required this.visibleMonth,
    required this.selected,
    required this.onSelect,
    required this.pinToken,
  });

  final DateTime visibleMonth;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  /// Increment to center today again when the user jumps back to today.
  final int pinToken;

  @override
  State<MonthDateStrip> createState() => _MonthDateStripState();
}

class _MonthDateStripState extends State<MonthDateStrip> {
  static const _itemWidth = 54.0;
  static const _gap = 8.0;
  static const _leading = 16.0;

  final ScrollController _controller = ScrollController();
  int _generation = 0;
  int _appliedPin = 0;

  @override
  void initState() {
    super.initState();
    _appliedPin = widget.pinToken;
    if (isSameMonth(widget.selected, widget.visibleMonth)) {
      _schedule(widget.selected.day, forceCenter: true, jump: true);
      return;
    }
    final today = DateTime.now();
    if (isSameMonth(today, widget.visibleMonth)) {
      _schedule(today.day, forceCenter: true, jump: true);
    }
  }

  @override
  void didUpdateWidget(MonthDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final monthChanged = !isSameMonth(
      oldWidget.visibleMonth,
      widget.visibleMonth,
    );
    if (widget.pinToken != _appliedPin) {
      _appliedPin = widget.pinToken;
      final today = DateTime.now();
      if (isSameMonth(today, widget.visibleMonth)) {
        _schedule(today.day, forceCenter: true, jump: false);
      }
      return;
    }
    if (monthChanged) {
      final day = isSameMonth(widget.selected, widget.visibleMonth)
          ? widget.selected.day
          : 1;
      _schedule(day, forceCenter: true, jump: true);
      return;
    }
    if (!isSameDay(oldWidget.selected, widget.selected) &&
        isSameMonth(widget.selected, widget.visibleMonth)) {
      _schedule(widget.selected.day, forceCenter: false, jump: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _schedule(int day, {required bool forceCenter, required bool jump}) {
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      if (!_controller.hasClients) return;
      _move(day, forceCenter: forceCenter, jump: jump);
    });
  }

  void _move(int day, {required bool forceCenter, required bool jump}) {
    final position = _controller.position;
    final start = _leading + (day - 1) * (_itemWidth + _gap);
    final end = start + _itemWidth;
    final offset = _controller.offset;
    final viewport = position.viewportDimension;
    final visible = start >= offset - 1 && end <= offset + viewport + 1;
    if (!forceCenter && visible) return;
    final target = (start - (viewport - _itemWidth) / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (jump) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.visibleMonth.year;
    final month = widget.visibleMonth.month;
    final count = daysInMonth(year, month);
    final today = dateOnly(DateTime.now());
    return SizedBox(
      height: 78,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        primary: false,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: _leading),
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final day = DateTime(year, month, index + 1);
          final selected = isSameDay(day, widget.selected);
          final isToday = isSameDay(day, today);
          return _DayChip(
            day: day,
            selected: selected,
            today: isToday,
            onTap: () => widget.onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final weekend = isWeekend(day);
    final label = StringBuffer(longDateLabel(day));
    if (today) label.write(', today');
    if (selected) label.write(', selected');
    return Semantics(
      button: true,
      selected: selected,
      label: label.toString(),
      child: Material(
        color: selected ? colors.card : colors.chip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? colors.ink : Colors.transparent,
            width: 1.6,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: _MonthDateStripState._itemWidth,
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayShort[sundayIndex(day)],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: weekend ? colors.weekend : colors.weekday,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.ink,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: today ? colors.weekday : Colors.transparent,
                    shape: BoxShape.circle,
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
