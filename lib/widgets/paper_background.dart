import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/paper.dart';
import 'package:baka/widgets/motion.dart';

/// Kraft is the one paper with its own colour; the rest are drawn on the
/// page's background.
Color? paperTint(BuildContext context, Paper paper) => paper == Paper.kraft
    ? (Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF33251A)
        : const Color(0xFFE8D9BD))
    : null;

/// [paper] behind [child], filling the parent. With [rule] on, the page is
/// ruled in once on mount (and again when the paper changes): lines run left
/// to right, top to bottom, like a fresh sheet being drawn up.
class PaperBackground extends StatefulWidget {
  final Paper paper;
  final Widget child;
  final bool rule;
  /// Distance between rules, matching the text's line height.
  final double spacing;
  final double topOffset;
  /// Left/right inset of the rules, matching the text's edge.
  final double inset;

  const PaperBackground({
    super.key,
    required this.paper,
    required this.child,
    this.rule = false,
    this.spacing = 29,
    this.topOffset = 16,
    this.inset = 20,
  });

  @override
  State<PaperBackground> createState() => _PaperBackgroundState();
}

class _PaperBackgroundState extends State<PaperBackground>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520), value: 1);
  late final _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.rule) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(PaperBackground old) {
    super.didUpdateWidget(old);
    if (widget.rule && old.paper != widget.paper) _play();
  }

  void _play() {
    if (!mounted || Motion.reduced(context)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t    = context.tokens;
    final tint = paperTint(context, widget.paper);
    final rule = tint == null ? t.rule : Color.lerp(tint, t.onBackground, 0.16)!;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.settle),
      color: tint ?? Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PaperPainter(
                paper: widget.paper,
                rule: rule,
                margin: t.primary.withValues(alpha: 0.45),
                progress: _a,
                spacing: widget.spacing,
                topOffset: widget.topOffset,
                inset: widget.inset,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// The marks of each paper. Also used small, on Home's stacked sheets.
class PaperPainter extends CustomPainter {
  final Paper paper;
  final Color rule, margin;
  final Animation<double>? progress;
  final double spacing, topOffset, inset;
  final double stroke;

  PaperPainter({
    required this.paper,
    required this.rule,
    required this.margin,
    this.progress,
    this.spacing = 29,
    this.topOffset = 16,
    this.inset = 20,
    this.stroke = 0.6,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (paper == Paper.plain) return;
    final p = progress?.value ?? 1;
    if (p <= 0) return;
    final line = Paint()..color = rule..strokeWidth = stroke;
    final rows = <double>[
      for (var y = topOffset + spacing; y < size.height; y += spacing) y,
    ];
    // Each row starts a little after the one above; the last finishes at 1.
    double rowT(int i) {
      const lag = 0.55;
      final start = rows.length <= 1 ? 0.0 : lag * i / (rows.length - 1);
      return ((p - start) / (1 - lag)).clamp(0.0, 1.0);
    }

    final x0 = inset, x1 = size.width - inset;
    switch (paper) {
      case Paper.ruled || Paper.kraft || Paper.margin:
        for (final (i, y) in rows.indexed) {
          final r = rowT(i);
          if (r > 0) canvas.drawLine(Offset(x0, y), Offset(x0 + (x1 - x0) * r, y), line);
        }
        if (paper == Paper.margin) {
          // The red margin is drawn first, top to bottom, as a ruler would.
          final m = (p / 0.5).clamp(0.0, 1.0);
          canvas.drawLine(Offset(inset * 0.6, 0), Offset(inset * 0.6, size.height * m),
              Paint()..color = margin..strokeWidth = stroke * 1.6);
        }
      case Paper.dotted:
        final dot = Paint()..color = rule.withValues(alpha: (rule.a * 1.6).clamp(0, 1));
        final step = spacing * 0.75;
        for (final (i, y) in rows.indexed) {
          final reach = x0 + (x1 - x0) * rowT(i);
          for (var x = x0; x <= reach; x += step) {
            canvas.drawCircle(Offset(x, y), stroke * 1.4, dot);
          }
        }
      case Paper.grid:
        final soft = Paint()..color = rule.withValues(alpha: rule.a * 0.7)..strokeWidth = stroke;
        for (final (i, y) in rows.indexed) {
          final r = rowT(i);
          if (r > 0) canvas.drawLine(Offset(x0, y), Offset(x0 + (x1 - x0) * r, y), soft);
        }
        final top = topOffset + spacing;
        final down = top + (size.height - top) * p;
        for (var x = x0; x <= x1 + 0.5; x += spacing) {
          canvas.drawLine(Offset(x, top), Offset(x, down), soft);
        }
      case Paper.plain:
        break;
    }
  }

  @override
  bool shouldRepaint(PaperPainter o) =>
      o.paper != paper || o.rule != rule || o.margin != margin ||
      o.progress != progress || o.spacing != spacing || o.inset != inset;
}
