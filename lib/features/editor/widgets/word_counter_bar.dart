import 'package:flutter/material.dart';

import 'package:baka/utils/word_counter.dart';

/// Word/char counter bar — uses [ValueListenableBuilder] so only this widget
/// rebuilds on text changes, not the entire editor screen.
class WordCounterBar extends StatelessWidget {
  final TextEditingController controller;
  final Color outline;
  final Color bg;
  final Color muted;

  const WordCounterBar({
    super.key,
    required this.controller,
    required this.outline,
    required this.bg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, __) {
        final words = countWords(value.text);
        final chars = value.text.length;
        return Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: outline, width: 0.8)),
            color: bg,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text('$words words',
                      style: TextStyle(fontFamily: 'CourierPrime',
                        fontSize: 12, color: muted)),
                  const SizedBox(width: 16),
                  Text('$chars chars',
                      style: TextStyle(fontFamily: 'CourierPrime',
                        fontSize: 12, color: muted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
