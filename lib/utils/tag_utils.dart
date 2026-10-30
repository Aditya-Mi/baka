import 'package:flutter/material.dart';

import 'package:baka/models/tag.dart';

/// Tags are case-insensitive: '#SOLO' and '#solo' are the same tag.
/// Lowercases, trims and de-duplicates while keeping first-seen order.
List<String> normalizeTags(Iterable<String> tags) {
  final seen = <String>{};
  return [
    for (final t in tags)
      if (t.trim().isNotEmpty && seen.add(t.trim().toLowerCase()))
        t.trim().toLowerCase(),
  ];
}

Color tagColorFor(List<Tag> tags, String name) {
  final key = name.toLowerCase();
  for (final t in tags) {
    if (t.name.toLowerCase() == key) return t.color;
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
