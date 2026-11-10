import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/utils/note_marks.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:baka/widgets/motion.dart';

/// A page's words drawn properly: dotted and numbered lists, checkboxes that
/// tick where they are, quotes in the hand between hanging marks, time
/// stamps as a ruled divider, and tags, people, links and [[pages]] picked
/// out (and tappable). Every line keeps the body's line height, so the
/// page's rules still fall under the words.
class NoteBody extends StatefulWidget {
  final String text;
  final TextStyle style;
  /// A checkbox on line [index] (of [noteLines]) was tapped.
  final ValueChanged<int>? onToggle;
  final ValueChanged<String>? onPerson;
  final ValueChanged<String>? onPage;
  final ValueChanged<String>? onLink;

  const NoteBody({
    super.key,
    required this.text,
    required this.style,
    this.onToggle,
    this.onPerson,
    this.onPage,
    this.onLink,
  });

  @override
  State<NoteBody> createState() => _NoteBodyState();
}

class _NoteBodyState extends State<NoteBody> {
  final _taps = <GestureRecognizer>[];

  void _drop() {
    for (final r in _taps) {
      r.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  GestureRecognizer? _tap(ValueChanged<String>? on, String value) {
    if (on == null) return null;
    final r = TapGestureRecognizer()..onTap = () => on(value);
    _taps.add(r);
    return r;
  }

  List<InlineSpan> _inline(BuildContext context, String s, TextStyle style) {
    final t = context.tokens;
    return [
      for (final tok in tokenize(s))
        switch (tok.mark) {
          Mark.plain  => TextSpan(text: tok.text, style: style),
          Mark.tag    => TextSpan(text: tok.text, style: style.copyWith(
              color: t.primaryText, fontWeight: FontWeight.bold)),
          Mark.person => TextSpan(
              text: tok.text,
              recognizer: _tap(widget.onPerson, tok.value),
              style: style.copyWith(
                  color: t.onSecondaryContainer, fontWeight: FontWeight.w600)),
          Mark.link   => TextSpan(
              text: tok.text,
              recognizer: _tap(widget.onLink, tok.value),
              style: style.copyWith(
                  color: t.primaryText,
                  decoration: TextDecoration.underline,
                  decorationColor: t.primaryText.withValues(alpha: 0.45),
                  decorationThickness: 1.2)),
          Mark.page   => TextSpan(children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: AppIcon(AppIconData.pageLink,
                      size: (style.fontSize ?? 17) * 0.9, color: t.onSurfaceMuted),
                ),
              ),
              TextSpan(
                text: tok.value,
                recognizer: _tap(widget.onPage, tok.value),
                style: style.copyWith(
                  fontFamily: AppText.heading(context).fontFamily,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: t.onBackground,
                ),
              ),
            ]),
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    _drop();
    final t = context.tokens;
    final style = widget.style;
    final size = style.fontSize ?? 17;
    final lineH = size * (style.height ?? 1.75);
    final faded = style.copyWith(
        color: t.onSurfaceMuted,
        decoration: TextDecoration.lineThrough,
        decorationColor: t.onSurfaceMuted);
    final hand = AppText.hand(context, t.onSurface)
        .copyWith(fontSize: size + 7, height: lineH / (size + 7));
    final quoteMark = AppText.heading(context).copyWith(
        color: t.primary.withValues(alpha: 0.6),
        fontSize: size + 17,
        height: 1,
        fontWeight: FontWeight.w400);
    final lines = noteLines(widget.text);
    // Numbers share the dots' column unless some list reaches two digits.
    final numberWidth =
        lines.any((l) => l.kind == LineKind.numbered && l.number >= 10) ? 28.0 : 18.0;

    Widget rich(List<InlineSpan> spans) => Text.rich(TextSpan(children: spans));
    Widget gutter(Widget child, {double width = 18}) => SizedBox(
        width: width, height: lineH, child: Align(alignment: Alignment.centerLeft, child: child));
    Widget item(Widget mark, List<InlineSpan> spans, {double width = 18, double gap = 10}) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [gutter(mark, width: width), SizedBox(width: gap), Expanded(child: rich(spans))],
        );

    final children = <Widget>[];
    for (final (i, l) in lines.indexed) {
      final prevQuote = i > 0 && lines[i - 1].kind == LineKind.quote;
      final nextQuote = i + 1 < lines.length && lines[i + 1].kind == LineKind.quote;
      children.add(switch (l.kind) {
        LineKind.text => l.text.isEmpty
            ? SizedBox(height: lineH)
            : rich(_inline(context, l.text, style)),
        LineKind.bullet => item(
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
              ),
            ),
            _inline(context, l.text, style)),
        LineKind.numbered => item(
            Text('${l.number}.',
                style: style.copyWith(color: t.primaryText, fontWeight: FontWeight.w600)),
            _inline(context, l.text, style),
            width: numberWidth),
        LineKind.check || LineKind.done => item(
            _CheckBox(
              done: l.kind == LineKind.done,
              onTap: widget.onToggle == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onToggle!(i);
                    },
            ),
            _inline(context, l.text, l.kind == LineKind.done ? faded : style),
            width: 28,
            gap: 0),
        LineKind.quote => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The opening mark hangs in the margin without making the
              // line any taller than its neighbours.
              SizedBox(
                width: 26,
                height: lineH,
                child: prevQuote
                    ? null
                    : OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: Text('“', style: quoteMark),
                      ),
              ),
              Expanded(
                child: rich([
                  ..._inline(context, l.text, hand),
                  if (!nextQuote)
                    TextSpan(
                        text: ' ”',
                        style: quoteMark.copyWith(
                            fontSize: hand.fontSize, height: hand.height)),
                ]),
              ),
            ],
          ),
        LineKind.stamp => SizedBox(
            height: lineH,
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: t.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(l.text,
                      style: AppText.caption(context)
                          .copyWith(color: t.onSurfaceMuted, fontSize: size + 2, height: 1)),
                ),
                Expanded(child: Container(height: 1, color: t.outline)),
              ],
            ),
          ),
      });
    }

    return SelectionArea(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// A pencilled box; ticking inks a terracotta check into it, stroke by
/// stroke, and unticking lifts it.
class _CheckBox extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;
  const _CheckBox({required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      checked: done,
      button: onTap != null,
      label: done ? 'Done' : 'Not done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // A finger-sized target around the small box.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 10, 4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: done ? 1 : 0),
            duration: Motion.of(context, const Duration(milliseconds: 260)),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CustomPaint(
              size: const Size(18, 18),
              painter: _CheckPainter(v, box: t.onSurface, tick: t.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color box, tick;
  _CheckPainter(this.progress, {required this.box, required this.tick});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)).deflate(0.6),
      Paint()
        ..color = box
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(s * 0.24, s * 0.52)
      ..lineTo(s * 0.43, s * 0.70)
      ..lineTo(s * 0.80, s * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = tick
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter o) =>
      o.progress != progress || o.box != box || o.tick != tick;
}
