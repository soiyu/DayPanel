import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';

/// 365-day Activity Matrix (Heatmap) widget.
/// Renders 52+ weeks of daily consistency in a compact, highly performant grid.
class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({
    super.key,
    required this.today,
    required this.levelForDay,
    this.detailForDay,
    this.title,
    this.subtitle,
    this.tone = UiTone.teal,
    this.onDayTap,
    this.initialSelectedDay,
  });

  final Day today;
  final int Function(Day day) levelForDay;
  final String? Function(Day day)? detailForDay;
  final String? title;
  final String? subtitle;
  final UiTone tone;
  final ValueChanged<Day>? onDayTap;
  final Day? initialSelectedDay;

  static Color colorForLevel(BuildContext context, int level, UiTone tone) {
    final theme = Theme.of(context);
    return switch (level) {
      1 => tone.ink(context).withValues(alpha: 0.30),
      2 => tone.ink(context).withValues(alpha: 0.65),
      3 => tone.ink(context),
      _ => theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.40),
    };
  }

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late final ScrollController _scrollController;
  Day? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialSelectedDay ?? widget.today;
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final endMonday = widget.today.monday;
    final startMonday = endMonday.plus(-7 * 52); // 52 weeks back

    const cellSize = 12.0;
    const cellSpacing = 3.0;
    const step = cellSize + cellSpacing;
    const leftLabelWidth = 24.0;
    const topLabelHeight = 18.0;

    final selected = _selectedDay;
    final selectedLevel = selected == null ? 0 : widget.levelForDay(selected);
    final selectedDetail = selected == null
        ? null
        : (widget.detailForDay?.call(selected) ?? '');

    String levelName(int level) => switch (level) {
      1 => s.heatmapLevel1,
      2 => s.heatmapLevel2,
      3 => s.heatmapLevel3,
      _ => s.heatmapLevel0,
    };

    return SoftPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title!,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                // Legend: Less [0] [1] [2] [3] More
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.heatmapLegendLess,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    for (var l = 0; l <= 3; l++)
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: ActivityHeatmap.colorForLevel(
                            context,
                            l,
                            widget.tone,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      s.heatmapLegendMore,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(widget.subtitle!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
          ],

          // Heatmap grid with left weekday labels and top month labels
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday initials column (Mon, Wed, Fri)
                Padding(
                  padding: const EdgeInsets.only(top: topLabelHeight),
                  child: SizedBox(
                    width: leftLabelWidth,
                    height: 7 * step,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var r = 0; r < 7; r++)
                          SizedBox(
                            height: step,
                            child: (r == 0 || r == 2 || r == 4)
                                ? Text(
                                    switch (r) {
                                      0 => s.weekMon.substring(0, 1),
                                      2 => s.weekWed.substring(0, 1),
                                      _ => s.weekFri.substring(0, 1),
                                    },
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 9,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),

                // 53 week columns
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(53 * step, topLabelHeight + 7 * step),
                    painter: _HeatmapPainter(
                      today: widget.today,
                      startMonday: startMonday,
                      selectedDay: _selectedDay,
                      levelForDay: widget.levelForDay,
                      tone: widget.tone,
                      context: context,
                      locale: locale,
                    ),
                    child: SizedBox(
                      width: 53 * step,
                      height: topLabelHeight + 7 * step,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (details) {
                          final local = details.localPosition;
                          if (local.dy < topLabelHeight) return;
                          final col = (local.dx / step).floor();
                          final row = ((local.dy - topLabelHeight) / step)
                              .floor();
                          if (col >= 0 && col < 53 && row >= 0 && row < 7) {
                            final clickedDay = startMonday.plus(col * 7 + row);
                            if (clickedDay.compareTo(widget.today) <= 0) {
                              setState(() => _selectedDay = clickedDay);
                              widget.onDayTap?.call(clickedDay);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail banner for selected day
          if (selected != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.tone.wash(context).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.tone.ink(context).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ActivityHeatmap.colorForLevel(
                        context,
                        selectedLevel,
                        widget.tone,
                      ),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateFormat.yMMMd(locale).format(selected.date)} · ${levelName(selectedLevel)}${selectedDetail != null && selectedDetail.isNotEmpty ? ' ($selectedDetail)' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.onDayTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.today,
    required this.startMonday,
    required this.selectedDay,
    required this.levelForDay,
    required this.tone,
    required this.context,
    required this.locale,
  });

  final Day today;
  final Day startMonday;
  final Day? selectedDay;
  final int Function(Day day) levelForDay;
  final UiTone tone;
  final BuildContext context;
  final String locale;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 12.0;
    const cellSpacing = 3.0;
    const step = cellSize + cellSpacing;
    const topLabelHeight = 18.0;

    final cellPaint = Paint()..style = PaintingStyle.fill;
    final selectPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = tone.ink(context);

    final todayDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = tone.ink(context);

    final textStyle = TextStyle(
      fontSize: 9,
      color: Theme.of(
        context,
      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      fontWeight: FontWeight.w500,
    );

    int? lastMonth;
    var lastMonthCol = -10;

    // 1. Draw month labels along the top
    for (var col = 0; col < 53; col++) {
      final colMonday = startMonday.plus(col * 7);
      final month = colMonday.date.month;
      if (month != lastMonth && (col - lastMonthCol) >= 3) {
        lastMonth = month;
        lastMonthCol = col;
        final monthStr = DateFormat.MMM(locale).format(colMonday.date);
        final tp = TextPainter(
          text: TextSpan(text: monthStr, style: textStyle),
          textDirection: Directionality.of(context),
        )..layout();
        tp.paint(canvas, Offset(col * step, 0));
        tp.dispose();
      }
    }

    // 2. Draw 53 * 7 cells
    for (var col = 0; col < 53; col++) {
      for (var row = 0; row < 7; row++) {
        final day = startMonday.plus(col * 7 + row);
        final isFuture = day.compareTo(today) > 0;
        final x = col * step;
        final y = topLabelHeight + row * step;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          const Radius.circular(2.5),
        );

        if (isFuture) {
          // Dimmed future cell
          cellPaint.color = Colors.transparent;
          canvas.drawRRect(rect, cellPaint);
          continue;
        }

        final level = levelForDay(day);
        cellPaint.color = ActivityHeatmap.colorForLevel(context, level, tone);
        canvas.drawRRect(rect, cellPaint);

        // Highlight selected cell
        if (selectedDay != null && day == selectedDay) {
          canvas.drawRRect(rect, selectPaint);
        }

        // Today dot indicator
        if (day == today) {
          canvas.drawCircle(
            Offset(x + cellSize / 2, y + cellSize / 2),
            1.5,
            level >= 2 ? (Paint()..color = Colors.white) : todayDotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter oldDelegate) {
    return oldDelegate.today != today ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.tone != tone;
  }
}
