import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/app_icon.dart' show parseSvgPath;
import 'package:baka/widgets/motion.dart';

/// Pen-and-ink drawings for empty states. Each is a list of strokes in pen
/// order; accent strokes take the terracotta ink.
enum Doodle { notebook, voice, tag, missingPage }

class _Stroke {
  final String d;
  final bool accent;
  final bool fill;
  const _Stroke(this.d, {this.accent = false, this.fill = false});
}

const _strokes = <Doodle, List<_Stroke>>{
  // viewBox 210 × 170: open notebook, ruled lines, quill with an ink drop.
  Doodle.notebook: [
    _Stroke('M20 70Q60 58 100 70L100 150Q60 138 20 150Z'),
    _Stroke('M100 70Q140 58 180 70L180 150Q140 138 100 150'),
    _Stroke('M34 90Q60 84 86 90M34 106Q60 100 86 106M34 122Q55 117 76 122'),
    _Stroke('M114 90Q140 84 166 90M114 106Q135 101 156 106'),
    _Stroke('M196 16Q170 22 150 44Q138 60 128 92M196 16Q192 38 170 52Q156 60 140 66M178 26L162 40M186 32L168 46',
        accent: true),
    _Stroke('M124 101a3 3 0 1 0 0 6a3 3 0 1 0 0-6', accent: true, fill: true),
  ],
  // viewBox 148 × 120: a hand-drawn sound wave between two ink dots.
  Doodle.voice: [
    _Stroke('M14 60Q24 30 34 60T54 60T74 60T94 60T114 60T134 60'),
    _Stroke('M34 84Q74 96 114 84', accent: true),
  ],
  // viewBox 148 × 120: a luggage tag on a loose string.
  Doodle.tag: [
    _Stroke('M30 40L90 40L120 70L90 100L30 100Z'),
    _Stroke('M48 64a6 6 0 1 0 0 12a6 6 0 1 0 0-12'),
    _Stroke('M42 70Q20 60 14 30', accent: true),
  ],
  // viewBox 148 × 120: a page torn off at the bottom.
  Doodle.missingPage: [
    _Stroke('M30 20L110 20L110 90L100 96L92 88L82 98L72 88L62 98L52 88L42 98L30 90Z'),
    _Stroke('M44 40H96M44 54H90M44 68H70', accent: true),
  ],
};

const _viewBox = <Doodle, Size>{
  Doodle.notebook: Size(210, 170),
  Doodle.voice: Size(148, 120),
  Doodle.tag: Size(148, 120),
  Doodle.missingPage: Size(148, 120),
};

/// Draws [doodle] stroke by stroke, like a pen tracing it, once per mount.
/// With reduce-motion on it simply appears complete.
class InkDoodle extends StatefulWidget {
  final Doodle doodle;
  final double width;
  final Duration duration;
  const InkDoodle(this.doodle,
      {super.key, this.width = 160, this.duration = const Duration(milliseconds: 1200)});

  @override
  State<InkDoodle> createState() => _InkDoodleState();
}

class _InkDoodleState extends State<InkDoodle>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final _a = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    Motion.reduced(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t  = context.tokens;
    final vb = _viewBox[widget.doodle]!;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.width * vb.height / vb.width,
        child: CustomPaint(
          painter: _DoodlePainter(
            doodle: widget.doodle,
            progress: _a,
            ink: t.onSurface,
            accent: t.primary,
          ),
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final Doodle doodle;
  final Animation<double> progress;
  final Color ink, accent;
  _DoodlePainter({
    required this.doodle,
    required this.progress,
    required this.ink,
    required this.accent,
  }) : super(repaint: progress);

  static final _cache = <Doodle, List<(ui.Path, _Stroke, double)>>{};

  List<(ui.Path, _Stroke, double)> get _parsed => _cache.putIfAbsent(doodle, () => [
        for (final s in _strokes[doodle]!)
          () {
            final p = parseSvgPath(s.d);
            final len = p.computeMetrics().fold<double>(0, (a, m) => a + m.length);
            return (p, s, len);
          }(),
      ]);

  @override
  void paint(Canvas canvas, Size size) {
    final vb = _viewBox[doodle]!;
    canvas
      ..save()
      ..scale(size.width / vb.width);

    final strokes = _parsed;
    final total = strokes.fold<double>(0, (a, s) => a + s.$3);
    var budget = total * progress.value;

    for (final (path, stroke, len) in strokes) {
      if (budget <= 0) break;
      final color = stroke.accent ? accent : ink;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (budget >= len) {
        canvas.drawPath(path, paint);
        if (stroke.fill) canvas.drawPath(path, Paint()..color = color);
      } else {
        // Trace this stroke up to the pen's current position.
        var left = budget;
        for (final m in path.computeMetrics()) {
          if (left <= 0) break;
          canvas.drawPath(m.extractPath(0, left.clamp(0, m.length)), paint);
          left -= m.length;
        }
      }
      budget -= len;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoodlePainter o) =>
      o.doodle != doodle || o.ink != ink || o.accent != accent;
}
