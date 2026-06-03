import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/editor/widgets/anchor_bar.dart';
import 'package:baka/features/editor/widgets/lined_paper_background.dart';
import 'package:baka/features/editor/widgets/word_counter_bar.dart';
import 'package:baka/features/editor/widgets/mood_selector.dart';
import 'package:baka/features/editor/widgets/tag_input_field.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/utils/hashtag_controller.dart';
import 'package:baka/utils/time_picker_util.dart';
import 'package:baka/utils/word_counter.dart';

class EditEntryScreen extends HookConsumerWidget {
  final String id;
  const EditEntryScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final ruleColor = t.rule;

    final entriesAsync = ref.watch(entriesProvider);
    final entry = entriesAsync.valueOrNull?.firstWhere(
      (e) => e.id == id,
      orElse: () => throw StateError('Entry not found'),
    );

    final bodyCtrl = useMemoized(() => HashtagController(highlightColor: t.primary));
    useEffect(() => bodyCtrl.dispose, const []);
    useEffect(() {
      bodyCtrl.highlightColor = t.primary;
      bodyCtrl.invalidate();
      return null;
    }, [t.primary]);

    final mood      = useState<Mood?>(null);
    final tags      = useState<List<String>>([]);
    final anchor    = useState(const Anchor());
    final hydrated  = useState(false);
    final isSaving  = useState(false);
    final entryDate = useState(DateTime.now());

    // Hydrate once
    useEffect(() {
      if (entry != null && !hydrated.value) {
        bodyCtrl.text   = entry.body;
        mood.value      = entry.mood;
        tags.value      = List<String>.from(entry.tags);
        anchor.value    = entry.anchor ?? const Anchor();
        entryDate.value = entry.createdAt;
        hydrated.value  = true;
      }
      return null;
    }, [entry]);

    // Debounced tag extraction only
    useEffect(() {
      Timer? debounce;
      void listener() {
        debounce?.cancel();
        debounce = Timer(const Duration(milliseconds: 400), () {
          final extracted = HashtagController.extractTags(bodyCtrl.text);
          final body = bodyCtrl.text;
          final manual = tags.value.where(
            (t) => !body.contains('#$t'),
          ).toList();
          final merged = [...extracted, ...manual.where(
            (m) => !extracted.any((e) => e.toLowerCase() == m.toLowerCase()),
          )];
          if (merged.join() != tags.value.join()) tags.value = merged;
        });
      }
      bodyCtrl.addListener(listener);
      return () {
        bodyCtrl.removeListener(listener);
        debounce?.cancel();
      };
    }, [bodyCtrl]);

    Future<void> save() async {
      if (entry == null || bodyCtrl.text.trim().isEmpty || isSaving.value) return;
      isSaving.value = true;
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
        if (context.mounted) context.pop();
      } finally {
        isSaving.value = false;
      }
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
          // ── Stamp ────────────────────────────────────────────────────────
          ValueListenableBuilder<DateTime>(
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
          ),

          Divider(color: t.outline, height: 1),
          MoodSelector(selected: mood.value, onChanged: (m) => mood.value = m),
          Divider(color: t.outline, height: 1),
          TagInputField(tags: tags.value, onChanged: (updated) => tags.value = updated),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: LinedPaperBackground(
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
          ),

          // ── Anchor bar ──────────────────────────────────────────────────
          AnchorBar(
            anchor: anchor.value,
            onChanged: (a) => anchor.value = a,
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
