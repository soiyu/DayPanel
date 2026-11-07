import 'package:flutter/material.dart';
import 'theme.dart';

/// Original multicolor object artwork. Theme affects its frame, never its colors.
class HabitIcon extends StatelessWidget {
  const HabitIcon(
    this.index, {
    super.key,
    this.size = 54,
    this.color = 'auto',
    this.frame = 'auto',
  });
  final int index;
  final double size;
  final String color, frame;
  @override
  Widget build(BuildContext context) {
    final style = frame == 'auto'
        ? DayPanelStyle.of(context).appearance.frame
        : frame;
    final tone = habitTone(index, color);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(style == 'plain' ? 0 : size * .035),
      decoration: BoxDecoration(
        color: style == 'soft'
            ? tone.wash(context).withValues(alpha: .65)
            : null,
        borderRadius: BorderRadius.circular(style == 'ring' ? size : size * .3),
        border: style == 'ring'
            ? Border.all(
                color: tone.ink(context).withValues(alpha: .5),
                width: 1.4,
              )
            : null,
      ),
      child: Image.asset(
        'assets/habit_icons/${index.clamp(0, 23).toString().padLeft(2, '0')}.png',
        excludeFromSemantics: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
