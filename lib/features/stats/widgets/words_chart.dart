import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';

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
    final t           = context.tokens;
    final axisStyle   = AppText.micro(context).copyWith(
        color: widget.muted,
      );

    // Nothing written this month: a calm note instead of a flat line.
    if (maxWords == 0) {
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.outlineSoft)),
        ),
        child: Text(
          'No words yet this month.\nYour next entry starts the line.',
          textAlign: TextAlign.center,
          style: AppText.label(context).copyWith(
              height: 1.5,
              color: widget.muted,
            ),
        ),
      );
    }

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
                  background: t.background,
                  labelBg: t.primaryContainer,
                  labelFg: t.onPrimaryContainer,
                  bodyFamily: context.fonts.body,
                ),
                size: Size.infinite,
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        // Date axis: first day, middle, today
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (n > 1)
              Text(DateFormat('MMM d').format(_points.first.date), style: axisStyle),
            if (n > 2)
              Text(DateFormat('MMM d').format(_points[n ~/ 2].date), style: axisStyle),
            Text('Today', style: axisStyle),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Wrote on $daysWritten of $n days · $avgPerDay ${avgPerDay == 1 ? 'word' : 'words'} a day on average',
          style: AppText.meta(context).copyWith(
              color: widget.muted,
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
  final Color background;
  final Color labelBg;
  final Color labelFg;

  /// A painter has no BuildContext, so the resolved family is passed in.
  final String bodyFamily;

  const _LinePainter({
    required this.points,
    required this.maxWords,
    required this.selectedIndex,
    required this.primary,
    required this.muted,
    required this.background,
    required this.labelBg,
    required this.labelFg,
    required this.bodyFamily,
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
    // Leave headroom so the peak dot and its label never clip.
    const top = 8.0;
    final h = size.height - top;
    Offset offsetAt(int i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final y = size.height - (points[i].words / maxWords) * h;
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
            primary.withValues(alpha: 0.25),
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
        canvas.drawCircle(o, 2.2, Paint()..color = background);
      } else {
        canvas.drawCircle(o, 3, Paint()..color = primary);
        canvas.drawCircle(o, 1.8, Paint()..color = background);
      }
    }

    // With nothing selected, label the best day so a lone spike reads as a
    // real day rather than a glitch.
    if (selectedIndex == null) {
      var peak = 0;
      for (int i = 1; i < n; i++) {
        if (points[i].words > points[peak].words) peak = i;
      }
      _drawLabel(canvas, size, offsetAt(peak), points[peak]);
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
      canvas.drawCircle(o, 2.2, Paint()..color = background);
      _drawLabel(canvas, size, o, pt);
    }
  }

  /// Small pill ("Oct 23 · 172 words") beside a point, clamped to the canvas.
  void _drawLabel(Canvas canvas, Size size, Offset o, _Point pt) {
    final tp = TextPainter(
      text: TextSpan(
        text: '${DateFormat('MMM d').format(pt.date)} · ${pt.words} words',
        style: TextStyle(
          fontFamily: bodyFamily,
          fontSize: 11,
          color: labelFg,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const padH = 6.0;
    const padV = 3.0;
    final bw = tp.width + padH * 2;
    final bh = tp.height + padV * 2;

    // Prefer the left of the point (peaks tend to sit near "today"), else right.
    double bx = o.dx - bw - 10;
    if (bx < 0) bx = o.dx + 10;
    bx = bx.clamp(0.0, size.width - bw).toDouble();
    final by = (o.dy - bh / 2).clamp(0.0, size.height - bh).toDouble();

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(6)),
      Paint()..color = labelBg,
    );
    tp.paint(canvas, Offset(bx + padH, by + padV));
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.maxWords != maxWords ||
      old.selectedIndex != selectedIndex ||
      old.primary != primary ||
      old.background != background ||
      old.bodyFamily != bodyFamily;
}
