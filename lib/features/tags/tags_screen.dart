import 'package:flutter/material.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/ink_doodle.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/people_provider.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/utils/note_marks.dart';

class TagsScreen extends HookConsumerWidget {
  final String? filterTag;
  /// Shows the pages about this person instead of the cloud.
  final String? filterPerson;
  const TagsScreen({super.key, this.filterTag, this.filterPerson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t            = context.tokens;
    final entriesAsync = ref.watch(entriesProvider);
    final tagsAsync    = ref.watch(tagsProvider);

    // Build a name→Tag lookup for quick color access
    final tagMap = {
      for (final tag in tagsAsync.valueOrNull ?? <Tag>[]) tag.name.toLowerCase(): tag,
    };

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: AppIcon(AppIconData.back, color: t.onBackground),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          filterTag != null
              ? '#${filterTag!.toLowerCase()}'
              : filterPerson != null
                  ? '@${filterPerson!.toLowerCase()}'
                  : 'Tags & people',
          overflow: TextOverflow.ellipsis,
          style: AppText.screenTitle(context).copyWith(
              fontWeight: FontWeight.w700,
              color: t.primary,
            ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _LoadError(
          t: t,
          onRetry: () => ref.invalidate(entriesProvider),
        ),
        data: (entries) {
          if (filterTag != null || filterPerson != null) {
            final tag = filterTag?.toLowerCase();
            final person = filterPerson?.toLowerCase();
            final filtered = entries
                .where((e) => tag != null
                    ? e.tags.any((tg) => tg.toLowerCase() == tag)
                    : peopleIn(e.body).contains(person))
                .toList();
            return filtered.isEmpty
                ? Center(
                    child: Text(
                        tag != null
                            ? 'No entries tagged #$tag.'
                            : 'No pages mention @$person.',
                        style: AppText.bodyPreview(context).copyWith(
                            fontStyle: FontStyle.italic,
                            color: t.onSurfaceMuted,
                          )),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        child: JournalCard(
                          entry: filtered[i],
                          onTap: () => context.push('/entry/${filtered[i].id}'),
                        ),
                      ),
                    ),
                  );
          }

          // Tag cloud
          final tagCounts = _countTags(entries);
          final people = ref.watch(peopleProvider);
          if (tagCounts.isEmpty && people.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const InkDoodle(Doodle.tag, width: 140),
                  const SizedBox(height: 16),
                  Text('No tags or people yet.\nWrite #anything or @someone in a page and they show up here.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyPreview(context).copyWith(
                        fontStyle: FontStyle.italic,
                        color: t.onSurfaceMuted,
                      )),
                ]),
              ),
            );
          }

          final sorted = tagCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                'Tap a tag or a person to see their pages. Long-press a tag to change its colour.',
                style: AppText.meta(context).copyWith(
                    height: 1.4,
                    color: t.onSurfaceMuted,
                  ),
              ),
              if (sorted.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionLabel('Tags', t: t),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: sorted.map((entry) {
                    final tag = tagMap[entry.key];
                    return _TagChip(
                      name:  entry.key,
                      count: entry.value,
                      tag:   tag,
                      t:     t,
                      onTap: () => context.push('/tags/${entry.key}'),
                      onLongPress: () => _showColorPicker(
                        context, ref,
                        tag ?? Tag(name: entry.key, color: TagPalette.forName(entry.key)),
                        t,
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (people.isNotEmpty) ...[
                const SizedBox(height: 26),
                _SectionLabel('People', t: t),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final p in people)
                      _PersonChip(
                        name: p.name,
                        count: p.pages,
                        t: t,
                        onTap: () => context.push('/people/${p.name}'),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Map<String, int> _countTags(entries) {
    final result = <String, int>{};
    for (final e in entries) {
      for (final tag in (e.tags as List<String>)) {
        final key = tag.toLowerCase();
        result[key] = (result[key] ?? 0) + 1;
      }
    }
    return result;
  }

  static void _showColorPicker(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    BakaTokens t,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surfaceElev,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change color for #${tag.name}',
                style: AppText.sectionHeading(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.onBackground,
                  )),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: TagPalette.colors.map((tc) {
                final isSelected = TagPalette.toHex(tag.color) ==
                    TagPalette.toHex(tc.color);
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: tc.name.replaceAll('_', ' '),
                  child: GestureDetector(
                    onTap: () async {
                      await ref.read(tagsProvider.notifier)
                          .updateColor(tag.name, TagPalette.toHex(tc.color));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tc.color.withValues(alpha: 0.25),
                        border: Border.all(
                          color: isSelected ? tc.color : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? AppIcon(AppIconData.check, size: 20, color: tc.color)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String name;
  final int count;
  final Tag? tag;
  final BakaTokens t;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TagChip({
    required this.name,
    required this.count,
    required this.tag,
    required this.t,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color  = tag?.color ?? t.secondary;
    final chipBg = tag?.chipBg ?? t.secondary.withValues(alpha: 0.12);
    final border = tag?.chipBorder ?? t.secondary.withValues(alpha: 0.30);

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          // No alignment: inside a Wrap it would stretch every chip to the
          // full row width.
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text('#$name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sectionLabel(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.onBackground,
                      )),
              ),
              const SizedBox(width: 7),
              Text('$count',
                  style: AppText.small(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: t.onSurfaceMuted,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final BakaTokens t;
  const _SectionLabel(this.text, {required this.t});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: AppText.sectionLabel(context).copyWith(
                fontSize: 20, color: t.onSurfaceMuted)),
      );
}

/// A person, in sage and outlined: tags are filled, people aren't.
class _PersonChip extends StatelessWidget {
  final String name;
  final int count;
  final BakaTokens t;
  final VoidCallback onTap;
  const _PersonChip(
      {required this.name, required this.count, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '@$name, $count ${count == 1 ? 'page' : 'pages'}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.secondary, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text('@$name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sectionLabel(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.onSecondaryContainer)),
                ),
                const SizedBox(width: 7),
                Text('$count',
                    style: AppText.small(context).copyWith(
                        fontWeight: FontWeight.w500, color: t.onSurfaceMuted)),
              ],
            ),
          ),
        ),
      );
}

/// Friendly load failure with a retry — replaces raw `Error: $e` text.
class _LoadError extends StatelessWidget {
  final BakaTokens t;
  final VoidCallback onRetry;
  const _LoadError({required this.t, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your tags.",
                  textAlign: TextAlign.center,
                  style: AppText.bodyPreview(context).copyWith(
                      fontStyle: FontStyle.italic,
                      color: t.onSurfaceMuted,
                    )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: Text('Try again',
                    style: AppText.bodyPreview(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.primaryText,
                      )),
              ),
            ],
          ),
        ),
      );
}
