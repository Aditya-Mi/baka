import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';
import 'package:baka/widgets/motion.dart';

/// Compact PIN entry widget — title, subtitle, 4 dots, keypad.
/// Parent is responsible for layout (centering, back button, etc.).
/// Pass a different [key] to reset internal digit state.
class PinKeypad extends StatefulWidget {
  final String title;
  final String subtitle;
  final ValueChanged<String> onComplete;
  /// When true the subtitle is shown as an error (error colour + icon) and the
  /// dots turn error-coloured, so a wrong PIN never looks like the plain hint.
  final bool isError;
  /// Optional action under the keypad (e.g. "Use fingerprint").
  final Widget? footer;

  const PinKeypad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
    this.isError = false,
    this.footer,
  });

  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad>
    with SingleTickerProviderStateMixin {
  final _digits = <int>[];
  // Wrong PIN: the dots shake alongside the error colour. Parents reset the
  // keypad with a new key, so an error can arrive at mount or as an update.
  late final _shake = AnimationController(vsync: this, duration: Motion.shake);

  @override
  void initState() {
    super.initState();
    if (widget.isError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playShake());
    }
  }

  @override
  void didUpdateWidget(PinKeypad old) {
    super.didUpdateWidget(old);
    if (widget.isError && !old.isError) _playShake();
  }

  void _playShake() {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    if (Motion.reduced(context)) return;
    _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

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
    final err = Theme.of(context).colorScheme.error;
    final dotColor = widget.isError && _digits.isEmpty ? err : t.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title,
            style: AppText.numeral(context).copyWith(
                fontWeight: FontWeight.w600,
                color: t.onBackground,
              )),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: widget.isError,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isError) ...[
                Icon(Icons.error_outline_rounded, size: 16, color: err),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(widget.subtitle,
                    textAlign: TextAlign.center,
                    style: AppText.label(context).copyWith(
                        fontWeight: widget.isError ? FontWeight.w600 : FontWeight.w400,
                        color: widget.isError ? err : t.onSurfaceMuted,
                      )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // Dots
        AnimatedBuilder(
          animation: _shake,
          builder: (_, row) => Transform.translate(
            offset: Offset(shakeOffset(_shake.value), 0),
            child: row,
          ),
          child: Row(
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
                  border: Border.all(color: dotColor, width: 1.5),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 44),
        // Grid
        _buildGrid(t),
        if (widget.footer != null) ...[
          const SizedBox(height: 16),
          widget.footer!,
        ],
      ],
    );
  }

  Widget _buildGrid(BakaTokens t) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(t, 1, 2, 3),
          const SizedBox(height: 16),
          _row(t, 4, 5, 6),
          const SizedBox(height: 16),
          _row(t, 7, 8, 9),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 76),
              const SizedBox(width: 24),
              _numBtn(t, 0),
              const SizedBox(width: 24),
              _backBtn(t),
            ],
          ),
        ],
      );

  Widget _row(BakaTokens t, int a, int b, int c) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _numBtn(t, a),
          const SizedBox(width: 24),
          _numBtn(t, b),
          const SizedBox(width: 24),
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
        semanticLabel: 'Delete digit',
        child: Icon(Icons.backspace_outlined, size: 24, color: t.onSurfaceMuted),
      );
}

class _KeyBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final BakaTokens t;
  final bool transparent;
  final String? semanticLabel;
  const _KeyBtn({required this.onTap, required this.child,
      required this.t, this.transparent = false, this.semanticLabel});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: transparent ? Colors.transparent : t.surface,
          borderRadius: BorderRadius.circular(38),
          child: InkWell(
            borderRadius: BorderRadius.circular(38),
            onTap: onTap,
            child: SizedBox(width: 76, height: 76, child: Center(child: child)),
          ),
        ),
      );
}
