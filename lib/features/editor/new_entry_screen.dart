import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/editor/widgets/anchor_bar.dart';
import 'package:baka/features/editor/widgets/lined_paper_background.dart';
import 'package:baka/features/editor/widgets/mood_selector.dart';
import 'package:baka/features/editor/widgets/tag_input_field.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/features/editor/widgets/word_counter_bar.dart';
import 'package:baka/utils/hashtag_controller.dart';
import 'package:baka/utils/time_picker_util.dart';
import 'package:baka/utils/word_counter.dart';

class NewEntryScreen extends HookConsumerWidget {
  final String? source;
  final String? date;

  const NewEntryScreen({super.key, this.source, this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final ruleColor = t.rule;

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

    // Debounced tag extraction — does NOT touch parent state on every keystroke.
    useEffect(() {
      Timer? debounce;
      void listener() {
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

    Future<void> save() async {
      if (bodyCtrl.text.trim().isEmpty || isSaving.value) return;
      isSaving.value = true;
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
          // ── Date / time ─────────────────────────────────────────────────
          _DateRow(entryDate: entryDate),

          Divider(color: t.outline, height: 1),

          // ── Mood ────────────────────────────────────────────────────────
          MoodSelector(
            selected: mood.value,
            onChanged: (m) => mood.value = m,
          ),

          Divider(color: t.outline, height: 1),

          // ── Tags ────────────────────────────────────────────────────────
          TagInputField(
            tags: tags.value,
            onChanged: (updated) => tags.value = updated,
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: RepaintBoundary(child: LinedPaperBackground(
              ruleColor: ruleColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: TextField(
                  controller: bodyCtrl,
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
                    hintText: 'Write something…',
                    hintStyle: TextStyle(fontFamily: 'Lora',
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
            onChanged: (a) => anchor.value = a,
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
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 14, color: t.onSurfaceMuted,
                  fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

}

// ── Word/char counter — rebuilds ONLY on text change, not on mood/tag/etc ────

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
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 18, color: t.primary, height: 1)),
          ],
        ),
      ),
    );
  }
}
