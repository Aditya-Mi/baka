import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/people_provider.dart';
import 'package:baka/utils/note_editing.dart';
import 'package:baka/utils/note_marks.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:baka/widgets/motion.dart';

/// What sits above the keyboard while writing, in the mood strip's place:
/// the format row, or, while an @name or [[page]] is being typed, what it
/// could be.
class WritingStrip extends ConsumerWidget {
  final TextEditingController body;
  /// The page being edited, kept out of its own [[page]] suggestions.
  final String? selfId;
  const WritingStrip({super.key, required this.body, this.selfId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: body,
      builder: (context, value, _) {
        final lookup = activeLookup(value);
        final Widget child = switch (lookup?.kind) {
          Lookup.person => _PeopleRow(
              key: const ValueKey('people'),
              lookup: lookup!,
              people: [
                ...ref.watch(peopleProvider),
                // Names already on this page, saved or not.
                for (final name in {
                  for (final tok in tokenize(value.text))
                    if (tok.mark == Mark.person && tok.start != lookup.start) tok.value,
                })
                  if (!ref.read(peopleProvider).any((p) => p.name == name))
                    (name: name, pages: 0),
              ],
              onPick: (name) => body.completeAt(lookup.start, '@$name'),
            ),
          Lookup.page => _PagesList(
              key: const ValueKey('pages'),
              query: lookup!.query,
              entries: [
                for (final e in ref.watch(entriesProvider).valueOrNull ?? const <JournalEntry>[])
                  if (e.id != selfId) e,
              ],
              onPick: (e) => body.completeAt(lookup.start, '[[${pageRefFor(e)}]]'),
            ),
          null => _FormatRow(
              key: const ValueKey('format'),
              body: body,
              current: body.lineKind,
            ),
        };
        return AnimatedSwitcher(
          duration: Motion.of(context, Motion.fast),
          switchInCurve: Curves.easeOutCubic,
          child: child,
        );
      },
    );
  }
}

class _FormatRow extends StatelessWidget {
  final TextEditingController body;
  final LineKind current;
  const _FormatRow({super.key, required this.body, required this.current});

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppIconData.list, 'List', LineKind.bullet,
          () => body.toggleLine(LineKind.bullet)),
      (AppIconData.checkSquare, 'Check', LineKind.check,
          () => body.toggleLine(LineKind.check)),
      (AppIconData.quote, 'Quote', LineKind.quote,
          () => body.toggleLine(LineKind.quote)),
      (AppIconData.clock, 'Time', LineKind.stamp,
          () => body.insertStamp(DateTime.now())),
      (AppIconData.at, 'Person', null, () => body.typeAtCaret('@')),
      (AppIconData.pageLink, 'Page', null, () => body.typeAtCaret('[[')),
    ];
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (icon, label, kind, action) in items)
              _FormatButton(
                icon: icon,
                label: label,
                on: kind != null && kind != LineKind.stamp &&
                    (current == kind ||
                        (kind == LineKind.check && current == LineKind.done) ||
                        (kind == LineKind.bullet && current == LineKind.numbered)),
                onTap: () {
                  HapticFeedback.selectionClick();
                  action();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _FormatButton(
      {required this.icon, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Motion.of(context, Motion.fast),
                width: 42, height: 38,
                decoration: BoxDecoration(
                  color: on ? t.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(19),
                ),
                alignment: Alignment.center,
                child: AppIcon(icon, size: 21, color: on ? t.primary : t.onSurface),
              ),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  style: AppText.hand(context, on ? t.primaryText : t.onSurfaceMuted)
                      .copyWith(fontSize: 16, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

/// People who match what's typed after "@". The closest match is outlined
/// darker; a name not seen before can be added as it is.
class _PeopleRow extends StatelessWidget {
  final ActiveLookup lookup;
  final List<({String name, int pages})> people;
  final ValueChanged<String> onPick;
  const _PeopleRow(
      {super.key, required this.lookup, required this.people, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final q = lookup.query.toLowerCase();
    final starts = [for (final p in people) if (p.name.startsWith(q)) p.name];
    final inside = [
      for (final p in people)
        if (!p.name.startsWith(q) && p.name.contains(q)) p.name,
    ];
    final names = [...starts, ...inside].take(8).toList();
    final canAdd = q.isNotEmpty && !names.contains(q);

    Widget chip(String text, {required bool best, bool add = false}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: best
                    ? t.onSecondaryContainer
                    : add
                        ? t.outline
                        : t.secondary,
                width: best ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onPick(add ? q : text);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Text(add ? '+ @$text' : '@$text',
                    style: AppText.hand(
                            context, add ? t.onSurfaceMuted : t.onSecondaryContainer)
                        .copyWith(fontSize: 19, fontWeight: FontWeight.w700, height: 1.2)),
              ),
            ),
          ),
        );

    return SizedBox(
      height: 68,
      child: names.isEmpty && !canAdd
          ? Center(
              child: Text('Type a name',
                  style: AppText.hand(context, t.onSurfaceMuted).copyWith(fontSize: 18)),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              children: [
                for (final (i, n) in names.indexed) chip(n, best: i == 0),
                if (canAdd) chip(q, best: names.isEmpty, add: true),
              ],
            ),
    );
  }
}

/// Pages that match what's typed after "[[": by title, first line or day.
/// With nothing typed yet, the latest pages.
class _PagesList extends StatelessWidget {
  final String query;
  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry> onPick;
  const _PagesList(
      {super.key, required this.query, required this.entries, required this.onPick});

  static final _day = DateFormat('EEE, MMM d');

  static String _lead(JournalEntry e) => leadLine(e.body);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final q = query.trim().toLowerCase();
    final sorted = [...entries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final matches = [
      for (final e in sorted)
        if (q.isEmpty ||
            (e.title?.toLowerCase().contains(q) ?? false) ||
            _lead(e).toLowerCase().contains(q) ||
            pageRefFor(e).toLowerCase().contains(q))
          e,
    ].take(3).toList();

    if (matches.isEmpty) {
      return SizedBox(
        height: 68,
        child: Center(
          child: Text('No page matches “$query”',
              style: AppText.hand(context, t.onSurfaceMuted).copyWith(fontSize: 18)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, e) in matches.indexed)
            Material(
              color: i == 0 ? t.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPick(e);
                },
                child: SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: e.title != null
                              ? Text(e.title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.heading(context).copyWith(
                                      color: t.onBackground,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400))
                              : Text(_lead(e).isEmpty ? 'An empty page' : _lead(e),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.reading(context).copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 15,
                                      color: t.onSurfaceMuted)),
                        ),
                        const SizedBox(width: 12),
                        Text(_day.format(e.createdAt),
                            style: AppText.caption(context)
                                .copyWith(color: t.onSurfaceMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
