import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/motion.dart';

/// Every mood in one swipeable row. Tapping one blooms an ink blot under its
/// glyph and writes its name in below; the previous blot fades. Nothing
/// opens or closes.
class MoodSelector extends StatefulWidget {
  final Mood? selected;
  final ValueChanged<Mood> onChanged;

  const MoodSelector({super.key, this.selected, required this.onChanged});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // A mood chosen earlier may sit off-screen; bring it into view once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          for (final mood in Mood.values)
            _MoodCell(
              key: mood == widget.selected ? _selectedKey : null,
              mood: mood,
              selected: mood == widget.selected,
              onTap: () {
                if (mood == widget.selected) return;
                HapticFeedback.selectionClick();
                widget.onChanged(mood);
              },
            ),
        ],
      ),
    );
  }
}

class _MoodCell extends StatefulWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;
  const _MoodCell({
    super.key,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MoodCell> createState() => _MoodCellState();
}

class _MoodCellState extends State<_MoodCell>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 160),
    value: widget.selected ? 1 : 0,
  );
  // True while the blot fades out: it keeps its size and only loses ink.
  bool _leaving = false;

  @override
  void didUpdateWidget(_MoodCell old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    if (Motion.reduced(context)) {
      _c.value = widget.selected ? 1 : 0;
      return;
    }
    _leaving = !widget.selected;
    widget.selected ? _c.forward(from: 0) : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.mood.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: 52,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              final bloom = Curves.easeOutExpo.transform(v);
              final scale = _leaving ? 1.0 : 0.2 + 0.8 * bloom;
              final ink   = _leaving ? v : (v == 0 ? 0.0 : 1.0);
              final write = _leaving
                  ? v
                  : const Interval(0.45, 1, curve: Curves.easeOut).transform(v);
              return Column(
                children: [
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 42, height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (ink > 0)
                          Opacity(
                            opacity: ink,
                            child: Transform.scale(
                              scale: scale,
                              child: CustomPaint(
                                size: const Size(42, 42),
                                painter: InkBlotPainter(t.primaryContainer),
                              ),
                            ),
                          ),
                        MoodGlyph(
                          mood: widget.mood,
                          size: 26,
                          color: Color.lerp(
                              t.onSurfaceMuted, t.primary, ink)!,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: write == 0
                        ? null
                        // The name wipes in left to right, like a pen stroke.
                        : OverflowBox(
                            maxWidth: 90,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: write,
                                child: Text(
                                  widget.mood.label,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: AppText.hand(context, t.primaryText)
                                      .copyWith(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          height: 1.1),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A wet-ink blot: a circle with a slightly uneven edge.
class InkBlotPainter extends CustomPainter {
  final Color color;
  const InkBlotPainter(this.color);

  static final _blot = parseSvgPath(
      'M21 2.5C30.5 2 38.5 9.5 37.5 19.5C38 29.5 31 37.5 20.5 37'
      'C10.5 38.5 2 31 2.5 20.5C1.5 10 10 3 21 2.5Z');

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 40;
    canvas
      ..save()
      ..scale(s)
      ..drawPath(_blot, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(InkBlotPainter o) => o.color != color;
}
