import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/utils/tag_utils.dart';
import 'package:baka/widgets/tag_chip.dart';

/// Horizontal tag row with inline add-tag input.
class TagInputField extends ConsumerStatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagInputField({super.key, required this.tags, required this.onChanged});

  @override
  ConsumerState<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends ConsumerState<TagInputField> {
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _submitTag(String raw) {
    final tag = raw.trim().toLowerCase().replaceAll('#', '');
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      widget.onChanged([...widget.tags, tag]);
    }
    _ctrl.clear();
    setState(() => _editing = false);
  }

  void _removeTag(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final t       = context.tokens;
    final primary = t.primary;
    final tagBg   = t.primaryContainer;
    final outline = t.outline;
    final muted   = t.onSurfaceMuted;
    final onBg    = t.onBackground;
    final tagList = ref.watch(tagsProvider).valueOrNull ?? <Tag>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Existing tags
          ...widget.tags.map((tag) => TagChip(
            tag: tag,
            color: tagColorFor(tagList, tag),
            textColor: t.onBackground,
            onRemove: () => _removeTag(tag),
          )),

          // Inline input when editing
          if (_editing)
            SizedBox(
              width: 100,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 14, fontWeight: FontWeight.w500, color: onBg,
                ),
                decoration: InputDecoration(
                  hintText: 'tag name',
                  hintStyle: TextStyle(fontFamily: 'Caveat',fontSize: 14, color: muted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  filled: true,
                  fillColor: tagBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: primary, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: primary, width: 1),
                  ),
                  prefixText: '#',
                  prefixStyle: TextStyle(fontFamily: 'Caveat',
                    fontSize: 14, fontWeight: FontWeight.w500, color: primary,
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: _submitTag,
                onTapOutside: (_) {
                  if (_ctrl.text.trim().isEmpty) {
                    setState(() => _editing = false);
                  } else {
                    _submitTag(_ctrl.text);
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
              ),
            )
          else
            // "+ add tag" button
            GestureDetector(
              onTap: _startEditing,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: outline, width: 1),
                ),
                child: Text(
                  '+ add tag',
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 13, fontWeight: FontWeight.w500, color: muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

