import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WordsChart extends StatefulWidget {
  final Map<DateTime, int> wordsPerDay;
  final Color primary;
  final Color muted;

  const WordsChart({
    super.key,
    required this.wordsPerDay,
    required this.primary,
    required this.muted,
  });

  @override
  State<WordsChart> createState() => _WordsChartState();
}

class _WordsChartState extends State<WordsChart> {
  int? _selectedIndex;
  List<_Point> _points = [];

  void _updateSelection(Offset localPos, Size size) {
    final n = _points.length;
    if (n < 2) return;
    final step = size.width / (n - 1);
    final idx  = (localPos.dx / step).round().clamp(0, n - 1);
    if (idx != _selectedIndex) setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final today       = DateTime.now();
    final n           = today.day;

    _points = List.generate(n, (i) {
      final d = DateTime(today.year, today.month, i + 1);
      return _Point(date: d, words: widget.wordsPerDay[d] ?? 0);
    });

    final maxWords    = _points.fold(0, (m, p) => p.words > m ? p.words : m);
    final totalWords  = _points.fold(0, (s, p) => s + p.words);
    final daysWritten = _points.where((p) => p.words > 0).length;
    final avgPerDay   = (totalWords / n).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (_, constraints) {
          final size = Size(constraints.maxWidth, 120);
          return GestureDetector(
            onTapDown:   (d) => _updateSelection(d.localPosition, size),
            onTapUp:     (_) => setState(() => _selectedIndex = null),
            onPanUpdate: (d) => _updateSelection(d.localPosition, size),
            onPanEnd:    (_) => setState(() => _selectedIndex = null),
            child: SizedBox(
              height: 120,
              child: CustomPaint(
                painter: _LinePainter(
                  points: _points,
                  maxWords: maxWords,
                  selectedIndex: _selectedIndex,
                  primary: widget.primary,
                  muted: widget.muted,
                ),
                size: Size.infinite,
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Text(
          'avg $avgPerDay words/day · wrote $daysWritten of $n days this month',
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 13,
            color: widget.muted,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _Point {
  final DateTime date;
  final int words;
  const _Point({required this.date, required this.words});
}

class _LinePainter extends CustomPainter {
  final List<_Point> points;
  final int maxWords;
  final int? selectedIndex;
  final Color primary;
  final Color muted;

  const _LinePainter({
    required this.points,
    required this.maxWords,
    required this.selectedIndex,
    required this.primary,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxWords == 0) {
      canvas.drawLine(
        Offset(0, size.height),
        Offset(size.width, size.height),
        Paint()
          ..color = muted.withValues(alpha: 0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    final n = points.length;
    Offset offsetAt(int i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height - (points[i].words / maxWords) * size.height;
      return Offset(x, y);
    }

    // Smooth bezier path
    final path = Path();
    path.moveTo(offsetAt(0).dx, offsetAt(0).dy);
    for (int i = 0; i < n - 1; i++) {
      final p0  = offsetAt(i);
      final p1  = offsetAt(i + 1);
      final cpx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpx, p0.dy, cpx, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill
    canvas.drawPath(
      Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.22),
            primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Regular dots
    for (int i = 0; i < n; i++) {
      if (points[i].words == 0 || i == selectedIndex) continue;
      final isToday = i == n - 1;
      final o = offsetAt(i);
      if (isToday) {
        canvas.drawCircle(o, 6, Paint()..color = primary.withValues(alpha: 0.25));
        canvas.drawCircle(o, 4, Paint()..color = primary);
        canvas.drawCircle(o, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.95));
      } else {
        canvas.drawCircle(o, 3, Paint()..color = primary);
        canvas.drawCircle(o, 1.8, Paint()..color = Colors.white.withValues(alpha: 0.9));
      }
    }

    // Selected point + tooltip
    if (selectedIndex != null) {
      final si = selectedIndex!;
      final o  = offsetAt(si);
      final pt = points[si];

      // Vertical hairline
      canvas.drawLine(
        Offset(o.dx, 0),
        Offset(o.dx, size.height),
        Paint()
          ..color = muted.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );

      // Highlighted dot
      canvas.drawCircle(o, 6, Paint()..color = primary.withValues(alpha: 0.25));
      canvas.drawCircle(o, 4, Paint()..color = primary);
      canvas.drawCircle(o, 2.2, Paint()..color = Colors.white.withValues(alpha: 0.95));

      // Tooltip bubble
      final label = '${DateFormat('d MMM').format(pt.date)} · ${pt.words} words';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      const pad    = 6.0;
      const radius = 6.0;
      final bw     = tp.width + pad * 2;
      final bh     = tp.height + pad * 2;

      // Position bubble above dot, clamp to canvas edges
      double bx = o.dx - bw / 2;
      bx = bx.clamp(0.0, size.width - bw).toDouble();
      final by = (o.dy - bh - 10).clamp(0.0, size.height - bh).toDouble();

      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(radius),
      );

      canvas.drawRRect(bubbleRect,
          Paint()..color = primary.withValues(alpha: 0.92));
      tp.paint(canvas, Offset(bx + pad, by + pad));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.maxWords != maxWords ||
      old.selectedIndex != selectedIndex ||
      old.primary != primary;
}
