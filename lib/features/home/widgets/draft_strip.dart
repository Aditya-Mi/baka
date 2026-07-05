import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/widgets/illustrations.dart';

/// Home-screen strip listing unsaved drafts. Tapping a card resumes the
/// draft; the ✕ discards it.
class DraftStrip extends ConsumerWidget {
  final List<Draft> drafts;
  const DraftStrip({super.key, required this.drafts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 6),
          child: Text('DRAFTS',
              style: TextStyle(fontFamily: 'Caveat',
                fontSize: 15, color: t.onSurfaceMuted, letterSpacing: 0.5)),
        ),
        ...drafts.map((d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _DraftCard(
                draft: d,
                onTap: () => context.push(d.isEdit
                    ? '/edit/${d.entryId}'
                    : '/new?draftId=${d.id}'),
                onDiscard: () =>
                    ref.read(draftsProvider.notifier).clear(d.id),
              ),
            )),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  final Draft draft;
  final VoidCallback onTap;
  final VoidCallback onDiscard;
  const _DraftCard({
    required this.draft,
    required this.onTap,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final snippet = draft.body.trim().replaceAll(RegExp(r'\s+'), ' ');
    final label = draft.isEdit ? 'Unsaved edits' : 'Draft';
    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.outline, width: 1),
          ),
          child: Row(
            children: [
              QuillIcon(size: 16, color: t.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: t.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(label,
                              style: TextStyle(fontFamily: 'Caveat',
                                fontSize: 13, color: t.primary)),
                        ),
                        const SizedBox(width: 8),
                        Text(_relTime(draft.savedAt),
                            style: TextStyle(fontFamily: 'Caveat',
                              fontSize: 13, color: t.onSurfaceMuted)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snippet.isEmpty ? 'Empty draft' : snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Lora',
                        fontSize: 14, color: t.onBackground),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 18, color: t.onSurfaceMuted),
                onPressed: onDiscard,
                tooltip: 'Discard draft',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }
}
