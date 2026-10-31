import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/mood_streak_widget.dart';
import 'package:baka/features/home/widgets/on_this_day.dart';
import 'package:baka/features/home/widgets/page_stack.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/providers/captures_provider.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/user_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/ink_doodle.dart';
import 'package:baka/widgets/motion.dart';
import 'package:baka/widgets/state_views.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t      = context.tokens;
    final entries = ref.watch(entriesProvider);
    final name   = ref.watch(userProvider);
    final drafts = ref.watch(draftsProvider).valueOrNull ?? const <Draft>[];
    final inboxCount = ref.watch(unprocessedCapturesCountProvider);

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
                  // Both parts may shrink so large font scales never overflow
                  // into the action icons; the name gives way first.
                  Flexible(
                    flex: 3,
                    child: Text(
                      '${_greeting()}, ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.primary,
                          height: 0.95,
                        ),
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sectionHeading(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: t.onBackground,
                        ),
                    ),
                  ),
                ],
              )
            : Text(
                _greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.screenTitle(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.primary,
                  ),
              ),
        actions: [
          IconButton(
            icon: inboxCount > 0
                ? Badge(
                    label: Text('$inboxCount'),
                    backgroundColor: t.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    child: AppIcon(AppIconData.mic, size: 24, color: t.onBackground),
                  )
                : AppIcon(AppIconData.mic, size: 24, color: t.onBackground),
            onPressed: () => context.push('/inbox'),
            tooltip: 'Voice Inbox',
          ),
          IconButton(
            tooltip: 'Search',
            icon: AppIcon(AppIconData.search, size: 24, color: t.onBackground),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: AppIcon(AppIconData.calendar, size: 24, color: t.onBackground),
            onPressed: () => _onCalendarTap(context, ref),
            tooltip: 'Jump to date',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(onRetry: () => ref.invalidate(entriesProvider)),
        data: (list) {
          final newDrafts = [for (final d in drafts) if (!d.isEdit) d];
          // One scroll for the whole page: the week, the drafts and the
          // shelves move together instead of the top staying pinned.
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: MoodStreakWidget(entries: list)),
              SliverToBoxAdapter(child: OnThisDay(entries: list)),
              SliverToBoxAdapter(
                child: AnimatedSize(
                  duration: Motion.of(context, Motion.fast),
                  curve: Motion.curve,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      for (final d in newDrafts)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: DraftSheet(key: ValueKey(d.id), draft: d),
                        ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _EmptyState(t: t))
              else
                _Shelves(entries: list),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
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
          const InkDoodle(Doodle.notebook, width: 180),
          const SizedBox(height: 20),
          // The words arrive once the pen has finished drawing.
          FadeRise(
            delay: const Duration(milliseconds: 1100),
            child: Column(children: [
              Text(
                'Your story begins here.',
                style: AppText.heading(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.onBackground,
                  ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Write to add your first entry.',
                style: AppText.caption(context).copyWith(
                    color: t.onSurfaceMuted,
                  ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Shelves ──────────────────────────────────────────────────────────────────

/// This month lies open; every earlier month sits shut on its shelf with only
/// its page count, so old pages are found on purpose, not met by scrolling.
class _Shelves extends HookWidget {
  final List<JournalEntry> entries;
  const _Shelves({required this.entries});

  /// The first stacks rise in once per app session, not on every rebuild.
  static bool _introPlayed = false;

  @override
  Widget build(BuildContext context) {
    final shelves = _group(entries);
    final open = useState<Set<String>>({shelves.keys.first});
    final intro = !_introPlayed;
    _introPlayed = true;

    final items = <Widget>[];
    var n = 0;
    for (final MapEntry(key: label, value: days) in shelves.entries) {
      final isOpen = open.value.contains(label);
      final pages = days.fold<int>(0, (a, d) => a + d.length);
      items.add(_ShelfHeader(
        label: label,
        pages: pages,
        open: isOpen,
        onTap: () => open.value = isOpen
            ? ({...open.value}..remove(label))
            : {...open.value, label},
      ));
      items.add(AnimatedSize(
        duration: Motion.of(context, Motion.settle),
        curve: Motion.curve,
        alignment: Alignment.topCenter,
        child: !isOpen
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Column(children: [
                  for (final (i, day) in days.indexed) ...[
                    // Inside this month, a quiet line where this week ends.
                    if (label == _thisMonth && i > 0 &&
                        !_inThisWeek(day.first) && _inThisWeek(days[i - 1].first))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Earlier this month',
                              style: AppText.caption(context)
                                  .copyWith(color: context.tokens.onSurfaceMuted)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: FadeRise(
                        animate: intro && n < 6,
                        delay: Duration(milliseconds: 45 * n++),
                        child: DayStack(key: ValueKey(day.first.id), entries: day),
                      ),
                    ),
                  ],
                ]),
              ),
      ));
    }
    return SliverList.list(children: items);
  }

  static const _thisMonth = 'This month';

  static bool _inThisWeek(JournalEntry e) {
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return !e.createdAt.isBefore(start);
  }

  /// Shelf label → days (newest first) → that day's pages (newest first).
  static Map<String, List<List<JournalEntry>>> _group(List<JournalEntry> entries) {
    final now       = DateTime.now();
    final result    = <String, List<List<JournalEntry>>>{};
    DateTime? lastDay;
    for (final e in entries) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      final label = d.year == now.year && d.month == now.month
          ? _thisMonth
          : d.year == now.year
              ? DateFormat('MMMM').format(d)
              : DateFormat('MMMM y').format(d);
      final shelf = result.putIfAbsent(label, () => []);
      if (lastDay == d && shelf.isNotEmpty) {
        shelf.last.add(e);
      } else {
        shelf.add([e]);
      }
      lastDay = d;
    }
    return result;
  }
}

class _ShelfHeader extends StatelessWidget {
  final String label;
  final int pages;
  final bool open;
  final VoidCallback onTap;
  const _ShelfHeader(
      {required this.label, required this.pages, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.outlineSoft)),
          ),
          child: Row(
            children: [
              Text(label,
                  style: AppText.sectionHeading(context).copyWith(color: t.onBackground)),
              const Spacer(),
              Text(pages == 1 ? '1 page' : '$pages pages',
                  style: AppText.caption(context).copyWith(color: t.onSurfaceMuted)),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: open ? 0 : -0.25,
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curve,
                child: AppIcon(AppIconData.chevronDown, size: 18, color: t.onSurfaceMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
