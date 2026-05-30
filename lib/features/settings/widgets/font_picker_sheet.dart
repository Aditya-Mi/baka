import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:baka/core/fonts/font_provider.dart';
import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/illustrations.dart';

const _kFonts = <String, String>{
  'lora':             'Lora',
  'playfairDisplay':  'Playfair Display',
  'crimsonPro':       'Crimson Pro',
  'ebGaramond':       'EB Garamond',
  'caveat':           'Caveat',
  'libreBaskerville': 'Libre Baskerville',
};

const _kPreview = 'Today I felt something shift inside me…';

class FontPickerSheet extends HookConsumerWidget {
  const FontPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final bg       = t.surfaceElev;
    final onBg     = t.onBackground;
    final muted    = t.onSurfaceMuted;
    final primary  = t.primary;
    final outline  = t.outline;

    final currentFont = ref.watch(fontProvider);
    final selected    = useState(currentFont);

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
                      style: TextStyle(fontFamily: 'PlayfairDisplay',
                        fontSize: 20, fontWeight: FontWeight.w600, color: onBg,
                      )),
                  const SizedBox(height: 4),
                  Text('Pick the voice your pages will speak in.',
                      style: TextStyle(fontFamily: 'Caveat', fontSize: 15, color: muted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: outline, height: 1),
            // Font list
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: _kFonts.entries.map((entry) {
                  final isSelected = selected.value == entry.key;
                  final fontStyle  = _fontStyle(entry.key);
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value,
                                  style: fontStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? primary : onBg,
                                  )),
                              const SizedBox(height: 2),
                              Text(_kPreview,
                                  style: fontStyle(
                                    fontSize: 13.0,
                                    color: muted,
                                  )),
                            ],
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
                            ref.read(fontProvider.notifier).setFont(selected.value);
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

  static Function _fontStyle(String key) => switch (key) {
        'playfairDisplay'  => GoogleFonts.playfairDisplay,
        'crimsonPro'       => GoogleFonts.crimsonPro,
        'ebGaramond'       => GoogleFonts.ebGaramond,
        'caveat'           => GoogleFonts.caveat,
        'libreBaskerville' => GoogleFonts.libreBaskerville,
        _                  => GoogleFonts.lora,
      };
}
