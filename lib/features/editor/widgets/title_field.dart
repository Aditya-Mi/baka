import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';

/// The page's optional name, under the date. Home shows it on the stack in
/// place of the text, so a page can be found without being re-read.
class TitleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  const TitleField({super.key, required this.controller, this.focusNode, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = AppText.heading(context).copyWith(color: t.onBackground, fontSize: 22);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: 1,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => onSubmitted?.call(),
        style: style,
        decoration: InputDecoration(
          hintText: 'Add a title…',
          hintStyle: style.copyWith(
              fontStyle: FontStyle.italic, fontWeight: FontWeight.w400,
              color: t.onSurfaceMuted.withValues(alpha: 0.7)),
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isCollapsed: true,
        ),
      ),
    );
  }
}
