import 'dart:async';

import 'package:flutter/material.dart';
import 'package:baka/widgets/app_icon.dart';
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

    // Rebuild on every keystroke so the clear button appears immediately
    // (the search itself stays debounced above).
    useListenable(ctrl);

    void retry() => ref.read(searchProvider.notifier).search(ctrl.text);

    Widget message(String text) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.bodyPreview(context).copyWith(
                  fontStyle: FontStyle.italic,
                  color: muted,
                ),
            ),
          ),
        );

    final query = searchState.query.trim();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        toolbarHeight: 72,
        titleSpacing: 0,
        leading: IconButton(
          icon: AppIcon(AppIconData.back, color: onBg),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: AppText.rowTitle(context).copyWith(
                  color: onBg,
                ),
              decoration: InputDecoration(
                hintText: 'Search entries…',
                hintStyle: AppText.rowTitle(context).copyWith(
                    fontStyle: FontStyle.italic,
                    color: muted,
                  ),
                filled: true,
                fillColor: t.surfaceElev,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                prefixIcon: AppIcon(AppIconData.search, size: 20, color: muted),
                suffixIcon: ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: AppIcon(AppIconData.close, size: 20, color: muted),
                        tooltip: 'Clear search',
                        onPressed: () {
                          ctrl.clear();
                          ref.read(searchProvider.notifier).clear();
                        },
                      ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.outline, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? message('Type to search your pages.')
          : searchState.results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Search didn't work this time.",
                        style: AppText.bodyPreview(context).copyWith(
                            fontStyle: FontStyle.italic,
                            color: muted,
                          )),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: retry,
                      child: Text('Try again',
                          style: AppText.bodyPreview(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: t.primaryText,
                            )),
                    ),
                  ],
                ),
              ),
              data: (entries) => entries.isEmpty
                  ? message('Nothing mentions “$query” yet.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: entries.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                            child: Text(
                              '${entries.length} ${entries.length == 1 ? 'entry mentions' : 'entries mention'} “$query”',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.meta(context).copyWith(
                                  color: muted,
                                ),
                            ),
                          );
                        }
                        final e = entries[i - 1];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6,
                          ),
                          child: JournalCard(
                            entry: e,
                            onTap: () => context.push('/entry/${e.id}'),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
