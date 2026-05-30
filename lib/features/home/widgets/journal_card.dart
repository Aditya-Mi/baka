import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class JournalCard extends ConsumerWidget {
  final JournalEntry entry;
  final VoidCallback? onTap;
  const JournalCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final tagList = ref.watch(tagsProvider).valueOrNull ?? <Tag>[];
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
                      Text(
                        DateFormat('EEE, MMM d').format(entry.createdAt),
                        style: TextStyle(fontFamily: 'Caveat',
                          fontSize: 19, color: t.onSurface, height: 1,
                        ),
                      ),
                      if (entry.mood != null)
                        MoodGlyph(mood: entry.mood!, size: 22, color: t.primary),
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
                      children: entry.tags.map((tag) {
                        final c = tagColorFor(tagList, tag);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            border: Border.all(
                              color: c.withValues(alpha: 0.30), width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(fontFamily: 'Caveat',
                              fontSize: 14, color: t.onBackground, height: 1.3,
                            ),
                          ),
                        );
                      }).toList(),
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

/// Builds a [TextSpan] that renders [text] with [baseStyle] but highlights
/// every `#word` token in bold + [highlightColor].
/// Returns stored tag color, falls back to deterministic palette hash.
Color tagColorFor(List<Tag> tags, String name) {
  for (final t in tags) {
    if (t.name == name) return t.color;
  }
  return TagPalette.forName(name);
}

TextSpan buildTagSpan(String text, Color highlightColor, TextStyle baseStyle) {
  final pattern = RegExp(r'#\w+');
  if (!pattern.hasMatch(text)) return TextSpan(text: text, style: baseStyle);

  final spans = <InlineSpan>[];
  int cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: baseStyle.copyWith(
        color: highlightColor,
        fontWeight: FontWeight.bold,
      ),
    ));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return TextSpan(children: spans, style: baseStyle);
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
