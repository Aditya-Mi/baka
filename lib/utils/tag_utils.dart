import 'package:flutter/material.dart';

import 'package:baka/models/tag.dart';

Color tagColorFor(List<Tag> tags, String name) {
  for (final t in tags) {
    if (t.name == name) return t.color;
  }
  return TagPalette.forName(name);
}

TextSpan buildTagSpan(String text, Color highlightColor, TextStyle baseStyle) {
  final pattern = RegExp(r'#\w+');
  if (!pattern.hasMatch(text)) return TextSpan(text: text, style: baseStyle);

  final spans = <InlineSpan>[];
  int cursor = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
    }
    spans.add(TextSpan(
      text: m.group(0),
      style: baseStyle.copyWith(color: highlightColor, fontWeight: FontWeight.bold),
    ));
    cursor = m.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
  }
  return TextSpan(children: spans, style: baseStyle);
}
