import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart';
import 'package:baka/providers/search_provider.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t       = context.tokens;
    final bg      = t.background;
    final onBg    = t.onBackground;
    final muted   = t.onSurfaceMuted;

    final searchState  = ref.watch(searchProvider);
    final ctrl         = useTextEditingController();
    final debounceTimer= useRef<Timer?>(null);

    useEffect(() {
      void listener() {
        debounceTimer.value?.cancel();
        debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
          ref.read(searchProvider.notifier).search(ctrl.text);
        });
      }
      ctrl.addListener(listener);
      return () {
        ctrl.removeListener(listener);
        debounceTimer.value?.cancel();
      };
    }, [ctrl]);

    // Clear on dispose
    useEffect(() => () => ref.read(searchProvider.notifier).clear(), const []);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: onBg),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(fontFamily: 'Lora',fontSize: 16, color: onBg),
          decoration: InputDecoration(
            hintText: 'Search entries…',
            hintStyle: TextStyle(fontFamily: 'Lora',
              fontSize: 16, fontStyle: FontStyle.italic, color: muted,
            ),
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (ctrl.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: muted),
              onPressed: () {
                ctrl.clear();
                ref.read(searchProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: searchState.query.isEmpty
          ? Center(
              child: Text(
                'Type to search your pages.',
                style: TextStyle(fontFamily: 'Lora',
                  fontSize: 15, fontStyle: FontStyle.italic, color: muted,
                ),
              ),
            )
          : searchState.results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (entries) => entries.isEmpty
                  ? Center(
                      child: Text(
                        'No entries found.',
                        style: TextStyle(fontFamily: 'Lora',
                          fontSize: 15, fontStyle: FontStyle.italic, color: muted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5,
                        ),
                        child: JournalCard(
                          entry: entries[i],
                          onTap: () => context.push('/entry/${entries[i].id}'),
                        ),
                      ),
                    ),
            ),
    );
  }
}
