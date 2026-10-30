import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/tags_provider.dart';

class TagsScreen extends HookConsumerWidget {
  final String? filterTag;
  const TagsScreen({super.key, this.filterTag});

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
          icon: Icon(Icons.arrow_back_rounded, color: t.onBackground),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          filterTag != null ? '#${filterTag!.toLowerCase()}' : 'Tags',
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
          if (filterTag != null) {
            final filtered = entries
                .where((e) => e.tags.any(
                    (tg) => tg.toLowerCase() == filterTag!.toLowerCase()))
                .toList();
            return filtered.isEmpty
                ? Center(
                    child: Text('No entries tagged #${filterTag!.toLowerCase()}.',
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
          if (tagCounts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('No tags yet.\nWrite #anything in a page and it shows up here.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyPreview(context).copyWith(
                        fontStyle: FontStyle.italic,
                        color: t.onSurfaceMuted,
                      )),
              ),
            );
          }

          final sorted = tagCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                'Tap a tag to see its entries. Long-press to change its colour.',
                style: AppText.meta(context).copyWith(
                    height: 1.4,
                    color: t.onSurfaceMuted,
                  ),
              ),
              const SizedBox(height: 14),
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
                          ? Icon(Icons.check_rounded, size: 20, color: tc.color)
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
