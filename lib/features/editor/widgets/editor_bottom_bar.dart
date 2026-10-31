import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/anchor.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/models/paper.dart';
import 'package:baka/utils/word_counter.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:baka/widgets/motion.dart';
import 'anchor_bar.dart';
import 'mood_selector.dart';
import 'paper_sheet.dart';
import 'tag_input_field.dart';

/// Everything about the page that isn't the writing: mood strip, tags,
/// anchors and the word count, kept under the paper so the page starts
/// right below the date. The mood strip steps aside while typing.
class EditorBottomBar extends StatefulWidget {
  final bool typing;
  final Mood? mood;
  final ValueChanged<Mood> onMood;
  final List<String> tags;
  final ValueChanged<List<String>> onTags;
  final Anchor anchor;
  final ValueChanged<Anchor> onAnchor;
  final TextEditingController body;
  final Paper paper;
  final ValueChanged<Paper> onPaper;

  const EditorBottomBar({
    super.key,
    required this.typing,
    required this.mood,
    required this.onMood,
    required this.tags,
    required this.onTags,
    required this.anchor,
    required this.onAnchor,
    required this.body,
    required this.paper,
    required this.onPaper,
  });

  @override
  State<EditorBottomBar> createState() => _EditorBottomBarState();
}

class _EditorBottomBarState extends State<EditorBottomBar> {
  final _tagField = GlobalKey<TagInputFieldState>();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.background,
        border: Border(top: BorderSide(color: t.outlineSoft, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: Motion.of(context, Motion.fast),
                curve: Motion.curve,
                alignment: Alignment.bottomCenter,
                child: widget.typing
                    ? const SizedBox(width: double.infinity)
                    : MoodSelector(selected: widget.mood, onChanged: widget.onMood),
              ),
              TagInputField(
                key: _tagField,
                tags: widget.tags,
                onChanged: widget.onTags,
              ),
              AnchorBar(
                anchor: widget.anchor,
                onChanged: widget.onAnchor,
                leading: ToolButton(
                  icon: AppIconData.hash,
                  tooltip: 'Add tag',
                  onTap: () => _tagField.currentState?.startEditing(),
                ),
                end: ToolButton(
                  icon: AppIconData.paper,
                  tooltip: 'Paper',
                  onTap: () async {
                    final p = await showPaperSheet(context, current: widget.paper);
                    if (p != null && p != widget.paper) widget.onPaper(p);
                  },
                ),
                trailing: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.body,
                  builder: (context, value, _) {
                    final words = countWords(value.text);
                    return Text(
                      '$words ${words == 1 ? 'word' : 'words'}',
                      style: AppText.counter(context).copyWith(color: t.onSurfaceMuted),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
