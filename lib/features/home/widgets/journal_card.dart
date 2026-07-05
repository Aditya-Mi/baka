import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/utils/tag_utils.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/tag_chip.dart';

class JournalCard extends ConsumerWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;
  const JournalCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final tagList = ref.watch(tagsProvider).valueOrNull ?? <Tag>[];
    // True when an unsaved edit-draft exists for this entry.
    final hasUnsavedEdits = ref.watch(draftsProvider.select((async) =>
        (async.valueOrNull ?? const [])
            .any((d) => d.isEdit && d.entryId == entry.id)));
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14.5, height: 1.55, color: t.onSurface,
    ) ?? TextStyle(fontFamily: 'Lora', fontSize: 14.5, height: 1.55, color: t.onSurface);

    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Left ribbon
            Positioned(
              left: 0, top: 0, bottom: 0, width: 3,
              child: Container(color: t.primary),
            ),
            // Faint ruled lines
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardRulesPainter(
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha:0.04)
                        : Colors.black.withValues(alpha:0.04),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date + mood
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                DateFormat('EEE, MMM d').format(entry.createdAt),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Caveat',
                                  fontSize: 19, color: t.onSurface, height: 1,
                                ),
                              ),
                            ),
                            if (hasUnsavedEdits) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: t.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5, height: 5,
                                      decoration: BoxDecoration(
                                        color: t.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text('draft',
                                        style: TextStyle(fontFamily: 'Caveat',
                                          fontSize: 12, color: t.primary)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (entry.mood != null) ...[
                        const SizedBox(width: 8),
                        MoodGlyph(mood: entry.mood!, size: 22, color: t.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Body preview with #word highlighting
                  if (entry.body.trim().isNotEmpty)
                    Text.rich(
                      buildTagSpan(entry.body.trim(), t.primary, baseStyle),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Tags
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 6,
                      children: entry.tags.map((tag) => TagChip(
                        tag: tag,
                        color: tagColorFor(tagList, tag),
                        textColor: t.onBackground,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardRulesPainter extends CustomPainter {
  final Color color;
  const _CardRulesPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    for (double y = 24; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _CardRulesPainter old) => old.color != color;
}
