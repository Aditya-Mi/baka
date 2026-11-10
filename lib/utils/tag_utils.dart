import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:baka/models/tag.dart';
import 'package:baka/utils/links.dart';

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

/// [text] with #tags in bold [highlightColor] and links in [highlightColor]
/// with a faint underline. With [onLink], links are tappable; their
/// recognizers go into [recognizers] for the caller to dispose.
TextSpan buildTagSpan(
  String text,
  Color highlightColor,
  TextStyle baseStyle, {
  void Function(String link)? onLink,
  List<GestureRecognizer>? recognizers,
}) {
  final spans = <InlineSpan>[];
  void plain(String s) {
    var cursor = 0;
    for (final m in RegExp(r'#\w+').allMatches(s)) {
      if (m.start > cursor) spans.add(TextSpan(text: s.substring(cursor, m.start)));
      spans.add(TextSpan(
        text: m.group(0),
        style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold),
      ));
      cursor = m.end;
    }
    if (cursor < s.length) spans.add(TextSpan(text: s.substring(cursor)));
  }

  final linkStyle = TextStyle(
    color: highlightColor,
    decoration: TextDecoration.underline,
    decorationColor: highlightColor.withValues(alpha: 0.45),
    decorationThickness: 1.2,
  );
  var cursor = 0;
  for (final l in findLinks(text)) {
    if (l.start > cursor) plain(text.substring(cursor, l.start));
    TapGestureRecognizer? tap;
    if (onLink != null) {
      tap = TapGestureRecognizer()..onTap = () => onLink(l.text);
      recognizers?.add(tap);
    }
    spans.add(TextSpan(text: l.text, style: linkStyle, recognizer: tap));
    cursor = l.end;
  }
  if (cursor < text.length) plain(text.substring(cursor));
  return TextSpan(children: spans, style: baseStyle);
}
