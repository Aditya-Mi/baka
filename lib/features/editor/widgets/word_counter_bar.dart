import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';

import 'package:baka/utils/word_counter.dart';

/// Word/char counter bar — uses [ValueListenableBuilder] so only this widget
/// rebuilds on text changes, not the entire editor screen.
class WordCounterBar extends StatelessWidget {
  final TextEditingController controller;
  final Color outline;
  final Color bg;
  final Color muted;
  /// False when the bar sits under the anchor bar, which owns the hairline.
  final bool showTopBorder;

  const WordCounterBar({
    super.key,
    required this.controller,
    required this.outline,
    required this.bg,
    required this.muted,
    this.showTopBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final words = countWords(value.text);
        return Container(
          decoration: BoxDecoration(
            border: showTopBorder
                ? Border(top: BorderSide(color: outline, width: 0.8))
                : null,
            color: bg,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: showTopBorder
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                  : const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Text('$words words',
                  style: AppText.counter(context).copyWith(
                      color: muted,
                    )),
            ),
          ),
        );
      },
    );
  }
}
