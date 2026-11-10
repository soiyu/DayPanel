import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Six original vector scenes authored for DayPanel. No external art assets.
class CardArt extends StatelessWidget {
  const CardArt({super.key, required this.artwork, this.height = 190});
  final int artwork;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _Scene(
            artwork,
            Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    ),
  );
}

class _Scene extends CustomPainter {
  const _Scene(this.artwork, this.dark);
  final int artwork;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 190);
    final bg = dark ? const Color(0xFF293451) : const Color(0xFFEDF3FF);
    final ink = dark ? const Color(0xFFAAC6FF) : const Color(0xFF5885D9);
    final purple = dark ? const Color(0xFFAE99E8) : const Color(0xFFB7A4E7);
    final orange = dark ? const Color(0xFFF0BC8B) : const Color(0xFFF2C49F);
    final wash = dark ? const Color(0xFF394461) : const Color(0xFFDCE6FA);
    void oval(Rect rect, Color color) =>
        canvas.drawOval(rect, Paint()..color = color);
    void line(Offset a, Offset b, Color color, double width) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void rect(Rect r, Color color, {double radius = 0}) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = color,
    );
    void path(Path p, Color color) =>
        canvas.drawPath(p, Paint()..color = color);
    rect(const Rect.fromLTWH(0, 0, 320, 190), bg);
    switch (artwork) {
      case 0: // Dawn across quiet hills.
        oval(const Rect.fromLTWH(202, 24, 60, 60), orange);
        path(
          Path()
            ..moveTo(0, 120)
            ..quadraticBezierTo(70, 52, 156, 115)
            ..quadraticBezierTo(241, 167, 320, 95)
            ..lineTo(320, 190)
            ..lineTo(0, 190)
            ..close(),
          purple,
        );
        path(
          Path()
            ..moveTo(0, 155)
            ..quadraticBezierTo(122, 93, 225, 155)
            ..quadraticBezierTo(278, 185, 320, 135)
            ..lineTo(320, 190)
            ..lineTo(0, 190)
            ..close(),
          ink,
        );
        line(const Offset(32, 42), const Offset(77, 42), wash, 4);
        line(const Offset(46, 52), const Offset(95, 52), wash, 4);
      case 1: // A plant with visible roots.
        oval(const Rect.fromLTWH(90, 142, 142, 24), wash);
        path(
          Path()
            ..moveTo(122, 117)
            ..lineTo(198, 117)
            ..lineTo(187, 157)
            ..lineTo(133, 157)
            ..close(),
          orange,
        );
        line(const Offset(160, 127), const Offset(160, 52), ink, 4);
        path(
          Path()
            ..moveTo(160, 99)
            ..quadraticBezierTo(97, 95, 111, 62)
            ..quadraticBezierTo(153, 62, 160, 99),
          purple,
        );
        path(
          Path()
            ..moveTo(160, 76)
            ..quadraticBezierTo(162, 35, 204, 38)
            ..quadraticBezierTo(211, 71, 160, 76),
          ink,
        );
        line(const Offset(151, 135), const Offset(142, 147), bg, 2);
        line(const Offset(160, 132), const Offset(161, 151), bg, 2);
        line(const Offset(171, 136), const Offset(181, 146), bg, 2);
        oval(const Rect.fromLTWH(56, 35, 17, 17), orange);
      case 2: // A river finding a path.
        path(
          Path()
            ..moveTo(0, 113)
            ..quadraticBezierTo(83, 56, 150, 104)
            ..quadraticBezierTo(236, 48, 320, 112)
            ..lineTo(320, 190)
            ..lineTo(0, 190)
            ..close(),
          purple,
        );
        path(
          Path()
            ..moveTo(170, 75)
            ..cubicTo(256, 104, 91, 119, 132, 149)
            ..quadraticBezierTo(152, 170, 227, 190)
            ..lineTo(72, 190)
            ..cubicTo(7, 144, 191, 128, 160, 76)
            ..close(),
          ink,
        );
        line(const Offset(156, 138), const Offset(183, 138), bg, 2);
        line(const Offset(121, 163), const Offset(161, 163), bg, 2);
        oval(const Rect.fromLTWH(56, 25, 42, 42), orange);
      case 3: // Small steps to an open sky.
        for (var i = 0; i < 5; i++) {
          rect(
            Rect.fromLTWH(45 + i * 42, 145 - i * 23, 45, 55 + i * 23),
            i.isEven ? ink : purple,
            radius: 4,
          );
        }
        oval(const Rect.fromLTWH(228, 13, 38, 38), orange);
        line(const Offset(55, 45), const Offset(93, 45), wash, 5);
        line(const Offset(68, 55), const Offset(118, 55), wash, 5);
      case 4: // Light at a window, a book on the sill.
        rect(const Rect.fromLTWH(88, 23, 144, 124), purple, radius: 36);
        rect(const Rect.fromLTWH(98, 33, 124, 106), wash, radius: 28);
        oval(const Rect.fromLTWH(171, 43, 31, 31), orange);
        path(
          Path()
            ..moveTo(98, 110)
            ..quadraticBezierTo(148, 70, 222, 110)
            ..lineTo(222, 139)
            ..lineTo(98, 139)
            ..close(),
          ink,
        );
        line(const Offset(160, 28), const Offset(160, 144), purple, 7);
        line(const Offset(94, 92), const Offset(227, 92), purple, 7);
        rect(const Rect.fromLTWH(76, 145, 168, 9), orange, radius: 4);
        rect(const Rect.fromLTWH(116, 154, 70, 12), ink, radius: 3);
        line(const Offset(125, 159), const Offset(175, 159), bg, 2);
      case 6: // Original review illustration: an open journal, warm mug and leaf.
        oval(const Rect.fromLTWH(54, 150, 214, 20), wash);
        path(
          Path()
            ..moveTo(70, 46)
            ..quadraticBezierTo(115, 31, 158, 56)
            ..lineTo(158, 145)
            ..quadraticBezierTo(115, 120, 70, 137)
            ..close(),
          purple,
        );
        path(
          Path()
            ..moveTo(162, 56)
            ..quadraticBezierTo(205, 31, 250, 46)
            ..lineTo(250, 137)
            ..quadraticBezierTo(205, 120, 162, 145)
            ..close(),
          ink,
        );
        for (var i = 0; i < 4; i++) {
          line(Offset(86, 65 + i * 16), Offset(139, 72 + i * 16), bg, 3);
          line(Offset(181, 72 + i * 16), Offset(233, 65 + i * 16), bg, 3);
        }
        oval(const Rect.fromLTWH(31, 102, 43, 44), orange);
        line(const Offset(49, 116), const Offset(58, 92), purple, 3);
      case 7: // Original review illustration: a small coastal lighthouse.
        path(
          Path()
            ..moveTo(0, 145)
            ..quadraticBezierTo(80, 98, 164, 143)
            ..quadraticBezierTo(250, 183, 320, 122)
            ..lineTo(320, 190)
            ..lineTo(0, 190)
            ..close(),
          wash,
        );
        path(
          Path()
            ..moveTo(0, 167)
            ..quadraticBezierTo(130, 127, 229, 164)
            ..quadraticBezierTo(280, 178, 320, 157)
            ..lineTo(320, 190)
            ..lineTo(0, 190)
            ..close(),
          purple,
        );
        path(
          Path()
            ..moveTo(127, 144)
            ..lineTo(141, 57)
            ..lineTo(179, 57)
            ..lineTo(194, 144)
            ..close(),
          ink,
        );
        rect(const Rect.fromLTWH(136, 40, 49, 25), orange, radius: 5);
        line(const Offset(132, 38), const Offset(190, 38), purple, 5);
        line(const Offset(146, 89), const Offset(176, 89), bg, 6);
        line(const Offset(141, 118), const Offset(182, 118), bg, 6);
        oval(const Rect.fromLTWH(225, 25, 37, 37), orange);
      default: // Constellation of small moments.
        final points = [
          const Offset(69, 125),
          const Offset(112, 57),
          const Offset(175, 89),
          const Offset(238, 43),
          const Offset(262, 130),
        ];
        for (var i = 0; i < points.length - 1; i++) {
          line(points[i], points[i + 1], purple, 2);
        }
        for (final point in points) {
          oval(Rect.fromCircle(center: point, radius: 6), orange);
          line(
            point + const Offset(-10, 0),
            point + const Offset(10, 0),
            orange,
            2,
          );
          line(
            point + const Offset(0, -10),
            point + const Offset(0, 10),
            orange,
            2,
          );
        }
        for (var i = 0; i < 18; i++) {
          oval(
            Rect.fromCircle(
              center: Offset(
                20 + (i * 47 % 280).toDouble(),
                18 + (i * 31 % 150).toDouble(),
              ),
              radius: 1.6,
            ),
            ink,
          );
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Scene oldDelegate) =>
      artwork != oldDelegate.artwork || dark != oldDelegate.dark;
}

Widget cardFlipTransition(Widget child, Animation<double> animation) =>
    AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .001)
          ..rotateY((1 - animation.value) * math.pi / 2),
        child: Opacity(opacity: animation.value, child: child),
      ),
    );
