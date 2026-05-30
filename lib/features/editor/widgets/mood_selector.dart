import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';

/// Inline mood selector — header row expands/collapses a grid in-place.
/// No bottom sheet.
class MoodSelector extends StatefulWidget {
  final Mood? selected;
  final ValueChanged<Mood> onChanged;

  const MoodSelector({super.key, this.selected, required this.onChanged});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row — always visible ──────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                if (widget.selected == null)
                  Expanded(
                    child: Text(
                      'How does today feel?',
                      style: TextStyle(fontFamily: 'Lora',
                        fontSize: 15, fontStyle: FontStyle.italic,
                        color: t.onSurfaceMuted,
                      ),
                    ),
                  )
                else ...[
                  MoodGlyph(
                    mood: widget.selected!, size: 24, color: t.primary,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.selected!.label,
                        style: TextStyle(fontFamily: 'Caveat',
                          fontSize: 17, fontWeight: FontWeight.w600,
                          color: t.onBackground,
                        ),
                      ),
                      Text(
                        'tap to change',
                        style: TextStyle(fontFamily: 'Caveat',
                          fontSize: 12, color: t.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: t.onSurfaceMuted),
                ),
              ],
            ),
          ),
        ),

        // ── Inline mood grid — AnimatedSize expand/collapse ─────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _expanded
              ? Container(
                  color: t.surface,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Mood.values.map((mood) {
                      final isSelected = mood == widget.selected;
                      return GestureDetector(
                        onTap: () {
                          widget.onChanged(mood);
                          setState(() => _expanded = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? t.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected ? t.primary : t.outline,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoodGlyph(
                                mood: mood, size: 18,
                                color: isSelected ? t.primary : t.onSurface,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                mood.label,
                                style: TextStyle(fontFamily: 'Caveat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? t.primary : t.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
