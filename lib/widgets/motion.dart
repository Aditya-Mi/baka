import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared motion timings. Every animation goes through [Motion.of] so the
/// system reduce-motion setting turns it off everywhere at once.
abstract final class Motion {
  static const fast   = Duration(milliseconds: 200);
  static const enter  = Duration(milliseconds: 240);
  static const settle = Duration(milliseconds: 320);
  static const count  = Duration(milliseconds: 600);
  static const shake  = Duration(milliseconds: 300);

  static const curve = Curves.easeOutExpo;

  /// Changes that land while the editor is still popping (saving today's
  /// entry) hold for the first ~45% so the settle plays once Home is visible.
  /// Pair with [afterPop] as the duration.
  static const afterPopCurve = Interval(0.45, 1, curve: Curves.easeOutExpo);
  static const afterPop = Duration(milliseconds: 600);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Tab page for the shell routes: short cross-fade with a 4px rise instead
/// of a hard cut.
CustomTransitionPage<void> fadeThroughPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Motion.fast,
      reverseTransitionDuration: Motion.fast,
      transitionsBuilder: (context, animation, _, child) {
        if (Motion.reduced(context)) return child;
        final a = CurvedAnimation(parent: animation, curve: Motion.curve);
        return FadeTransition(
          opacity: a,
          child: AnimatedBuilder(
            animation: a,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, 4 * (1 - a.value)),
              child: c,
            ),
            child: child,
          ),
        );
      },
    );

/// Fades [child] in with an 8px rise after [delay]. Decides once, at mount:
/// with [animate] false (or reduce-motion on) it simply shows the child, so
/// rebuilds and scrolling never replay it.
class FadeRise extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Duration delay;
  const FadeRise({
    super.key,
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
  });

  @override
  State<FadeRise> createState() => _FadeRiseState();
}

class _FadeRiseState extends State<FadeRise>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  Animation<double>? _a;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null || !widget.animate || Motion.reduced(context)) return;
    final total = widget.delay + Motion.enter;
    final start = widget.delay.inMicroseconds / total.inMicroseconds;
    _c = AnimationController(vsync: this, duration: total)..forward();
    _a = CurvedAnimation(
        parent: _c!, curve: Interval(start, 1, curve: Motion.curve));
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    if (a == null) return widget.child;
    return FadeTransition(
      opacity: a,
      child: AnimatedBuilder(
        animation: a,
        builder: (_, c) => Transform.translate(
            offset: Offset(0, 8 * (1 - a.value)), child: c),
        child: widget.child,
      ),
    );
  }
}

/// Horizontal shake offset for progress [t] in 0..1: three decaying swings.
double shakeOffset(double t, {double amplitude = 8}) =>
    math.sin(t * 3 * 2 * math.pi) * amplitude * (1 - t);
