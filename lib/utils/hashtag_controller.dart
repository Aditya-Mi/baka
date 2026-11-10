import 'package:flutter/material.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/utils/note_marks.dart';

/// The page's TextEditingController: styles tags, people, links, page
/// references and line marks as they're typed (see [noteLines]).
/// Caches the last built TextSpan — Flutter calls buildTextSpan multiple times
/// per frame; skipping redundant regex runs on unchanged text is the single
/// biggest editor performance win.
class HashtagController extends TextEditingController {
  Color highlightColor;

  HashtagController({required this.highlightColor});

  /// Forces TextSpan cache to rebuild on next frame (e.g. after color change).
  void invalidate() => notifyListeners();

  static final _completedPattern = RegExp(r'#(\w+)(?=\W|$)');

  // Cache — invalidated when text, highlight color or theme changes.
  String? _cachedText;
  Color?  _cachedColor;
  BakaTokens? _cachedTokens;
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
        context.tokens == _cachedTokens &&
        _cachedSpan != null) {
      return _cachedSpan!;
    }

    _cachedText  = text;
    _cachedColor = highlightColor;
    _cachedTokens = context.tokens;
    _cachedSpan  = _buildSpan(context, text, style);
    return _cachedSpan!;
  }

  /// The page's marks, styled in place: the text itself never changes, so
  /// the caret and selection stay true. List marks and checkboxes go
  /// terracotta, done items fade, quotes lean, stamps go handwritten,
  /// people go sage and [[page]] names take the title face.
  TextSpan _buildSpan(BuildContext context, String text, TextStyle? style) {
    final base   = style ?? const TextStyle();
    final t      = context.tokens;
    final mark   = base.copyWith(color: t.primary, fontWeight: FontWeight.w700);
    final faded  = base.copyWith(color: t.onSurfaceMuted);
    final size   = base.fontSize ?? 17;
    final line   = size * (base.height ?? 1.75);
    final stamp  = AppText.caption(context).copyWith(
        color: t.onSurfaceMuted, fontSize: size + 2, height: line / (size + 2));
    final title  = base.copyWith(
        fontFamily: AppText.heading(context).fontFamily,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400);

    List<InlineSpan> inline(String s, TextStyle runStyle) => [
          for (final tok in tokenize(s))
            switch (tok.mark) {
              Mark.plain  => TextSpan(text: tok.text, style: runStyle),
              Mark.tag    => TextSpan(text: tok.text, style: runStyle.copyWith(
                  color: highlightColor, fontWeight: FontWeight.bold)),
              Mark.person => TextSpan(text: tok.text, style: runStyle.copyWith(
                  color: t.onSecondaryContainer, fontWeight: FontWeight.w600)),
              Mark.link   => TextSpan(text: tok.text, style: runStyle.copyWith(
                  color: t.primaryText,
                  decoration: TextDecoration.underline,
                  decorationColor: t.primaryText.withValues(alpha: 0.45))),
              Mark.page   => TextSpan(children: [
                  TextSpan(text: '[[', style: faded),
                  TextSpan(text: tok.text.substring(2, tok.text.length - 2), style: title),
                  TextSpan(text: ']]', style: faded),
                ]),
            },
        ];

    final spans = <InlineSpan>[];
    final lines = noteLines(text);
    for (final (i, l) in lines.indexed) {
      final raw = text.substring(l.start,
          i + 1 < lines.length ? lines[i + 1].start - 1 : text.length);
      switch (l.kind) {
        case LineKind.text:
          spans.addAll(inline(raw, base));
        case LineKind.stamp:
          spans.add(TextSpan(text: raw, style: stamp));
        case LineKind.done:
          spans.add(TextSpan(text: l.marker, style: mark.copyWith(fontWeight: FontWeight.w400)));
          spans.addAll(inline(l.text, faded.copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: t.onSurfaceMuted)));
        case LineKind.check:
          spans.add(TextSpan(text: l.marker, style: mark.copyWith(fontWeight: FontWeight.w400)));
          spans.addAll(inline(l.text, base));
        case LineKind.quote:
          spans.add(TextSpan(text: l.marker, style: mark));
          spans.addAll(inline(l.text, base.copyWith(fontStyle: FontStyle.italic)));
        case LineKind.bullet || LineKind.numbered:
          spans.add(TextSpan(text: l.marker, style: mark));
          spans.addAll(inline(l.text, base));
      }
      if (i + 1 < lines.length) spans.add(TextSpan(text: '\n', style: base));
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
