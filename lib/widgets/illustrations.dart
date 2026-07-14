import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:baka/models/mood.dart';
import 'package:baka/core/fonts/font_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Flame  (viewBox 0 0 24 24) — streak icon, matches MoodGlyph design language
// ─────────────────────────────────────────────────────────────────────────────

class FlameIcon extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  const FlameIcon({
    super.key,
    this.width = 16,
    this.height = 20,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, height),
        painter: _FlamePainter(color),
      );
}

class _FlamePainter extends CustomPainter {
  final Color color;
  _FlamePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 24, size.height / 24);
    canvas
      ..save()
      ..translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2)
      ..scale(s);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer flame
    final outer = Path()
      ..moveTo(12, 21)
      ..cubicTo(6, 21, 3, 17, 3, 13)
      ..cubicTo(3, 9, 6, 7, 8, 5)
      ..cubicTo(8, 8, 10, 9, 10, 9)
      ..cubicTo(10, 6, 12, 3, 14, 2)
      ..cubicTo(14, 6, 16, 7, 17, 9)
      ..cubicTo(19, 7, 20, 5, 20, 5)
      ..cubicTo(21, 8, 21, 11, 21, 13)
      ..cubicTo(21, 17, 18, 21, 12, 21)
      ..close();
    canvas.drawPath(outer, stroke);

    // Inner teardrop — warmth detail
    final inner = Path()
      ..moveTo(12, 18)
      ..cubicTo(9.5, 18, 8, 16, 8, 14)
      ..cubicTo(8, 12, 10, 11, 12, 10)
      ..cubicTo(14, 11, 16, 12, 16, 14)
      ..cubicTo(16, 16, 14.5, 18, 12, 18)
      ..close();
    canvas.drawPath(inner, stroke..strokeWidth = 1.25);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quill  (viewBox 0 0 120 120)
// ─────────────────────────────────────────────────────────────────────────────

class QuillIcon extends StatelessWidget {
  final double size;
  final Color color;
  const QuillIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _QuillPainter(color: color),
      );
}

class _QuillPainter extends CustomPainter {
  final Color color;
  const _QuillPainter({required this.color});

  static const _vw = 120.0, _vh = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vw, size.height / _vh);
    canvas
      ..save()
      ..translate((size.width - _vw * s) / 2, (size.height - _vh * s) / 2)
      ..scale(s);
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas canvas) {
    final barb = Paint()
      ..color = color.withValues(alpha:0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left barbs
    for (final p in _leftBarbs) {
      canvas.drawPath(p, barb);
    }
    // Right barbs
    for (final p in _rightBarbs) {
      canvas.drawPath(p, barb);
    }

    // Shaft
    canvas.drawPath(
      Path()..moveTo(30, 24)..quadraticBezierTo(50, 50, 90, 96),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Nib (filled)
    canvas.drawPath(
      Path()..moveTo(88, 94)..lineTo(98, 104)..lineTo(92, 108)..close(),
      Paint()..color = color.withValues(alpha:0.9)..style = PaintingStyle.fill,
    );

    // Ink dot
    canvas.drawCircle(
      const Offset(100, 108), 1.6,
      Paint()..color = color.withValues(alpha:0.7)..style = PaintingStyle.fill,
    );
  }

  static final _leftBarbs = [
    Path()..moveTo(28, 28)..quadraticBezierTo(38, 24, 48, 30),
    Path()..moveTo(30, 36)..quadraticBezierTo(40, 32, 50, 38),
    Path()..moveTo(32, 44)..quadraticBezierTo(42, 40, 52, 46),
    Path()..moveTo(34, 52)..quadraticBezierTo(44, 48, 54, 54),
    Path()..moveTo(36, 60)..quadraticBezierTo(46, 56, 56, 62),
    Path()..moveTo(38, 68)..quadraticBezierTo(48, 64, 58, 70),
    Path()..moveTo(40, 76)..quadraticBezierTo(50, 72, 60, 78),
    Path()..moveTo(44, 84)..quadraticBezierTo(54, 80, 64, 86),
  ];

  static final _rightBarbs = [
    Path()..moveTo(52, 22)..quadraticBezierTo(60, 20, 68, 26),
    Path()..moveTo(54, 30)..quadraticBezierTo(62, 28, 70, 34),
    Path()..moveTo(56, 38)..quadraticBezierTo(64, 36, 72, 42),
    Path()..moveTo(58, 46)..quadraticBezierTo(66, 44, 74, 50),
    Path()..moveTo(60, 54)..quadraticBezierTo(68, 52, 76, 58),
    Path()..moveTo(62, 62)..quadraticBezierTo(70, 60, 78, 66),
    Path()..moveTo(64, 70)..quadraticBezierTo(72, 68, 80, 74),
    Path()..moveTo(66, 78)..quadraticBezierTo(74, 76, 82, 82),
  ];

  @override
  bool shouldRepaint(_QuillPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Fingerprint  (viewBox 0 0 64 64)
// ─────────────────────────────────────────────────────────────────────────────

class FingerprintIcon extends StatelessWidget {
  final double size;
  final Color color;
  const FingerprintIcon({super.key, this.size = 64, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _FingerprintPainter(color: color),
      );
}

class _FingerprintPainter extends CustomPainter {
  final Color color;
  const _FingerprintPainter({required this.color});

  static const _vw = 64.0, _vh = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vw, size.height / _vh);
    canvas
      ..save()
      ..translate((size.width - _vw * s) / 2, (size.height - _vh * s) / 2)
      ..scale(s);

    final p = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final path in _paths) {
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  static final _paths = [
    // Outermost arch
    Path()
      ..moveTo(16, 28)
      ..cubicTo(16, 18, 24, 12, 32, 12)
      ..cubicTo(40, 12, 48, 18, 48, 28),
    // Second ring
    Path()
      ..moveTo(20, 36)
      ..cubicTo(20, 22, 26, 18, 32, 18)
      ..cubicTo(38, 18, 44, 22, 44, 32)
      ..cubicTo(44, 38, 43, 44, 42, 50),
    // Third ring
    Path()
      ..moveTo(24, 38)
      ..cubicTo(24, 28, 28, 24, 32, 24)
      ..cubicTo(36, 24, 40, 28, 40, 34)
      ..cubicTo(40, 42, 38, 46, 36, 52),
    // Fourth ring
    Path()
      ..moveTo(28, 40)
      ..cubicTo(28, 34, 30, 30, 32, 30)
      ..cubicTo(34, 30, 36, 32, 36, 36)
      ..cubicTo(36, 42, 35, 46, 32, 54),
    // Centre swirl tail
    Path()
      ..moveTo(32, 36)
      ..cubicTo(32, 40, 31, 46, 28, 52),
    // Left outer break
    Path()
      ..moveTo(14, 38)
      ..cubicTo(14, 36, 14, 34, 15, 32),
    // Right outer break
    Path()
      ..moveTo(50, 38)
      ..cubicTo(50, 36, 50, 34, 49, 32),
  ];

  @override
  bool shouldRepaint(_FingerprintPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Inkwell  (viewBox 0 0 80 80)
// ─────────────────────────────────────────────────────────────────────────────

class InkwellIcon extends StatelessWidget {
  final double size;
  final Color color;
  const InkwellIcon({super.key, this.size = 80, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _InkwellPainter(color: color),
      );
}

class _InkwellPainter extends CustomPainter {
  final Color color;
  const _InkwellPainter({required this.color});

  static const _vw = 80.0, _vh = 80.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vw, size.height / _vh);
    canvas
      ..save()
      ..translate((size.width - _vw * s) / 2, (size.height - _vh * s) / 2)
      ..scale(s);
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas canvas) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shadow ellipse
    canvas.drawOval(
      const Rect.fromLTWH(18, 57, 44, 10),
      Paint()..color = color.withValues(alpha:0.4)..style = PaintingStyle.fill,
    );
    // Bottle body
    canvas.drawPath(
      Path()
        ..moveTo(22, 38)..lineTo(22, 58)
        ..cubicTo(22, 64, 22, 64, 28, 64)
        ..lineTo(52, 64)
        ..cubicTo(58, 64, 58, 64, 58, 58)
        ..lineTo(58, 38)..close(),
      stroke,
    );
    // Neck
    canvas.drawPath(
      Path()
        ..moveTo(30, 30)..lineTo(30, 38)
        ..lineTo(50, 38)..lineTo(50, 30)..close(),
      stroke,
    );
    // Cap rim
    canvas.drawLine(
      const Offset(27, 30), const Offset(53, 30),
      stroke..strokeWidth = 2,
    );
    // Ink fill
    canvas.drawPath(
      Path()
        ..moveTo(24, 48)
        ..quadraticBezierTo(40, 44, 56, 48)
        ..lineTo(56, 58)
        ..cubicTo(56, 62, 56, 62, 52, 62)
        ..lineTo(28, 62)
        ..cubicTo(24, 62, 24, 62, 24, 58)..close(),
      Paint()..color = color.withValues(alpha:0.7)..style = PaintingStyle.fill,
    );
    // Feather shaft
    canvas.drawPath(
      Path()..moveTo(40, 30)..quadraticBezierTo(52, 14, 64, 8),
      Paint()
        ..color = color
        ..strokeWidth = 1.75
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    // Feather barbs
    final barbPaint = Paint()
      ..color = color.withValues(alpha:0.7)
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(48, 18)..quadraticBezierTo(54, 14, 58, 14), barbPaint);
    canvas.drawPath(Path()..moveTo(52, 22)..quadraticBezierTo(58, 18, 62, 18), barbPaint);
    canvas.drawPath(Path()..moveTo(44, 24)..quadraticBezierTo(50, 20, 54, 20), barbPaint);
  }

  @override
  bool shouldRepaint(_InkwellPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// WaxSeal  (viewBox 0 0 130 130)
// ─────────────────────────────────────────────────────────────────────────────

class WaxSealIcon extends StatelessWidget {
  final double size;
  final Color color;
  const WaxSealIcon({super.key, this.size = 130, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _WaxSealPainter(color: color),
      );
}

class _WaxSealPainter extends CustomPainter {
  final Color color;
  const _WaxSealPainter({required this.color});

  static const _vw = 130.0, _vh = 130.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vw, size.height / _vh);
    canvas
      ..save()
      ..translate((size.width - _vw * s) / 2, (size.height - _vh * s) / 2)
      ..scale(s);
    _draw(canvas);
    canvas.restore();
  }

  void _draw(Canvas canvas) {
    // Blob fill (radial gradient approximated with two paints)
    final blobPath = Path()
      ..moveTo(65, 12)
      ..cubicTo(86, 14, 110, 30, 112, 56)
      ..cubicTo(114, 78, 100, 96, 96, 102)
      ..cubicTo(100, 112, 92, 120, 84, 116)
      ..cubicTo(78, 120, 70, 118, 65, 114)
      ..cubicTo(58, 120, 48, 118, 42, 112)
      ..cubicTo(32, 118, 22, 110, 24, 100)
      ..cubicTo(14, 92, 12, 76, 18, 60)
      ..cubicTo(22, 38, 44, 16, 65, 12)
      ..close();

    canvas.drawPath(
      blobPath,
      Paint()..color = color.withValues(alpha:0.78)..style = PaintingStyle.fill,
    );

    // Inner ring
    canvas.drawCircle(
      const Offset(65, 62), 32,
      Paint()
        ..color = color.withValues(alpha:0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Monogram "B" (simplified from "J" in design — adapt to app)
    canvas.drawPath(
      Path()
        ..moveTo(58, 44)..lineTo(58, 80)
        ..moveTo(58, 44)
        ..cubicTo(66, 44, 72, 48, 72, 54)
        ..cubicTo(72, 60, 66, 63, 58, 63)
        ..moveTo(58, 63)
        ..cubicTo(67, 63, 74, 67, 74, 74)
        ..cubicTo(74, 80, 67, 83, 58, 83),
      Paint()
        ..color = Colors.white.withValues(alpha:0.85)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Sheen ellipse
    canvas.save();
    canvas.translate(48, 42);
    canvas.rotate(-30 * math.pi / 180);
    canvas.drawOval(
      const Rect.fromLTWH(-14, -7, 28, 14),
      Paint()..color = Colors.white.withValues(alpha:0.18)..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WaxSealPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Folded Letter  (viewBox 0 0 24 24)
// ─────────────────────────────────────────────────────────────────────────────

class FoldedLetterIcon extends StatelessWidget {
  final double size;
  final Color color;
  const FoldedLetterIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _FoldedLetterPainter(color: color),
      );
}

class _FoldedLetterPainter extends CustomPainter {
  final Color color;
  const _FoldedLetterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 24, size.height / 24);
    canvas
      ..save()
      ..translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2)
      ..scale(s);

    final p = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Envelope rect
    canvas.drawPath(
      Path()..moveTo(3, 7)..lineTo(21, 7)..lineTo(21, 19)..lineTo(3, 19)..close(),
      p,
    );
    // Flap crease
    canvas.drawPath(
      Path()..moveTo(3, 7)..lineTo(12, 14)..lineTo(21, 7),
      p,
    );
    // Bottom fold lines
    canvas.drawPath(Path()..moveTo(3, 19)..lineTo(9, 13),
        p..color = color.withValues(alpha:0.7)..strokeWidth = 1.5);
    canvas.drawPath(Path()..moveTo(21, 19)..lineTo(15, 13),
        p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FoldedLetterPainter o) => o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// MoodGlyph  (viewBox 0 0 24 24)
// ─────────────────────────────────────────────────────────────────────────────

class MoodGlyph extends StatelessWidget {
  final Mood mood;
  final double size;
  final Color color;

  const MoodGlyph({
    super.key,
    required this.mood,
    this.size = 22,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _MoodGlyphPainter(mood: mood, color: color),
      );
}

class _MoodGlyphPainter extends CustomPainter {
  final Mood mood;
  final Color color;
  const _MoodGlyphPainter({required this.mood, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 24, size.height / 24);
    canvas
      ..save()
      ..translate((size.width - 24 * s) / 2, (size.height - 24 * s) / 2)
      ..scale(s);
    _drawMood(canvas);
    canvas.restore();
  }

  void _drawMood(Canvas canvas) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (mood) {
      case Mood.happy:
        canvas.drawCircle(const Offset(9, 10), 0.7, dot);
        canvas.drawCircle(const Offset(15, 10), 0.7, dot);
        canvas.drawPath(
          Path()..moveTo(7.5, 14)..quadraticBezierTo(12, 18, 16.5, 14),
          stroke,
        );

      case Mood.calm:
        canvas.drawLine(const Offset(7, 10), const Offset(9, 10), stroke);
        canvas.drawLine(const Offset(15, 10), const Offset(17, 10), stroke);
        canvas.drawPath(
          Path()..moveTo(8, 14)..quadraticBezierTo(12, 16, 16, 14),
          stroke,
        );

      case Mood.thoughtful:
        canvas.drawPath(
          Path()
            ..moveTo(9, 9)..quadraticBezierTo(11, 5, 14, 7)
            ..quadraticBezierTo(16, 10, 12, 12)
            ..lineTo(12, 14),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 17.5), 0.8, dot);

      case Mood.sad:
        canvas.drawCircle(const Offset(9, 10), 0.7, dot);
        canvas.drawCircle(const Offset(15, 10), 0.7, dot);
        canvas.drawPath(
          Path()..moveTo(7.5, 16)..quadraticBezierTo(12, 12, 16.5, 16),
          stroke,
        );

      case Mood.tired:
        canvas.drawPath(
          Path()..moveTo(6.5, 11)..quadraticBezierTo(9, 13, 11.5, 11),
          stroke,
        );
        canvas.drawPath(
          Path()..moveTo(12.5, 11)..quadraticBezierTo(15, 13, 17.5, 11),
          stroke,
        );
        canvas.drawLine(const Offset(8, 15), const Offset(16, 15), stroke);

      case Mood.anxious:
        canvas.drawPath(
          Path()
            ..moveTo(5, 13)..lineTo(8, 10)..lineTo(11, 13)
            ..lineTo(14, 10)..lineTo(17, 13)..lineTo(19, 11),
          stroke,
        );

      case Mood.excited:
        for (final pair in [
          [12.0, 4.0, 12.0, 8.0], [12.0, 16.0, 12.0, 20.0],
          [4.0, 12.0, 8.0, 12.0], [16.0, 12.0, 20.0, 12.0],
          [6.3, 6.3, 8.8, 8.8], [15.2, 15.2, 17.7, 17.7],
          [17.7, 6.3, 15.2, 8.8], [8.8, 15.2, 6.3, 17.7],
        ]) {
          canvas.drawLine(Offset(pair[0], pair[1]), Offset(pair[2], pair[3]), stroke);
        }

      case Mood.loved:
        canvas.drawPath(
          Path()
            ..moveTo(12, 18.5)
            ..cubicTo(7.5, 15, 4.5, 12, 4.5, 9)
            ..arcToPoint(const Offset(12, 7.5),
                radius: const Radius.circular(3.3), clockwise: true)
            ..arcToPoint(const Offset(19.5, 9),
                radius: const Radius.circular(3.3), clockwise: true)
            ..cubicTo(19.5, 12, 16.5, 15, 12, 18.5)..close(),
          stroke,
        );

      case Mood.angry:
        canvas.drawLine(const Offset(6, 8), const Offset(10, 10), stroke);
        canvas.drawLine(const Offset(18, 8), const Offset(14, 10), stroke);
        canvas.drawPath(
          Path()..moveTo(8, 16)..quadraticBezierTo(12, 14, 16, 16),
          stroke,
        );

      case Mood.crying:
        canvas.drawCircle(const Offset(9, 10), 0.7, dot);
        canvas.drawCircle(const Offset(15, 10), 0.7, dot);
        canvas.drawPath(
          Path()..moveTo(7.5, 16)..quadraticBezierTo(12, 12, 16.5, 16),
          stroke,
        );
        // Teardrop
        canvas.drawPath(
          Path()
            ..moveTo(8, 13)..quadraticBezierTo(9, 16, 8, 17.5)
            ..quadraticBezierTo(7, 16, 8, 13)..close(),
          Paint()..color = color.withValues(alpha:0.4)..style = PaintingStyle.fill,
        );
    }
  }

  @override
  bool shouldRepaint(_MoodGlyphPainter o) =>
      o.mood != mood || o.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Wordmark  — "Baka" in Caveat + wavy underline + dot
// ─────────────────────────────────────────────────────────────────────────────

class WordmarkWidget extends StatelessWidget {
  final double fontSize;
  final Color color;

  const WordmarkWidget({super.key, this.fontSize = 40, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Baka',
          style: TextStyle(fontFamily: kWordmarkFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            height: 0.95,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: CustomPaint(
            size: Size(fontSize * 1.35, fontSize * 0.22),
            painter: _WordmarkUnderlinePainter(color: color, fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

class _WordmarkUnderlinePainter extends CustomPainter {
  final Color color;
  final double fontSize;
  const _WordmarkUnderlinePainter({required this.color, required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = math.max(1.5, fontSize * 0.03);

    // Gentle two-hump wave — visible but not dramatic.
    final path = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.28, h * 0.05, w * 0.54, h * 0.55)
      ..quadraticBezierTo(w * 0.80, h * 1.00, w * 0.95, h * 0.55);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Dot after the wave tail
    canvas.drawCircle(
      Offset(w * 0.95 + sw * 2.5, h * 0.55),
      sw,
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_WordmarkUnderlinePainter o) =>
      o.color != color || o.fontSize != fontSize;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppIcon — all custom 24×24 stroke icons
// ─────────────────────────────────────────────────────────────────────────────

enum AppIconData {
  back, search, sun, moon, chevronRight,
  bell, lock, share, download, check,
  clock, typeIcon, calendar, book, stats, cog, pencil,
}

class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double size;
  final Color color;
  const AppIcon(this.icon, {super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _AppIconPainter(icon: icon, color: color),
      );
}

class _AppIconPainter extends CustomPainter {
  final AppIconData icon;
  final Color color;
  const _AppIconPainter({required this.icon, required this.color});

  static const _vb = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _vb, size.height / _vb);
    canvas
      ..save()
      ..translate((size.width - _vb * s) / 2, (size.height - _vb * s) / 2)
      ..scale(s);
    _draw(canvas);
    canvas.restore();
  }

  Paint get _stroke => Paint()
    ..color = color
    ..strokeWidth = 1.75
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _fill => Paint()..color = color..style = PaintingStyle.fill;

  void _draw(Canvas canvas) {
    final p = _stroke;
    switch (icon) {
      case AppIconData.back:
        canvas.drawPath(
          Path()..moveTo(15, 6)..lineTo(9, 12)..lineTo(15, 18), p);

      case AppIconData.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 6.5, p);
        canvas.drawPath(Path()..moveTo(20, 20)..lineTo(15.5, 15.5), p);

      case AppIconData.sun:
        canvas.drawCircle(const Offset(12, 12), 4, p);
        for (final seg in [
          [12.0,2.0,12.0,4.0], [12.0,20.0,12.0,22.0],
          [2.0,12.0,4.0,12.0], [20.0,12.0,22.0,12.0],
          [4.93,4.93,6.34,6.34], [17.66,17.66,19.07,19.07],
          [4.93,19.07,6.34,17.66], [17.66,6.34,19.07,4.93],
        ]) {
          canvas.drawLine(Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), p);
        }

      case AppIconData.moon:
        canvas.drawPath(
          Path()
            ..moveTo(20, 14.5)
            ..arcToPoint(const Offset(9.5, 4),
                radius: const Radius.circular(8), clockwise: true)
            ..arcToPoint(const Offset(20, 14.5),
                radius: const Radius.circular(8),
                largeArc: true,
                clockwise: false)
            ..close(),
          p,
        );

      case AppIconData.chevronRight:
        canvas.drawPath(
          Path()..moveTo(9, 6)..lineTo(15, 12)..lineTo(9, 18), p);

      case AppIconData.bell:
        canvas.drawPath(
          Path()
            ..moveTo(6, 16)..lineTo(6, 11)
            ..arcToPoint(const Offset(18, 11),
                radius: const Radius.circular(6), clockwise: true)
            ..lineTo(18, 16)
            ..lineTo(19.5, 18.5)
            ..lineTo(4.5, 18.5)..close(),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..arcToPoint(const Offset(14, 20),
                radius: const Radius.circular(2), clockwise: false),
          p,
        );

      case AppIconData.lock:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(5, 11, 14, 10), const Radius.circular(2)),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 11)..lineTo(8, 7)
            ..arcToPoint(const Offset(16, 7),
                radius: const Radius.circular(4), clockwise: true)
            ..lineTo(16, 11),
          p,
        );

      case AppIconData.share:
        canvas.drawPath(Path()..moveTo(12, 3)..lineTo(12, 15), p);
        canvas.drawPath(
          Path()..moveTo(8, 7)..lineTo(12, 3)..lineTo(16, 7), p);
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)..lineTo(5, 19)
            ..arcToPoint(const Offset(7, 21),
                radius: const Radius.circular(2), clockwise: true)
            ..lineTo(17, 21)
            ..arcToPoint(const Offset(19, 19),
                radius: const Radius.circular(2), clockwise: true)
            ..lineTo(19, 12),
          p,
        );

      case AppIconData.download:
        canvas.drawPath(Path()..moveTo(12, 3)..lineTo(12, 15), p);
        canvas.drawPath(
          Path()..moveTo(8, 11)..lineTo(12, 15)..lineTo(16, 11), p);
        canvas.drawPath(Path()..moveTo(5, 21)..lineTo(19, 21), p);

      case AppIconData.check:
        canvas.drawPath(
          Path()..moveTo(5, 12)..lineTo(10, 17)..lineTo(19, 6),
          p..strokeWidth = 2.25,
        );

      case AppIconData.clock:
        canvas.drawCircle(const Offset(12, 12), 9, p..strokeWidth = 1.75);
        canvas.drawPath(
          Path()..moveTo(12, 7)..lineTo(12, 12)..lineTo(15, 14), p);

      case AppIconData.typeIcon:
        canvas.drawPath(
          Path()..moveTo(5, 7)..lineTo(5, 5)..lineTo(19, 5)..lineTo(19, 7),
          p,
        );
        canvas.drawPath(Path()..moveTo(12, 5)..lineTo(12, 19), p);
        canvas.drawPath(Path()..moveTo(9, 19)..lineTo(15, 19), p);

      case AppIconData.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(3.5, 5, 17, 15), const Radius.circular(2.5)),
          p,
        );
        canvas.drawLine(
            const Offset(3.5, 10), const Offset(20.5, 10), p);
        canvas.drawPath(Path()..moveTo(8, 3)..lineTo(8, 7), p);
        canvas.drawPath(Path()..moveTo(16, 3)..lineTo(16, 7), p);
        for (final pt in [
          const Offset(8, 14.5), const Offset(12, 14.5),
          const Offset(16, 14.5), const Offset(8, 17.5),
          const Offset(12, 17.5),
        ]) {
          canvas.drawCircle(pt, 0.6, _fill);
        }

      case AppIconData.book:
        final dim = p..strokeWidth = 1.75;
        // Left page
        canvas.drawPath(
          Path()
            ..moveTo(4, 5)..quadraticBezierTo(4, 4, 5, 4)
            ..lineTo(11, 4)..quadraticBezierTo(12, 4, 12, 5)
            ..lineTo(12, 20)..quadraticBezierTo(12, 19, 11, 19)
            ..lineTo(5, 19)..quadraticBezierTo(4, 19, 4, 20)..close(),
          dim,
        );
        // Right page
        canvas.drawPath(
          Path()
            ..moveTo(20, 5)..quadraticBezierTo(20, 4, 19, 4)
            ..lineTo(13, 4)..quadraticBezierTo(12, 4, 12, 5)
            ..lineTo(12, 20)..quadraticBezierTo(12, 19, 13, 19)
            ..lineTo(19, 19)..quadraticBezierTo(20, 19, 20, 20)..close(),
          dim,
        );
        // Text lines
        final linePaint = Paint()
          ..color = color.withValues(alpha:0.7)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        for (final seg in [
          [6.5, 8.0, 9.5, 8.0], [6.5, 11.0, 9.5, 11.0],
          [14.5, 8.0, 17.5, 8.0], [14.5, 11.0, 17.5, 11.0],
        ]) {
          canvas.drawLine(
              Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), linePaint);
        }

      case AppIconData.stats:
        for (final rect in [
          const Rect.fromLTWH(4, 12, 3.5, 8),
          const Rect.fromLTWH(10.25, 7, 3.5, 13),
          const Rect.fromLTWH(16.5, 4, 3.5, 16),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(1)), p);
        }

      case AppIconData.cog:
        canvas.drawCircle(const Offset(12, 12), 3, p);
        for (final seg in [
          [12.0,2.0,12.0,5.0], [12.0,19.0,12.0,22.0],
          [2.0,12.0,5.0,12.0], [19.0,12.0,22.0,12.0],
          [5.0,5.0,7.0,7.0], [17.0,17.0,19.0,19.0],
          [19.0,5.0,17.0,7.0], [7.0,17.0,5.0,19.0],
        ]) {
          canvas.drawLine(Offset(seg[0], seg[1]), Offset(seg[2], seg[3]), p);
        }

      case AppIconData.pencil:
        canvas.drawPath(
          Path()
            ..moveTo(4, 20)..lineTo(4, 17)..lineTo(16, 5)
            ..lineTo(19, 8)..lineTo(7, 20)..close(),
          p,
        );
        canvas.drawPath(Path()..moveTo(13, 8)..lineTo(16, 11), p);
    }
  }

  @override
  bool shouldRepaint(_AppIconPainter o) => o.icon != icon || o.color != color;
}
