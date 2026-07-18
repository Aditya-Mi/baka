import 'package:flutter/material.dart';

/// Renders a voice capture's amplitude bars. Bars left of [progress] are drawn
/// in [playedColor], the rest in [barColor]. Matches the Pencil "Waveform"
/// component: thin rounded bars, height mapped to normalized amplitude.
///
/// If [samples] is empty (captures recorded before waveform support), a calm
/// static placeholder pattern is drawn so the row never looks broken.
class Waveform extends StatelessWidget {
  final List<double> samples;
  final double progress; // 0..1
  final Color barColor;
  final Color playedColor;
  final double barWidth;
  final double gap;
  final double minBarHeight;

  const Waveform({
    super.key,
    required this.samples,
    required this.barColor,
    required this.playedColor,
    this.progress = 0,
    this.barWidth = 2,
    this.gap = 2,
    this.minBarHeight = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _WaveformPainter(
          samples: samples.isNotEmpty ? samples : _placeholder,
          progress: progress.clamp(0.0, 1.0),
          barColor: barColor,
          playedColor: playedColor,
          barWidth: barWidth,
          gap: gap,
          minBarHeight: minBarHeight,
        ),
      ),
    );
  }

  static const List<double> _placeholder = [
    .18, .34, .5, .28, .62, .4, .74, .52, .34, .66, .44, .8,
    .56, .3, .5, .7, .42, .6, .34, .78, .48, .26, .66, .44,
  ];
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final double progress;
  final Color barColor;
  final Color playedColor;
  final double barWidth;
  final double gap;
  final double minBarHeight;

  _WaveformPainter({
    required this.samples,
    required this.progress,
    required this.barColor,
    required this.playedColor,
    required this.barWidth,
    required this.gap,
    required this.minBarHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // How many bars fit; sample the data down to that count.
    final slot = barWidth + gap;
    final count = ((size.width + gap) / slot).floor().clamp(1, samples.length);
    if (count <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(barWidth / 2);
    final playedBars = (count * progress).round();

    for (var i = 0; i < count; i++) {
      final srcIndex = (i * samples.length / count).floor().clamp(0, samples.length - 1);
      final amp = samples[srcIndex].clamp(0.0, 1.0);
      final h = (minBarHeight + amp * (size.height - minBarHeight))
          .clamp(minBarHeight, size.height);
      final x = i * slot;
      final top = (size.height - h) / 2;
      paint.color = i < playedBars ? playedColor : barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, top, barWidth, h), radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.samples != samples ||
      old.barColor != barColor ||
      old.playedColor != playedColor;
}
