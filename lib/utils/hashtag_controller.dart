import 'package:flutter/material.dart';

/// TextEditingController that highlights #word tokens bold + primary color.
/// Caches the last built TextSpan — Flutter calls buildTextSpan multiple times
/// per frame; skipping redundant regex runs on unchanged text is the single
/// biggest editor performance win.
class HashtagController extends TextEditingController {
  Color highlightColor;

  HashtagController({required this.highlightColor});

  /// Forces TextSpan cache to rebuild on next frame (e.g. after color change).
  void invalidate() => notifyListeners();

  static final _pattern          = RegExp(r'#\w+');
  static final _completedPattern = RegExp(r'#(\w+)(?=\s)');

  // Cache — invalidated when text or highlight color changes.
  String? _cachedText;
  Color?  _cachedColor;
  TextSpan? _cachedSpan;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = value.text;

    // Return cached span if nothing changed — avoids redundant regex per frame.
    if (text == _cachedText &&
        highlightColor == _cachedColor &&
        _cachedSpan != null) {
      return _cachedSpan!;
    }

    _cachedText  = text;
    _cachedColor = highlightColor;
    _cachedSpan  = _buildSpan(text, style);
    return _cachedSpan!;
  }

  TextSpan _buildSpan(String text, TextStyle? style) {
    if (!_pattern.hasMatch(text)) return TextSpan(text: text, style: style);

    final spans  = <InlineSpan>[];
    int   cursor = 0;

    for (final m in _pattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: style));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: (style ?? const TextStyle()).copyWith(
          color:      highlightColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
    return TextSpan(children: spans, style: style);
  }

  /// Returns tags only for completed words (followed by whitespace).
  static List<String> extractTags(String text) {
    return _completedPattern
        .allMatches(text)
        .map((m) => m.group(1)!)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }
}
