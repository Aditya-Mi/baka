import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/editor/widgets/anchor_bar.dart';
import 'package:baka/features/editor/widgets/editor_meta.dart';
import 'package:baka/features/editor/widgets/lined_paper_background.dart';
import 'package:baka/features/editor/widgets/word_counter_bar.dart';
import 'package:baka/features/editor/widgets/mood_selector.dart';
import 'package:baka/features/editor/widgets/tag_input_field.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/utils/hashtag_controller.dart';
import 'package:baka/utils/lifecycle_observer.dart';
import 'package:baka/utils/time_picker_util.dart';
import 'package:baka/utils/word_counter.dart';

class EditEntryScreen extends HookConsumerWidget {
  final String id;
  const EditEntryScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final ruleColor = t.rule;
    final sessionId = 'edit:$id';

    final entriesAsync = ref.watch(entriesProvider);
    final entry = () {
      for (final e in entriesAsync.valueOrNull ?? const <JournalEntry>[]) {
        if (e.id == id) return e;
      }
      return null;
    }();

    final bodyCtrl = useMemoized(() => HashtagController(highlightColor: t.primary));
    useEffect(() => bodyCtrl.dispose, const []);
    useEffect(() {
      bodyCtrl.highlightColor = t.primary;
      bodyCtrl.invalidate();
      return null;
    }, [t.primary]);

    final mood      = useState<Mood?>(null);
    final tags      = useState<List<String>>([]);
    final bodyTags  = useState<Set<String>>({});
    final anchor    = useState(const Anchor());
    final hydrated  = useState(false);
    final restored  = useState(false);
    final isSaving  = useState(false);
    final entryDate = useState(DateTime.now());

    // Body focus drives the collapsible metadata header.
    final bodyFocus   = useFocusNode();
    final bodyFocused = useState(false);
    useEffect(() {
      void l() => bodyFocused.value = bodyFocus.hasFocus;
      bodyFocus.addListener(l);
      return () => bodyFocus.removeListener(l);
    }, [bodyFocus]);

    void applyFields({
      required String body,
      required Mood? m,
      required List<String> tg,
      required Anchor a,
      required DateTime date,
    }) {
      bodyCtrl.text   = body;
      mood.value      = m;
      tags.value      = List<String>.from(tg);
      bodyTags.value  = Set<String>.from(HashtagController.extractTags(body));
      anchor.value    = a;
      entryDate.value = date;
    }

    // Hydrate once — prefer an unsaved edit-draft over the stored entry.
    useEffect(() {
      if (entry != null && !hydrated.value) {
        final d = ref.read(draftsProvider.notifier).byId(sessionId);
        if (d != null) {
          applyFields(
            body: d.body, m: d.mood, tg: d.tags,
            a: d.anchor ?? const Anchor(), date: d.entryDate,
          );
          restored.value = true;
        } else {
          applyFields(
            body: entry.body, m: entry.mood, tg: entry.tags,
            a: entry.anchor ?? const Anchor(), date: entry.createdAt,
          );
        }
        hydrated.value = true;
      }
      return null;
    }, [entry]);

    // Orphan guard — entry was deleted while a draft lingered.
    useEffect(() {
      if (!entriesAsync.isLoading && entry == null) {
        ref.read(draftsProvider.notifier).clear(sessionId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.pop();
        });
      }
      return null;
    }, [entriesAsync.isLoading, entry == null]);

    // ── Draft autosave ─────────────────────────────────────────────────────
    final debounce = useRef<Timer?>(null);

    bool matchesEntry() {
      if (entry == null) return false;
      final curAnchor = anchor.value.isEmpty ? null : anchor.value;
      final sameAnchor = (curAnchor?.toDbString() ?? '') ==
          (entry.anchor?.toDbString() ?? '');
      return bodyCtrl.text.trim() == entry.body &&
          mood.value == entry.mood &&
          listEquals(tags.value, entry.tags) &&
          sameAnchor &&
          entryDate.value == entry.createdAt;
    }

    Draft buildDraft() => Draft(
          id:        sessionId,
          entryId:   id,
          entryDate: entryDate.value,
          body:      bodyCtrl.text,
          mood:      mood.value,
          tags:      tags.value,
          anchor:    anchor.value.isEmpty ? null : anchor.value,
          savedAt:   DateTime.now(),
        );

    void commitDraft() {
      if (!hydrated.value || isSaving.value) return;
      final notifier = ref.read(draftsProvider.notifier);
      if (matchesEntry()) {
        notifier.clear(sessionId);
      } else {
        notifier.save(buildDraft());
      }
    }

    void scheduleSave() {
      if (!hydrated.value) return;
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 700), commitDraft);
    }

    // Persist on background/kill and on dispose.
    useEffect(() {
      final observer = LifecycleObserver(() {
        debounce.value?.cancel();
        commitDraft();
      });
      WidgetsBinding.instance.addObserver(observer);
      return () {
        WidgetsBinding.instance.removeObserver(observer);
        debounce.value?.cancel();
        commitDraft();
      };
    }, const []);

    // Debounced tag extraction only
    useEffect(() {
      Timer? debounce;
      void listener() {
        scheduleSave();
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 400), () {
          final newBody = Set<String>.from(
              HashtagController.extractTags(bodyCtrl.text));
          final removed = bodyTags.value.difference(newBody);
          final added   = newBody.difference(bodyTags.value);
          if (removed.isEmpty && added.isEmpty) return;
          final current = tags.value.toList()
            ..removeWhere((t) => removed.any(
                (r) => r.toLowerCase() == t.toLowerCase()));
          for (final a in added) {
            if (!current.any((t) => t.toLowerCase() == a.toLowerCase())) {
              current.add(a);
            }
          }
          bodyTags.value = newBody;
          tags.value = current;
        });
      }
      bodyCtrl.addListener(listener);
      return () {
        bodyCtrl.removeListener(listener);
        debounce?.cancel();
      };
    }, [bodyCtrl]);

    // Autosave when date/time changes.
    useEffect(() {
      void l() => scheduleSave();
      entryDate.addListener(l);
      return () => entryDate.removeListener(l);
    }, [entryDate]);

    Future<void> save() async {
      if (entry == null || bodyCtrl.text.trim().isEmpty || isSaving.value) return;
      isSaving.value = true;
      debounce.value?.cancel();
      try {
        await ref.read(entriesProvider.notifier).updateEntry(entry.copyWith(
          createdAt: entryDate.value,
          updatedAt: DateTime.now(),
          body:      bodyCtrl.text.trim(),
          mood:      mood.value,
          tags:      tags.value,
          wordCount: countWords(bodyCtrl.text),
          anchor:    anchor.value.isEmpty ? null : anchor.value,
        ));
        await ref.read(draftsProvider.notifier).clear(sessionId);
        if (context.mounted) context.pop();
      } finally {
        isSaving.value = false;
      }
    }

    void discardRestored() {
      if (entry == null) return;
      applyFields(
        body: entry.body, m: entry.mood, tg: entry.tags,
        a: entry.anchor ?? const Anchor(), date: entry.createdAt,
      );
      ref.read(draftsProvider.notifier).clear(sessionId);
      restored.value = false;
    }

    if (entriesAsync.isLoading || entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.onBackground),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: isSaving.value
                ? const SizedBox(
                    width: 60, height: 32,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : ValueListenableBuilder<TextEditingValue>(
                    valueListenable: bodyCtrl,
                    builder: (_, value, __) {
                      final canSave = value.text.trim().isNotEmpty;
                      return Material(
                        color: canSave ? t.primary : t.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: canSave ? save : null,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            child: Text('Save',
                                style: TextStyle(fontFamily: 'Caveat',
                                  fontSize: 17, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Collapsible metadata (stamp / mood / tags) ───────────────────
          ValueListenableBuilder<DateTime>(
            valueListenable: entryDate,
            builder: (_, dateVal, __) => EditorMeta(
              collapsed: bodyFocused.value,
              onTapSummary: () => bodyFocus.unfocus(),
              dateLabel: DateFormat('EEE, MMM d').format(dateVal),
              timeLabel: DateFormat.jm().format(dateVal),
              mood: mood.value,
              tagCount: tags.value.length,
              expanded: [
                _StampRow(entryDate: entryDate),
                Divider(color: t.outline, height: 1),
                MoodSelector(
                  selected: mood.value,
                  onChanged: (m) { mood.value = m; scheduleSave(); },
                ),
                Divider(color: t.outline, height: 1),
                TagInputField(
                  tags: tags.value,
                  onChanged: (updated) { tags.value = updated; scheduleSave(); },
                ),
              ],
            ),
          ),

          // ── Restored-draft banner ────────────────────────────────────────
          if (restored.value)
            _RestoredBanner(
              onDiscard: discardRestored,
              onDismiss: () => restored.value = false,
            ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: RepaintBoundary(child: LinedPaperBackground(
              ruleColor: ruleColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  controller: bodyCtrl,
                  focusNode: bodyFocus,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: t.onBackground, height: 1.75, fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    border:             InputBorder.none,
                    enabledBorder:      InputBorder.none,
                    focusedBorder:      InputBorder.none,
                    disabledBorder:     InputBorder.none,
                    errorBorder:        InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled:             false,
                    isCollapsed:        true,
                    hintText: 'Write something…',
                    hintStyle: TextStyle(fontFamily: 'Lora',
                      fontSize: 17, fontStyle: FontStyle.italic,
                      color: t.onSurfaceMuted),
                  ),
                ),
              ),
            ),
          )),

          // ── Anchor bar ──────────────────────────────────────────────────
          AnchorBar(
            anchor: anchor.value,
            onChanged: (a) { anchor.value = a; scheduleSave(); },
          ),

          // ── Counter — isolated, zero parent rebuild ───────────────────────
          WordCounterBar(
            controller: bodyCtrl,
            outline: t.outline,
            bg: t.background,
            muted: t.onSurfaceMuted,
          ),
        ],
      ),
    );
  }

}

// ── Date/time stamp row ──────────────────────────────────────────────────────

class _StampRow extends StatelessWidget {
  final ValueNotifier<DateTime> entryDate;
  const _StampRow({required this.entryDate});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ValueListenableBuilder<DateTime>(
      valueListenable: entryDate,
      builder: (ctx, date, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(
          children: [
            Text(DateFormat('EEEE, MMMM d').format(date),
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 16, fontWeight: FontWeight.w500,
                  color: t.onBackground)),
            const Spacer(),
            GestureDetector(
              onTap: () => pickTime(ctx, entryDate),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat.jm().format(date),
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: t.primary)),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: t.onSurfaceMuted),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restored-draft banner ────────────────────────────────────────────────────

class _RestoredBanner extends StatelessWidget {
  final VoidCallback onDiscard;
  final VoidCallback onDismiss;
  const _RestoredBanner({required this.onDiscard, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      color: t.primaryContainer,
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: 16, color: t.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Restored unsaved changes',
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 15, color: t.onBackground)),
          ),
          TextButton(
            onPressed: onDiscard,
            child: Text('Discard',
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 15, fontWeight: FontWeight.w700, color: t.primary)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, size: 18, color: t.onSurfaceMuted),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
