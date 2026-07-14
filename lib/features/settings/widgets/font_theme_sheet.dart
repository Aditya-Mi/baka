import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:baka/core/fonts/font_theme.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/illustrations.dart';

/// Picks the app-wide font pairing. Each row previews all three visible roles
/// at once — the thing being chosen is how the fonts sit together, so showing
/// a single specimen would hide the actual decision.
class FontThemeSheet extends HookConsumerWidget {
  const FontThemeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final fonts   = context.fonts;
    final onBg    = t.onBackground;
    final muted   = t.onSurfaceMuted;
    final primary = t.primary;
    final outline = t.outline;

    final current  = ref.watch(fontThemeProvider);
    final selected = useState(current.id);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        color: t.surfaceElev,
        child: Column(
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App font',
                      style: TextStyle(fontFamily: fonts.display,
                        fontSize: 20, fontWeight: FontWeight.w600, color: onBg,
                      )),
                  const SizedBox(height: 4),
                  Text('Each set is a pairing — headings, text and labels chosen to sit together.',
                      style: TextStyle(fontFamily: fonts.accent, fontSize: 15, color: muted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: outline, height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: kFontPresets.values.map((p) {
                  final isSelected = selected.value == p.id;
                  final card = _PresetCard(
                    preset: p,
                    isSelected: isSelected,
                    onTap: () => selected.value = p.id,
                    onBg: onBg,
                    muted: muted,
                    primary: primary,
                    outline: outline,
                    surface: t.surface,
                  );
                  // Everything here already renders at the *active* preset's
                  // scale. Divide it back out so each card previews its own.
                  final mq = MediaQuery.of(context);
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaler: PresetTextScaler(
                        base: mq.textScaler,
                        factor: p.scale / current.scale,
                      ),
                    ),
                    child: card,
                  );
                }).toList(),
              ),
            ),
            Divider(color: outline, height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.value == current.id
                        ? null
                        : () {
                            ref.read(fontThemeProvider.notifier).setPreset(selected.value);
                            Navigator.of(context).pop();
                          },
                    child: const Text('Apply'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final FontPreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final Color onBg, muted, primary, outline, surface;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
    required this.onBg,
    required this.muted,
    required this.primary,
    required this.outline,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    final p = preset;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primary : outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? primary : outline,
                        width: isSelected ? 0 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const AppIcon(AppIconData.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(p.label,
                      style: TextStyle(
                        fontFamily: p.display,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? primary : onBg,
                      )),
                  const Spacer(),
                  Text(p.blurb,
                      style: TextStyle(fontFamily: p.accent, fontSize: 13, color: muted)),
                ],
              ),
              const SizedBox(height: 12),
              // The pairing itself: heading over body over a chip.
              Text('A quiet Tuesday',
                  style: TextStyle(
                    fontFamily: p.display,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: onBg,
                  )),
              const SizedBox(height: 6),
              Text('Today I felt something shift inside me — small, but it was there.',
                  style: TextStyle(
                    fontFamily: p.body,
                    fontSize: 14.5,
                    height: 1.5,
                    color: onBg.withValues(alpha: 0.85),
                  )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: outline),
                    ),
                    child: Text('#quiet',
                        style: TextStyle(fontFamily: p.accent, fontSize: 13, color: onBg)),
                  ),
                  const SizedBox(width: 10),
                  Text('412 words',
                      style: TextStyle(
                        fontFamily: p.mono,
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: muted,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
