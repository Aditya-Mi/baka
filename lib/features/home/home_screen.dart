import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t      = context.tokens;
    final entries = ref.watch(entriesProvider);
    final name   = ref.watch(userProvider);

    final streak = entries.valueOrNull != null
        ? EntriesNotifier.computeCurrentStreak(entries.valueOrNull!)
        : 0;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: name.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_greeting()}, ',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: t.primary, height: 0.95,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'PlayfairDisplay',
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: t.onBackground,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                _greeting(),
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: t.primary,
                ),
              ),
        actions: [
          if (streak > 0)
            GestureDetector(
              onTap: () => context.go('/stats'),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: t.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlameIcon(width: 13, height: 18, color: t.primary),
                    const SizedBox(width: 3),
                    Text(
                      '$streak',
                      style: TextStyle(fontFamily: 'Caveat',
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: t.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: AppIcon(AppIconData.search, size: 22, color: t.onBackground),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: AppIcon(AppIconData.calendar, size: 22, color: t.onBackground),
            onPressed: () => _onCalendarTap(context, ref),
            tooltip: 'Jump to date',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeekRow(entries: list),
            Expanded(
              child: list.isEmpty
                  ? _EmptyState(t: t)
                  : _EntryList(entries: list, t: t),
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5  && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 22) return 'Good evening';
    return 'Good night';
  }

  Future<void> _onCalendarTap(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !context.mounted) return;

    final list = ref.read(entriesProvider).valueOrNull ?? [];
    final existing = list.where((e) {
      final d = e.createdAt;
      return d.year == picked.year &&
             d.month == picked.month &&
             d.day == picked.day;
    }).toList();

    if (existing.isNotEmpty && context.mounted) {
      context.push('/entry/${existing.first.id}');
    } else if (context.mounted) {
      final ds = '${picked.year.toString().padLeft(4, '0')}-'
                 '${picked.month.toString().padLeft(2, '0')}-'
                 '${picked.day.toString().padLeft(2, '0')}';
      context.push('/new?date=$ds');
    }
  }
}

// ── Week mood row ────────────────────────────────────────────────────────────

class _WeekRow extends StatelessWidget {
  final List<JournalEntry> entries;
  const _WeekRow({required this.entries});

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

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BakaTokens t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 56, color: t.onSurfaceMuted),
          const SizedBox(height: 20),
          Text(
            'Your story begins here.',
            style: TextStyle(fontFamily: 'PlayfairDisplay',
              fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Write to add your first entry.',
            style: TextStyle(fontFamily: 'Caveat',fontSize: 16, color: t.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

// ── Grouped list ─────────────────────────────────────────────────────────────

class _EntryList extends StatelessWidget {
  final List<JournalEntry> entries;
  final BakaTokens t;
  const _EntryList({required this.entries, required this.t});

  @override
  Widget build(BuildContext context) {
    final grouped = _group(entries);
    final keys    = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: keys.length,
      itemBuilder: (_, i) => _Section(
        label:   keys[i],
        entries: grouped[keys[i]]!,
        t:       t,
      ),
    );
  }

  static Map<String, List<JournalEntry>> _group(List<JournalEntry> entries) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastStart = weekStart.subtract(const Duration(days: 7));
    final result    = <String, List<JournalEntry>>{};

    for (final e in entries) {
      final d    = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      final diff = today.difference(d).inDays;
      final label = diff == 0              ? 'Today'
                  : diff == 1              ? 'Yesterday'
                  : !d.isBefore(weekStart) ? 'This week'
                  : !d.isBefore(lastStart) ? 'Last week'
                  : DateFormat('MMMM yyyy').format(e.createdAt);
      result.putIfAbsent(label, () => []).add(e);
    }
    return result;
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<JournalEntry> entries;
  final BakaTokens t;
  const _Section({required this.label, required this.entries, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            label,
            style: TextStyle(fontFamily: 'Caveat',
              fontSize: 15, fontWeight: FontWeight.w600,
              color: t.onSurfaceMuted, letterSpacing: 0.5,
            ),
          ),
        ),
        ...entries.map((e) => RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: JournalCard(
              entry: e,
              onTap: () => context.push('/entry/${e.id}'),
            ),
          ),
        )),
      ],
    );
  }
}
