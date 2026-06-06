import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/stats/mood_entries_screen.dart';
import 'package:baka/features/stats/widgets/mood_calendar.dart';
import 'package:baka/features/stats/widgets/mood_chart.dart';
import 'package:baka/features/stats/widgets/streak_calendar.dart';
import 'package:baka/features/stats/widgets/tags_summary.dart';
import 'package:baka/features/stats/widgets/words_chart.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class StatsScreen extends HookConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t            = context.tokens;
    final entriesAsync = ref.watch(entriesProvider);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        bottom: false,
        child: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final streak     = EntriesNotifier.computeCurrentStreak(entries);
          final longest    = EntriesNotifier.computeLongestStreak(entries);
          final totalWords = entries.fold<int>(0, (s, e) => s + e.wordCount);
          final perDay     = EntriesNotifier.computeEntriesPerDay(entries, 365);
          final wordsPerDay = EntriesNotifier.computeWordsPerDay(entries, DateTime.now().day);
          final moods      = EntriesNotifier.computeMoodCounts(entries, 90);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your streak',
                              style: AppText.wordmark(t.primary, 42)),
                          const SizedBox(height: 2),
                          Text('Past year of pages',
                              style: AppText.handSm(t.onSurfaceMuted)),
                        ],
                      ),
                    ),
                    Text(
                      '${DateTime.now().year}',
                      style: AppText.mono(t.onSurfaceMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Hero card
                _HeroCard(
                  streak: streak,
                  longest: longest,
                  entries: entries.length,
                  words: totalWords,
                ),
                const SizedBox(height: 22),

                // Heatmap
                Text('Your year', style: AppText.displayS(t.onBackground)),
                const SizedBox(height: 4),
                Text(
                  'Each square is a day. Darker means more writing.',
                  style: AppText.handSm(t.onSurfaceMuted)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                RepaintBoundary(
                  child: StreakCalendar(
                    entriesPerDay: perDay,
                    primary: t.primary,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Less', style: AppText.handSm(t.onSurfaceMuted)),
                    const SizedBox(width: 6),
                    ...List.generate(5, (i) {
                      return Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: t.heatmap[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                    const SizedBox(width: 6),
                    Text('More', style: AppText.handSm(t.onSurfaceMuted)),
                  ],
                ),
                const SizedBox(height: 28),

                // Words per day
                Text('Words written', style: AppText.displayS(t.onBackground)),
                const SizedBox(height: 4),
                Text(
                  'Daily word count, past 30 days.',
                  style: AppText.handSm(t.onSurfaceMuted)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                RepaintBoundary(
                  child: WordsChart(
                    wordsPerDay: wordsPerDay,
                    primary: t.primary,
                    muted: t.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 28),

                // Mood mix
                if (moods.isNotEmpty) ...[
                  Text("How you've felt",
                      style: AppText.displayS(t.onBackground)),
                  const SizedBox(height: 4),
                  Text(
                    'Top moods, past three months.',
                    style: AppText.handSm(t.onSurfaceMuted)
                        .copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),
                  MoodChart(
                    moodCounts: moods,
                    primary: t.primary,
                    onBg: t.onBackground,
                    muted: t.onSurfaceMuted,
                    onMoodTap: (mood) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MoodEntriesScreen(mood: mood),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Tags summary
                TagsSummary(entries: entries),
                const SizedBox(height: 28),

                // Monthly mood calendar
                Text('Mood this month', style: AppText.displayS(t.onBackground)),
                const SizedBox(height: 4),
                Text('Tap a day to open or write an entry.',
                    style: AppText.handSm(t.onSurfaceMuted)
                        .copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 14),
                MoodCalendar(
                  entries: entries,
                  onDayTap: (date, entry) {
                    if (entry != null) {
                      context.push('/entry/${entry.id}');
                    } else {
                      final ds =
                          '${date.year.toString().padLeft(4, '0')}-'
                          '${date.month.toString().padLeft(2, '0')}-'
                          '${date.day.toString().padLeft(2, '0')}';
                      context.push('/new?date=$ds');
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int streak;
  final int longest;
  final int entries;
  final int words;
  const _HeroCard({
    required this.streak,
    required this.longest,
    required this.entries,
    required this.words,
  });

  static String _fmtWords(int w) =>
      w >= 1000 ? '${(w / 1000).toStringAsFixed(0)}k' : '$w';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ghost decoration
          Positioned(
            top: 0, right: 0,
            child: Opacity(
              opacity: 0.18,
              child: InkwellIcon(size: 72, color: t.primary),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$streak',
                    style: TextStyle(fontFamily: 'PlayfairDisplay',
                      fontSize: 64, fontWeight: FontWeight.w600,
                      color: t.primary, letterSpacing: -1, height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('day streak', style: AppText.handLg(t.onSurface)),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 240,
                child: Text(
                  '"${_motivational(streak)}"',
                  style: AppText.handSm(t.onSurfaceMuted)
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: t.outlineSoft),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Stat(label: 'Longest', value: '$longest', suffix: 'days'),
                  _Stat(label: 'Entries', value: '$entries'),
                  _Stat(label: 'Words',   value: _fmtWords(words)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _motivational(int s) {
    if (s == 0) return 'Write today to start a streak.';
    if (s == 1) return 'One day at a time. Keep going.';
    if (s < 3)  return 'Two days in. Something is beginning.';
    if (s < 7)  return 'A few days running. The habit is forming.';
    if (s < 14) return "You've shown up every day. That matters.";
    if (s < 21) return "Two weeks of words. Quietly remarkable.";
    if (s < 30) return "You've shown up three weeks running. Quietly remarkable.";
    if (s < 60) return 'A month of pages. This is who you are now.';
    return 'Keep writing. Your future self will be grateful.';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  const _Stat({required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontFamily: 'PlayfairDisplay',
                  fontSize: 22, fontWeight: FontWeight.w600,
                  color: t.onSurface, letterSpacing: -0.3,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix!,
                  style: AppText.handSm(t.onSurfaceMuted)
                      .copyWith(fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(label,
              style: AppText.handSm(t.onSurfaceMuted).copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
