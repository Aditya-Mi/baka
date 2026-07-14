import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';

/// Compact PIN entry widget — title, subtitle, 4 dots, keypad.
/// Parent is responsible for layout (centering, back button, etc.).
/// Pass a different [key] to reset internal digit state.
class PinKeypad extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String> onComplete;

  const PinKeypad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad> {
  final _digits = <int>[];

  void _tap(int d) {
    if (_digits.length >= 4) return;
    setState(() => _digits.add(d));
    if (_digits.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          widget.onComplete(_digits.map((x) => x.toString()).join());
        }
      });
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            style: TextStyle(fontFamily: context.fonts.display,
              fontSize: 22, fontWeight: FontWeight.w600, color: t.onBackground)),
        const SizedBox(height: 6),
        Text(widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: context.fonts.accent, fontSize: 15, color: t.onSurfaceMuted)),
        const SizedBox(height: 32),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _digits.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 16, height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? t.primary : Colors.transparent,
                border: Border.all(color: t.primary, width: 1.5),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        // Grid
        _buildGrid(t),
      ],
    );
  }

  Widget _buildGrid(BakaTokens t) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(t, 1, 2, 3),
          const SizedBox(height: 12),
          _row(t, 4, 5, 6),
          const SizedBox(height: 12),
          _row(t, 7, 8, 9),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 72),
              const SizedBox(width: 12),
              _numBtn(t, 0),
              const SizedBox(width: 12),
              _backBtn(t),
            ],
          ),
        ],
      );

  Widget _row(BakaTokens t, int a, int b, int c) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _numBtn(t, a),
          const SizedBox(width: 12),
          _numBtn(t, b),
          const SizedBox(width: 12),
          _numBtn(t, c),
        ],
      );

  Widget _numBtn(BakaTokens t, int n) => _KeyBtn(
        onTap: () => _tap(n),
        t: t,
        child: Text('$n',
            style: TextStyle(fontFamily: context.fonts.display,
              fontSize: 26, fontWeight: FontWeight.w400, color: t.onBackground)),
      );

  Widget _backBtn(BakaTokens t) => _KeyBtn(
        onTap: _backspace,
        t: t,
        transparent: true,
        child: Icon(Icons.backspace_outlined, size: 22, color: t.onSurfaceMuted),
      );
}

class _KeyBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final BakaTokens t;
  final bool transparent;
  const _KeyBtn({required this.onTap, required this.child,
      required this.t, this.transparent = false});

  @override
  Widget build(BuildContext context) => Material(
        color: transparent ? Colors.transparent : t.surface,
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: SizedBox(width: 72, height: 72, child: Center(child: child)),
        ),
      );
}
