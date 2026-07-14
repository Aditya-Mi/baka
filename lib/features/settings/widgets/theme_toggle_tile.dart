import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/theme/theme_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/core/fonts/font_theme.dart';

class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final onBg    = t.onBackground;
    final muted   = t.onSurfaceMuted;
    final primary = t.primary;
    final tagBg   = t.primaryContainer;
    final outline = t.outline;
    final surface = t.surface;

    final themeMode     = ref.watch(themeProvider);
    final systemIsDark  = MediaQuery.of(context).platformBrightness == Brightness.dark;
    // When system mode, highlight whichever the device is currently using.
    final effectiveDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemIsDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: TextStyle(fontFamily: context.fonts.body,
                        fontSize: 15, fontWeight: FontWeight.w500, color: onBg,
                      )),
                  const SizedBox(height: 2),
                  Text('Candlelight or parchment.',
                      style: TextStyle(fontFamily: context.fonts.accent,fontSize: 13, color: muted)),
                ],
              ),
              const Spacer(),
              // Segmented Light / Dark selector
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: outline, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeSegment(
                      label: 'Light',
                      selected: !effectiveDark,
                      primary: primary,
                      tagBg: tagBg,
                      onBg: onBg,
                      muted: muted,
                      onTap: () => ref.read(themeProvider.notifier).setMode(ThemeMode.light),
                      isFirst: true,
                    ),
                    _ThemeSegment(
                      label: 'Dark',
                      selected: effectiveDark,
                      primary: primary,
                      tagBg: tagBg,
                      onBg: onBg,
                      muted: muted,
                      onTap: () => ref.read(themeProvider.notifier).setMode(ThemeMode.dark),
                      isFirst: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color primary;
  final Color tagBg;
  final Color onBg;
  final Color muted;
  final VoidCallback onTap;
  final bool isFirst;

  const _ThemeSegment({
    required this.label, required this.selected, required this.primary,
    required this.tagBg, required this.onBg, required this.muted,
    required this.onTap, required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? tagBg : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left:  Radius.circular(isFirst ? 9 : 0),
            right: Radius.circular(isFirst ? 0 : 9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Light')
              AppIcon(AppIconData.sun, size: 14, color: selected ? primary : muted)
            else
              AppIcon(AppIconData.moon, size: 14, color: selected ? primary : muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontFamily: context.fonts.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? primary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
