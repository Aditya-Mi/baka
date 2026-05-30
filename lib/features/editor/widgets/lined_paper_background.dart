import 'package:flutter/material.dart';

/// Draws faint horizontal ruled lines behind [child].
/// Matches the "lined" class from the design — body textarea background.
class LinedPaperBackground extends StatelessWidget {
  final Widget child;
  final Color ruleColor;
  final double lineSpacing;
  final double topOffset;

  const LinedPaperBackground({
    super.key,
    required this.child,
    required this.ruleColor,
    this.lineSpacing = 29.0,
    this.topOffset   = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioned.fill ensures lines cover the FULL parent area
        // regardless of how much text content is in the child.
        Positioned.fill(
          child: CustomPaint(
            painter: _LinesPainter(
              ruleColor:   ruleColor,
              lineSpacing: lineSpacing,
              topOffset:   topOffset,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LinesPainter extends CustomPainter {
  final Color ruleColor;
  final double lineSpacing;
  final double topOffset;

  const _LinesPainter({
    required this.ruleColor,
    required this.lineSpacing,
    required this.topOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ruleColor
      ..strokeWidth = 0.6;

    var y = topOffset + lineSpacing;
    while (y < size.height) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
      y += lineSpacing;
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.ruleColor != ruleColor ||
      old.lineSpacing != lineSpacing ||
      old.topOffset != topOffset;
}
