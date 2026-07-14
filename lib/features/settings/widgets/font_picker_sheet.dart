import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:baka/core/fonts/font_provider.dart';
import 'package:baka/core/fonts/font_theme.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/illustrations.dart';

const _kPreview = 'Today I felt something shift inside me…';

/// Picks the font journal text is written in. This is an override layered on
/// top of the app font preset — null means "follow the preset".
class FontPickerSheet extends HookConsumerWidget {
  const FontPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final fonts    = context.fonts;
    final bg       = t.surfaceElev;
    final onBg     = t.onBackground;
    final muted    = t.onSurfaceMuted;
    final primary  = t.primary;
    final outline  = t.outline;

    final preset      = ref.watch(fontThemeProvider);
    final currentFont = ref.watch(fontProvider);
    final selected    = useState<String?>(currentFont);

    // null entry = "Match app font", pinned to the top.
    final entries = <MapEntry<String?, String>>[
      MapEntry(null, 'Match app font (${preset.label})'),
      ...kAvailableFonts.entries,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        color: bg,
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              decoration: BoxDecoration(
                color: outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose your writing font',
                      style: TextStyle(fontFamily: fonts.display,
                        fontSize: 20, fontWeight: FontWeight.w600, color: onBg,
                      )),
                  const SizedBox(height: 4),
                  Text('Pick the voice your pages will speak in.',
                      style: TextStyle(fontFamily: fonts.accent, fontSize: 15, color: muted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: outline, height: 1),
            // Font list
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: entries.map((entry) {
                  final isSelected = selected.value == entry.key;
                  final family = writingFamily(entry.key) ?? preset.body;
                  return InkWell(
                    onTap: () => selected.value = entry.key,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          // Radio circle
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.value,
                                    style: TextStyle(
                                      fontFamily: family,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? primary : onBg,
                                    )),
                                const SizedBox(height: 2),
                                Text(_kPreview,
                                    style: TextStyle(
                                      fontFamily: family,
                                      fontSize: 13,
                                      color: muted,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(color: outline, height: 1),
            // Apply button
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selected.value == currentFont
                        ? null
                        : () {
                            final notifier = ref.read(fontProvider.notifier);
                            final key = selected.value;
                            if (key == null) {
                              notifier.clearFont();
                            } else {
                              notifier.setFont(key);
                            }
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
