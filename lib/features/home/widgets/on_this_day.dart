import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/journal_entry.dart';

/// "A year ago today" — the most recent entry written on today's date in an
/// earlier year. Renders nothing on days without one.
class OnThisDay extends StatelessWidget {
  final List<JournalEntry> entries;
  const OnThisDay({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final t   = context.tokens;
    final now = DateTime.now();

    JournalEntry? match;
    for (final e in entries) {
      final d = e.createdAt;
      if (d.year < now.year && d.month == now.month && d.day == now.day &&
          (match == null || d.isAfter(match.createdAt))) {
        match = e;
      }
    }
    if (match == null) return const SizedBox.shrink();

    final entry   = match;
    final years   = now.year - entry.createdAt.year;
    final when    = years == 1 ? 'A year ago today' : '$years years ago today';
    final snippet = entry.body.trim().split('\n').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/entry/${entry.id}'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.outline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$when · ${DateFormat('EEE, MMM d y').format(entry.createdAt)}',
                  style: AppText.hand(context, t.primaryText),
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(context).copyWith(
                        color: t.onSurface,
                      ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
