import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:baka/utils/note_marks.dart';

/// Enter on a list item starts the next one ("- ", "4. ", "[ ] ", "> ");
/// Enter on an empty item ends the list instead.
class ListContinuation extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final at = next.selection.baseOffset;
    if (!old.selection.isCollapsed ||
        !next.selection.isCollapsed ||
        next.text.length != old.text.length + 1 ||
        at < 1 ||
        next.text[at - 1] != '\n' ||
        old.text.substring(0, at - 1) != next.text.substring(0, at - 1)) {
      return next;
    }
    final lineStart = old.text.lastIndexOf('\n', at - 2) + 1;
    final line = parseLine(old.text.substring(lineStart, at - 1));
    final kind = line.kind == LineKind.done ? LineKind.check : line.kind;
    if (line.marker.isEmpty || kind == LineKind.stamp) return next;

    if (line.text.trim().isEmpty) {
      // An empty item: drop its mark and stay on that line.
      final text = old.text.replaceRange(lineStart, at - 1, '');
      return TextEditingValue(
          text: text, selection: TextSelection.collapsed(offset: lineStart));
    }
    final mark = markerFor(kind, number: line.number + 1);
    return TextEditingValue(
      text: next.text.replaceRange(at, at, mark),
      selection: TextSelection.collapsed(offset: at + mark.length),
    );
  }
}

/// What's being typed right before the caret, for suggestions.
enum Lookup { person, page }

class ActiveLookup {
  final Lookup kind;
  final String query;
  /// Where the "@" or "[[" starts.
  final int start;
  const ActiveLookup(this.kind, this.query, this.start);
}

final _personQuery = RegExp(r'(?:^|[^\w@.])@([\w-]*)$');
final _pageQuery   = RegExp(r'\[\[([^\[\]\n]*)$');

ActiveLookup? activeLookup(TextEditingValue v) {
  final at = v.selection.baseOffset;
  if (!v.selection.isCollapsed || at < 1 || at > v.text.length) return null;
  final before = v.text.substring(0, at);
  if (_pageQuery.firstMatch(before) case final m?) {
    return ActiveLookup(Lookup.page, m.group(1)!, m.start);
  }
  if (_personQuery.firstMatch(before) case final m?) {
    final q = m.group(1)!;
    return ActiveLookup(Lookup.person, q, at - q.length - 1);
  }
  return null;
}

extension NoteEditing on TextEditingController {
  int get _caret {
    final s = selection;
    return s.isValid ? s.baseOffset.clamp(0, text.length) : text.length;
  }

  ({int start, int end}) _lineAt(int at) {
    final start = at == 0 ? 0 : text.lastIndexOf('\n', at - 1) + 1;
    final nl = text.indexOf('\n', at);
    return (start: start, end: nl < 0 ? text.length : nl);
  }

  /// The kind of the line the caret is on.
  LineKind get lineKind {
    final r = _lineAt(_caret);
    return parseLine(text.substring(r.start, r.end)).kind;
  }

  /// Makes the caret's line a [kind] item, or plain text if it already is.
  /// Check and done count as one kind here.
  void toggleLine(LineKind kind) {
    final at = _caret;
    final r = _lineAt(at);
    final line = parseLine(text.substring(r.start, r.end));
    final same = line.kind == kind ||
        (kind == LineKind.check && line.kind == LineKind.done);
    final mark = same ? '' : markerFor(kind);
    final delta = mark.length - line.marker.length;
    value = TextEditingValue(
      text: text.replaceRange(r.start, r.start + line.marker.length, mark),
      selection: TextSelection.collapsed(
          offset: (at + delta).clamp(r.start + mark.length, text.length + delta)),
    );
  }

  /// Puts a time stamp on a line of its own at the caret, and the caret on
  /// the line after it.
  void insertStamp(DateTime at) {
    final c = _caret;
    final r = _lineAt(c);
    final lineEmpty = text.substring(r.start, r.end).trim().isEmpty;
    final before = lineEmpty || c == r.start ? '' : '\n';
    final insert = '$before${stampFor(at)}\n';
    final from = lineEmpty ? r.start : c;
    final to = lineEmpty ? r.end : c;
    value = TextEditingValue(
      text: text.replaceRange(from, to, insert),
      selection: TextSelection.collapsed(offset: from + insert.length),
    );
  }

  /// Types [s] at the caret, with a space before it when it would otherwise
  /// stick to a word ("@" after "with" → "with @").
  void typeAtCaret(String s) {
    final c = _caret;
    final pad = c > 0 && !RegExp(r'\s').hasMatch(text[c - 1]) ? ' ' : '';
    final insert = '$pad$s';
    value = TextEditingValue(
      text: text.replaceRange(c, c, insert),
      selection: TextSelection.collapsed(offset: c + insert.length),
    );
  }

  /// Swaps what's typed from [from] to the caret for [s].
  void completeAt(int from, String s) {
    final c = _caret;
    // Eat a "]]" already sitting after the caret.
    final end = text.startsWith(']]', c) ? c + 2 : c;
    final after = end < text.length && text[end] == ' ' ? '' : ' ';
    final insert = '$s$after';
    value = TextEditingValue(
      text: text.replaceRange(from, end, insert),
      selection: TextSelection.collapsed(offset: from + insert.length),
    );
  }
}
