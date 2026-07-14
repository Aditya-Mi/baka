import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/prompts/writing_prompts.dart';
import 'package:baka/features/editor/widgets/anchor_bar.dart';
import 'package:baka/features/editor/widgets/editor_meta.dart';
import 'package:baka/features/editor/widgets/lined_paper_background.dart';
import 'package:baka/features/editor/widgets/mood_selector.dart';
import 'package:baka/features/editor/widgets/tag_input_field.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/models/draft.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/draft_provider.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/features/editor/widgets/word_counter_bar.dart';
import 'package:baka/utils/hashtag_controller.dart';
import 'package:baka/utils/lifecycle_observer.dart';
import 'package:baka/utils/time_picker_util.dart';
import 'package:baka/utils/word_counter.dart';
import 'package:baka/core/fonts/font_theme.dart';

class NewEntryScreen extends HookConsumerWidget {
  final String? source;
  final String? date;
  final String? resumeDraftId;

  const NewEntryScreen({super.key, this.source, this.date, this.resumeDraftId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final ruleColor = t.rule;

    // Draft session id — reuse the resumed one, else mint a fresh uuid.
    final sessionId = useMemoized(
        () => resumeDraftId ?? const Uuid().v4(), const []);

    final initialDate = useMemoized(() => _parseDate(date), const []);
    final entryDate   = useState(initialDate);

    final bodyCtrl = useMemoized(() => HashtagController(highlightColor: t.primary));
    useEffect(() => bodyCtrl.dispose, const []);
    useEffect(() {
      bodyCtrl.highlightColor = t.primary;
      bodyCtrl.invalidate();
      return null;
    }, [t.primary]);

    final mood     = useState<Mood?>(null);
    final tags     = useState<List<String>>([]);
    // Tracks which tags were extracted from body (vs manually added via chip input).
    final bodyTags = useState<Set<String>>({});
    final anchor   = useState(const Anchor());
    final isSaving = useState(false);

    // Body focus drives the collapsible metadata header.
    final bodyFocus   = useFocusNode();
    final bodyFocused = useState(false);
    useEffect(() {
      void l() => bodyFocused.value = bodyFocus.hasFocus;
      bodyFocus.addListener(l);
      return () => bodyFocus.removeListener(l);
    }, [bodyFocus]);

    // ── Draft autosave ─────────────────────────────────────────────────────
    final debounce = useRef<Timer?>(null);
    final hydrated = useState(false);

    Draft buildDraft() => Draft(
          id:        sessionId,
          entryDate: entryDate.value,
          body:      bodyCtrl.text,
          mood:      mood.value,
          tags:      tags.value,
          anchor:    anchor.value.isEmpty ? null : anchor.value,
          savedAt:   DateTime.now(),
        );

    void flushDraft() {
      debounce.value?.cancel();
      if (!hydrated.value || isSaving.value) return;
      ref.read(draftsProvider.notifier).save(buildDraft());
    }

    void scheduleSave() {
      if (!hydrated.value) return;
      debounce.value?.cancel();
      debounce.value = Timer(const Duration(milliseconds: 700), () {
        if (isSaving.value) return;
        ref.read(draftsProvider.notifier).save(buildDraft());
      });
    }

    // Hydrate once from a resumed draft, then enable autosave.
    useEffect(() {
      if (resumeDraftId != null) {
        final d = ref.read(draftsProvider.notifier).byId(resumeDraftId!);
        if (d != null) {
          bodyCtrl.text   = d.body;
          mood.value      = d.mood;
          tags.value      = List<String>.from(d.tags);
          bodyTags.value  = Set<String>.from(
              HashtagController.extractTags(d.body));
          anchor.value    = d.anchor ?? const Anchor();
          entryDate.value = d.entryDate;
        }
      }
      hydrated.value = true;
      return null;
    }, const []);

    // Persist on background/kill and on dispose.
    useEffect(() {
      final observer = LifecycleObserver(flushDraft);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        WidgetsBinding.instance.removeObserver(observer);
        debounce.value?.cancel();
        flushDraft();
      };
    }, const []);

    // Debounced tag extraction — does NOT touch parent state on every keystroke.
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
      if (bodyCtrl.text.trim().isEmpty || isSaving.value) return;
      isSaving.value = true;
      debounce.value?.cancel();
      try {
        await ref.read(entriesProvider.notifier).add(JournalEntry(
          id:        const Uuid().v4(),
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

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.onBackground),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Save button rebuilds only when text or isSaving changes
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
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            child: Text('Save',
                                style: TextStyle(fontFamily: context.fonts.accent,
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
          // ── Collapsible metadata (date / mood / tags) ───────────────────
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
                _DateRow(entryDate: entryDate),
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

          // ── Body ────────────────────────────────────────────────────────
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
                    border:           InputBorder.none,
                    enabledBorder:    InputBorder.none,
                    focusedBorder:    InputBorder.none,
                    disabledBorder:   InputBorder.none,
                    errorBorder:      InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled:           false,
                    isCollapsed:      true,
                    hintText: WritingPrompts.todayPrompt(),
                    hintStyle: TextStyle(fontFamily: context.fonts.body,
                      fontSize: 17, fontStyle: FontStyle.italic,
                      color: t.onSurfaceMuted),
                  ),
                  autofocus: source == 'notification' || date != null,
                ),
              ),
            ),
          )),

          // ── Anchor bar ──────────────────────────────────────────────────
          AnchorBar(
            anchor: anchor.value,
            onChanged: (a) { anchor.value = a; scheduleSave(); },
          ),

          // ── Counter — isolated leaf, zero parent rebuild on typing ───────
          WordCounterBar(controller: bodyCtrl, outline: t.outline, bg: t.background, muted: t.onSurfaceMuted),
        ],
      ),
    );
  }

  static DateTime _parseDate(String? date) {
    if (date != null) {
      try {
        final p   = date.split('-');
        final now = DateTime.now();
        return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]),
            now.hour, now.minute);
      } catch (_) {}
    }
    return DateTime.now();
  }
}

// ── Date row — only rebuilds when entryDate changes ──────────────────────────

class _DateRow extends StatelessWidget {
  final ValueNotifier<DateTime> entryDate;
  const _DateRow({required this.entryDate});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ValueListenableBuilder<DateTime>(
      valueListenable: entryDate,
      builder: (ctx, date, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Wrap(
          spacing: 8, runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DateChip(
              icon: Icons.calendar_today_outlined,
              label: DateFormat('EEE, MMM d').format(date),
              onTap: null,
            ),
            _DateChip(
              icon: Icons.access_time,
              label: DateFormat.jm().format(date),
              onTap: () => pickTime(ctx, entryDate),
            ),
            Text('tap time to change',
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 14, color: t.onSurfaceMuted,
                  fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

}

// ── Date chip ─────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _DateChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: t.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.primary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: t.primary),
            const SizedBox(width: 7),
            Text(label,
                style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 18, color: t.primary, height: 1)),
          ],
        ),
      ),
    );
  }
}
