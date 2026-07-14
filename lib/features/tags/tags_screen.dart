import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/core/fonts/font_theme.dart';

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
      for (final tag in tagsAsync.valueOrNull ?? <Tag>[]) tag.name: tag,
    };

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          filterTag != null ? '#$filterTag' : 'Tags',
          style: TextStyle(fontFamily: context.fonts.accent,
            fontSize: 28, fontWeight: FontWeight.w700, color: t.primary),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (filterTag != null) {
            final filtered = entries
                .where((e) => e.tags.contains(filterTag!.toLowerCase()))
                .toList();
            return filtered.isEmpty
                ? Center(
                    child: Text('No entries tagged #$filterTag.',
                        style: TextStyle(fontFamily: context.fonts.body,
                          fontSize: 15, fontStyle: FontStyle.italic,
                          color: t.onSurfaceMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => RepaintBoundary(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
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
              child: Text('No tags yet.',
                  style: TextStyle(fontFamily: context.fonts.body,
                    fontSize: 15, fontStyle: FontStyle.italic,
                    color: t.onSurfaceMuted)),
            );
          }

          final sorted = tagCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 10,
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
          );
        },
      ),
    );
  }

  static Map<String, int> _countTags(entries) {
    final result = <String, int>{};
    for (final e in entries) {
      for (final tag in (e.tags as List<String>)) {
        result[tag] = (result[tag] ?? 0) + 1;
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
                style: TextStyle(fontFamily: context.fonts.display,
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: TagPalette.colors.map((tc) {
                final isSelected = TagPalette.toHex(tag.color) ==
                    TagPalette.toHex(tc.color);
                return GestureDetector(
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

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(24),
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
            Text('#$name',
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: t.onBackground)),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 13, color: t.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }
}
