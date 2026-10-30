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
import 'package:baka/widgets/motion.dart';
import 'package:baka/widgets/state_views.dart';

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
        error:   (e, _) => ErrorView(
          message: "Something went wrong loading your stats.",
          onRetry: () => ref.invalidate(entriesProvider)),
        data: (entries) {
          final streak     = EntriesNotifier.computeCurrentStreak(entries);
          final longest    = EntriesNotifier.computeLongestStreak(entries);
          final totalWords = entries.fold<int>(0, (s, e) => s + e.wordCount);
          final perDay     = EntriesNotifier.computeEntriesPerDay(entries, 365);
          final wordsPerDay = EntriesNotifier.computeWordsPerDay(entries, DateTime.now().day);
          final moods      = EntriesNotifier.computeMoodCounts(entries, 90);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('Your streak',
                    style: AppText.handXl(context, t.primary, 32)),
                const SizedBox(height: 18),

                // Hero card
                _HeroCard(
                  streak: streak,
                  longest: longest,
                  entries: entries.length,
                  words: totalWords,
                ),
                const SizedBox(height: 30),

                // Heatmap
                // Less/More legend below explains the shading.
                const _SectionTitle('Your year'),
                RepaintBoundary(
                  child: StreakCalendar(
                    entriesPerDay: perDay,
                    primary: t.primary,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Less', style: AppText.small(context).copyWith(
                        color: t.onSurfaceMuted,
                      )),
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
                    Text('More', style: AppText.small(context).copyWith(
                        color: t.onSurfaceMuted,
                      )),
                  ],
                ),
                const SizedBox(height: 30),

                // Words per day
                const _SectionTitle('Words written', 'Daily word count, this month.'),
                RepaintBoundary(
                  child: WordsChart(
                    wordsPerDay: wordsPerDay,
                    primary: t.primary,
                    muted: t.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 30),

                // Mood mix
                if (moods.isNotEmpty) ...[
                  const _SectionTitle("How you've felt", 'Top moods, past three months.'),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 30),
                ],

                // Tags summary (hidden until a tag exists)
                if (entries.any((e) => e.tags.isNotEmpty)) ...[
                  TagsSummary(entries: entries),
                  const SizedBox(height: 30),
                ],

                // Monthly mood calendar
                const _SectionTitle('Mood this month', 'Tap a day to open or write an entry.'),
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

  /// The streak counts up from 0 the first time Stats opens in a session.
  static bool _countPlayed = false;

  /// 980 → "980", 1 450 → "1.4k", 21 300 → "21k", 1 250 000 → "1.3M".
  static String _fmtWords(int w) {
    String trim(double v) => v < 10
        ? v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')
        : v.toStringAsFixed(0);
    if (w >= 1000000) return '${trim(w / 1000000)}M';
    if (w >= 1000) return '${trim(w / 1000)}k';
    return '$w';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final countFrom = _countPlayed ? streak : 0;
    _countPlayed = true;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.outlineSoft, width: 1),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: countFrom, end: streak),
                    duration: Motion.of(context, Motion.count),
                    curve: Motion.curve,
                    builder: (_, v, __) => Text(
                      '$v',
                      style: AppText.numeralXL(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: t.primary,
                          letterSpacing: -1,
                          height: 1,
                          fontFeatures: const [
                            FontFeature.liningFigures(),
                            FontFeature.tabularFigures(),
                          ],
                        ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text('day streak',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: AppText.handLg(context, t.onSurface)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  _motivational(streak),
                  style: AppText.label(context).copyWith(
                      fontStyle: FontStyle.italic,
                      color: t.onSurfaceMuted,
                    ),
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: t.outlineSoft),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(label: 'Longest', value: '$longest', suffix: longest == 1 ? 'day' : 'days'),
                  _Stat(label: 'Entries', value: '$entries'),
                  _Stat(label: 'Words',   value: _fmtWords(words)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scale down rather than overflow when values get long.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppText.numeral(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.onSurface,
                    letterSpacing: -0.3,
                  ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix!,
                  style: AppText.meta(context).copyWith(
                      color: t.onSurfaceMuted,
                    ),
                ),
              ],
            ],
          ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.meta(context).copyWith(
                  color: t.onSurfaceMuted,
                )),
        ],
      ),
    );
  }
}

/// Section title (display) with an optional one-line explanation beneath.
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle(this.title, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.heading(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: t.onBackground,
                )),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: AppText.meta(context).copyWith(
                    color: t.onSurfaceMuted,
                  )),
          ],
        ],
      ),
    );
  }
}
