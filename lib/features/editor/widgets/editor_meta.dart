import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/core/fonts/font_theme.dart';

/// Collapsible editor metadata. Shows the full date/mood/tag [expanded] widgets,
/// or a slim one-line summary when [collapsed] (i.e. the body field is focused),
/// giving the text field the maximum vertical space on small phones.
class EditorMeta extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTapSummary; // called to expand (unfocus body)
  final String dateLabel;
  final String timeLabel;
  final Mood? mood;
  final int tagCount;
  final List<Widget> expanded; // full date row, mood, tags (+ dividers)

  const EditorMeta({
    super.key,
    required this.collapsed,
    required this.onTapSummary,
    required this.dateLabel,
    required this.timeLabel,
    required this.mood,
    required this.tagCount,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: collapsed
          ? InkWell(
              onTap: onTapSummary,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: t.outline, width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: t.onSurfaceMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('$dateLabel · $timeLabel',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: context.fonts.accent,
                              fontSize: 15, color: t.onSurfaceMuted)),
                    ),
                    const Spacer(),
                    if (mood != null) ...[
                      MoodGlyph(mood: mood!, size: 16, color: t.primary),
                      const SizedBox(width: 10),
                    ],
                    if (tagCount > 0)
                      Text('#$tagCount',
                          style: TextStyle(fontFamily: context.fonts.accent,
                              fontSize: 15, color: t.primary)),
                    const SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: t.onSurfaceMuted),
                  ],
                ),
              ),
            )
          : Column(mainAxisSize: MainAxisSize.min, children: expanded),
    );
  }
}
