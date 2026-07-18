import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/draft_strip.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/features/home/widgets/mood_streak_widget.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/providers/captures_provider.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/core/fonts/font_theme.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t      = context.tokens;
    final entries = ref.watch(entriesProvider);
    final name   = ref.watch(userProvider);
    final drafts = ref.watch(draftsProvider).valueOrNull ?? const <Draft>[];
    final inboxCount = ref.watch(unprocessedCapturesCountProvider);

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
                    style: TextStyle(fontFamily: context.fonts.accent,
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: t.primary, height: 0.95,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: context.fonts.display,
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: t.onBackground,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                _greeting(),
                style: TextStyle(fontFamily: context.fonts.accent,
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
                      style: TextStyle(fontFamily: context.fonts.accent,
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: t.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: inboxCount > 0
                ? Badge(
                    label: Text('$inboxCount'),
                    backgroundColor: t.primary,
                    textColor: Colors.white,
                    child: Icon(Icons.mic_none_rounded, size: 22, color: t.onBackground),
                  )
                : Icon(Icons.mic_none_rounded, size: 22, color: t.onBackground),
            onPressed: () => context.push('/inbox'),
            tooltip: 'Voice Inbox',
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
            MoodStreakWidget(entries: list),
            if (drafts.any((d) => !d.isEdit))
              DraftStrip(drafts: [for (final d in drafts) if (!d.isEdit) d]),
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
            style: TextStyle(fontFamily: context.fonts.display,
              fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Write to add your first entry.',
            style: TextStyle(fontFamily: context.fonts.accent,fontSize: 16, color: t.onSurfaceMuted),
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
            style: TextStyle(fontFamily: context.fonts.accent,
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
