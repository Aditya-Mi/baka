import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/widgets/illustrations.dart';

/// "THIS WEEK" row — one dot per weekday, showing that day's mood glyph.
class MoodStreakWidget extends StatelessWidget {
  final List<JournalEntry> entries;
  const MoodStreakWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final t   = context.tokens;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of this week
    final weekStart = today.subtract(Duration(days: (today.weekday - 1) % 7));

    final moodByDay = <DateTime, Mood>{};
    for (final e in entries) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (e.mood != null) moodByDay[d] ??= e.mood!;
    }

    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK',
            style: TextStyle(fontFamily: 'Caveat',
              fontSize: 15, color: t.onSurfaceMuted,
              letterSpacing: 0.5, height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isToday = day == today;
              final mood = moodByDay[day];
              return _StreakDay(
                letter: letters[i],
                mood: mood,
                today: isToday,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  final String letter;
  final Mood? mood;
  final bool today;
  const _StreakDay({required this.letter, required this.mood, required this.today});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ringColor  = today ? t.primary : t.outline;
    final labelColor = today ? t.primary : t.onSurfaceMuted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: today ? t.primaryContainer : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: mood != null
              ? MoodGlyph(
                  mood: mood!, size: 20,
                  color: today ? t.primary : t.onSurfaceMuted,
                )
              : Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    color: t.onSurfaceMuted.withValues(alpha:0.5),
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          letter,
          style: TextStyle(fontFamily: 'Caveat',
            fontSize: 13, color: labelColor, height: 1.3,
          ),
        ),
      ],
    );
  }
}
