import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.onMenu,
    required this.onToggleTheme,
    this.onChart,
    this.badge = 0,
    this.night = false,
  });

  final String title;
  final VoidCallback onMenu;
  final VoidCallback onToggleTheme;
  final VoidCallback? onChart;
  final int badge;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final top = math.max(MediaQuery.paddingOf(context).top, 10.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 6, 16, 6),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                _HeaderButton(
                  tooltip: 'Menu',
                  onPressed: onMenu,
                  child: Icon(Icons.menu_rounded, color: colors.ink, size: 22),
                ),
                if (onChart != null) ...[
                  const SizedBox(width: 8),
                  _ChartButton(
                    onPressed: onChart!,
                    badge: badge,
                    colors: colors,
                  ),
                ],
                const Spacer(),
                _HeaderButton(
                  tooltip: night
                      ? 'Switch to day mood'
                      : 'Switch to night mood',
                  onPressed: onToggleTheme,
                  circular: true,
                  child: Icon(
                    night ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: colors.ink,
                    size: 20,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 112),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.circular = false,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = circular ? 21.0 : 14.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: colors.line, width: 1.3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(width: 42, height: 42, child: child),
        ),
      ),
    );
  }
}

class _ChartButton extends StatelessWidget {
  const _ChartButton({
    required this.onPressed,
    required this.badge,
    required this.colors,
  });

  final VoidCallback onPressed;
  final int badge;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final tooltip = badge > 0 ? 'Insights, $badge overdue' : 'Insights';
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: colors.ink,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: colors.card,
                    size: 22,
                  ),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: colors.badge,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.scaffold, width: 1.6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
