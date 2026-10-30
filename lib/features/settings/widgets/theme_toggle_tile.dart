import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/theme/theme_provider.dart';
import 'package:baka/features/settings/widgets/settings_row.dart';
import 'package:baka/widgets/illustrations.dart';

class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;

    final themeMode     = ref.watch(themeProvider);
    final systemIsDark  = MediaQuery.of(context).platformBrightness == Brightness.dark;
    // When system mode, highlight whichever the device is currently using.
    final effectiveDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemIsDark);

    return SettingsRow(
      icon: Icons.contrast_rounded,
      title: 'Theme',
      subtitle: 'Candlelight or parchment.',
      // Segmented Light / Dark selector in a padded track
      trailing: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.outline, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSegment(
              label: 'Light',
              selected: !effectiveDark,
              onTap: () => ref.read(themeProvider.notifier).setMode(ThemeMode.light),
            ),
            _ThemeSegment(
              label: 'Dark',
              selected: effectiveDark,
              onTap: () => ref.read(themeProvider.notifier).setMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t     = context.tokens;
    final color = selected ? t.onPrimaryContainer : t.onSurfaceMuted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? t.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(label == 'Light' ? AppIconData.sun : AppIconData.moon,
                  size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.meta(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
