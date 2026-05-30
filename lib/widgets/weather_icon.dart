import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:baka/models/anchor.dart';

class WeatherIcon extends StatelessWidget {
  final WeatherCondition condition;
  final double size;
  final Color color;
  const WeatherIcon(this.condition, {super.key, this.size = 28, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _WeatherPainter(condition, color),
      );
}

class _WeatherPainter extends CustomPainter {
  final WeatherCondition condition;
  final Color color;
  _WeatherPainter(this.condition, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 24.0;
    canvas
      ..save()
      ..translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2)
      ..scale(s);
    _draw(canvas);
    canvas.restore();
  }

  Paint get _p => Paint()
    ..color = color
    ..strokeWidth = 1.75
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _f => Paint()..color = color..style = PaintingStyle.fill;

  void _draw(Canvas canvas) {
    switch (condition) {
      case WeatherCondition.sunny:
        // Circle + 8 rays
        canvas.drawCircle(const Offset(12, 12), 4, _p);
        for (final seg in [
          [12.0, 2.0, 12.0, 5.0], [12.0, 19.0, 12.0, 22.0],
          [2.0, 12.0, 5.0, 12.0], [19.0, 12.0, 22.0, 12.0],
          [4.9, 4.9, 7.0, 7.0], [17.0, 17.0, 19.1, 19.1],
          [4.9, 19.1, 7.0, 17.0], [17.0, 7.0, 19.1, 4.9],
        ]) {
          canvas.drawLine(Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), _p);
        }

      case WeatherCondition.cloudy:
        canvas.drawPath(_cloudPath(), _p);

      case WeatherCondition.partlyCloudy:
        // Half sun + cloud
        final sunP = _p..strokeWidth = 1.5;
        canvas.drawArc(const Rect.fromLTWH(5, 4, 8, 8), math.pi * 0.25, math.pi, false, sunP);
        for (final seg in [
          [9.0, 3.0, 9.0, 1.5], [14.0, 7.0, 15.5, 7.0], [12.8, 3.7, 13.8, 2.7],
        ]) {
          canvas.drawLine(Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), sunP);
        }
        canvas.drawPath(_cloudPath(top: 11), _p..strokeWidth = 1.75);

      case WeatherCondition.rainy:
        canvas.drawPath(_cloudPath(), _p);
        for (final seg in [
          [7.0, 17.0, 5.5, 21.0], [12.0, 17.0, 10.5, 21.0], [17.0, 17.0, 15.5, 21.0],
        ]) {
          canvas.drawLine(Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), _p);
        }

      case WeatherCondition.stormy:
        canvas.drawPath(_cloudPath(), _p);
        // Lightning bolt
        canvas.drawPath(
          Path()
            ..moveTo(13, 16)..lineTo(10, 21)..lineTo(13, 19)..lineTo(11, 24),
          _p,
        );

      case WeatherCondition.snowy:
        canvas.drawPath(_cloudPath(), _p);
        for (final cx in [7.0, 12.0, 17.0]) {
          canvas.drawCircle(Offset(cx, 20), 1.2, _f);
        }

      case WeatherCondition.foggy:
        for (final y in [9.0, 13.0, 17.0]) {
          canvas.drawLine(Offset(4, y), Offset(20, y), _p);
        }

      case WeatherCondition.windy:
        canvas.drawPath(
          Path()..moveTo(2, 9)..quadraticBezierTo(8, 5, 14, 9)..quadraticBezierTo(20, 13, 22, 9),
          _p,
        );
        canvas.drawPath(
          Path()..moveTo(2, 15)..quadraticBezierTo(6, 11, 12, 15)..quadraticBezierTo(18, 19, 22, 15),
          _p,
        );
    }
  }

  Path _cloudPath({double top = 7}) => Path()
    ..moveTo(5, top + 7)
    ..arcToPoint(Offset(7, top + 5), radius: const Radius.circular(2))
    ..arcToPoint(Offset(9, top + 2), radius: const Radius.circular(3), clockwise: false)
    ..arcToPoint(Offset(15, top + 3), radius: const Radius.circular(3.5))
    ..arcToPoint(Offset(18, top + 6), radius: const Radius.circular(3))
    ..arcToPoint(Offset(19, top + 7), radius: const Radius.circular(1.5))
    ..arcToPoint(Offset(5, top + 7), radius: const Radius.circular(2.5), largeArc: true);

  @override
  bool shouldRepaint(_WeatherPainter old) =>
      old.condition != condition || old.color != color;
}
