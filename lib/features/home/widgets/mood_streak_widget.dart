import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/motion.dart';

/// "This week" row — one disc per weekday. Days with an entry get a filled
/// disc (plus that day's mood glyph); empty days are a quiet dot. The
/// current streak sits on the right and opens Stats.
///
/// On milestone streak days (written today) one handwritten line sits under
/// the row for the rest of that day.
///
/// Saving today's entry is the app's one authored moment: today's disc fills,
/// its glyph settles in and the streak rolls to the new count.
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
    final writtenDays = <DateTime>{};
    for (final e in entries) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      writtenDays.add(d);
      if (e.mood != null) moodByDay[d] ??= e.mood!;
    }

    final streak = EntriesNotifier.computeCurrentStreak(entries);
    final milestone =
        writtenDays.contains(today) ? _milestones[streak] : null;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'This week',
                style: AppText.sectionLabel(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.onSurfaceMuted,
                    height: 1.2,
                  ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.afterPop),
                switchInCurve: Motion.afterPopCurve,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                        .animate(a),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerRight,
                  children: [...previous, if (current != null) current],
                ),
                child: streak <= 0
                    ? const SizedBox.shrink(key: ValueKey(0))
                    : InkWell(
                        key: ValueKey(streak),
                        onTap: () => context.go('/stats'),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FlameIcon(width: 11, height: 15, color: t.primary),
                              const SizedBox(width: 4),
                              Text(
                                streak == 1 ? '1-day streak' : '$streak-day streak',
                                style: AppText.small(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: t.primaryText,
                                  ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              return _StreakDay(
                letter: letters[i],
                mood: moodByDay[day],
                written: writtenDays.contains(day),
                today: day == today,
              );
            }),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.afterPop),
            curve: Motion.afterPopCurve,
            alignment: Alignment.topLeft,
            child: milestone == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(milestone,
                        style: AppText.hand(context, t.primaryText)),
                  ),
          ),
        ],
      ),
    );
  }

  static const _milestones = {
    3:   'Three days in a row. Keep the thread going.',
    7:   'Seven days running. A whole week of pages.',
    14:  'Two weeks of showing up.',
    30:  'Thirty days. A month of pages.',
    50:  'Fifty days. This is a habit now.',
    100: 'A hundred days of pages.',
    365: 'A full year, every day.',
  };
}

class _StreakDay extends StatelessWidget {
  final String letter;
  final Mood? mood;
  final bool written;
  final bool today;
  const _StreakDay({required this.letter, required this.mood,
      required this.written, required this.today});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: Motion.of(context, Motion.afterPop),
          curve: Motion.afterPopCurve,
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: today ? t.primaryContainer
                : written ? t.surface : Colors.transparent,
            shape: BoxShape.circle,
            border: today ? Border.all(color: t.primary, width: 1.5) : null,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.afterPop),
            switchInCurve: Motion.afterPopCurve,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: 0.6, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: mood != null
                ? MoodGlyph(key: ValueKey(mood), mood: mood!, size: 20,
                    color: t.primary)
                : Container(
                    key: ValueKey(written || today),
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: written || today ? t.primary : t.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          letter,
          style: AppText.micro(context).copyWith(
              fontWeight: today ? FontWeight.w700 : FontWeight.w500,
              color: today ? t.onPrimaryContainer : t.onSurfaceMuted,
            ),
        ),
      ],
    );
  }
}
