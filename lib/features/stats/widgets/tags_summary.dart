import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/core/fonts/font_theme.dart';

class TagsSummary extends ConsumerWidget {
  final List<JournalEntry> entries;
  const TagsSummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final tagsAsync = ref.watch(tagsProvider);
    final tagMap    = {
      for (final tag in tagsAsync.valueOrNull ?? <Tag>[]) tag.name: tag,
    };

    // Count tag frequency across all entries
    final counts = <String, int>{};
    for (final e in entries) {
      for (final tag in e.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    final top5 = (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your tags', style: AppText.displayS(context, t.onBackground)),
                  const SizedBox(height: 2),
                  Text('Most used topics.',
                      style: AppText.handSm(context, t.onSurfaceMuted)
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/tags'),
              child: Text('See all →',
                  style: TextStyle(fontFamily: context.fonts.accent,
                    fontSize: 16, color: t.primary,
                    fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: top5.map((entry) {
            final tag    = tagMap[entry.key];
            final color  = tag?.color ?? t.secondary;
            final chipBg = tag?.chipBg ?? t.secondary.withValues(alpha: 0.12);
            final border = tag?.chipBorder ?? t.secondary.withValues(alpha: 0.30);

            return GestureDetector(
              onTap: () => context.push('/tags/${entry.key}'),
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
                    Text('#${entry.key}',
                        style: TextStyle(fontFamily: context.fonts.accent,
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: t.onBackground)),
                    const SizedBox(width: 6),
                    Text('${entry.value}',
                        style: TextStyle(fontFamily: context.fonts.accent,
                          fontSize: 13, color: t.onSurfaceMuted)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
