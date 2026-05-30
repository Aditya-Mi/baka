import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/widgets/illustrations.dart';

class MoodEntriesScreen extends ConsumerWidget {
  final Mood mood;
  const MoodEntriesScreen({super.key, required this.mood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t            = context.tokens;
    final entriesAsync = ref.watch(entriesProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: t.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoodGlyph(mood: mood, size: 22, color: t.primary),
            const SizedBox(width: 10),
            Text(mood.label,
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: t.primary)),
          ],
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final filtered = entries
              .where((e) => e.mood == mood)
              .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoodGlyph(mood: mood, size: 48, color: t.onSurfaceMuted),
                  const SizedBox(height: 16),
                  Text('No entries with this mood.',
                      style: TextStyle(fontFamily: 'Lora',
                        fontSize: 15, fontStyle: FontStyle.italic,
                        color: t.onSurfaceMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (_, i) => RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: JournalCard(
                  entry: filtered[i],
                  onTap: () => context.push('/entry/${filtered[i].id}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
