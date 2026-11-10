import 'package:intl/intl.dart';

import 'package:baka/models/journal_entry.dart';
import 'package:baka/utils/links.dart';

/// The marks a page can carry, all plain text so the note reads anywhere:
///
///   - a list item        1. a numbered item     [ ] to do     [x] done
///   > a quoted line      — 5:40 PM —  (a time stamp, alone on its line)
///   #tag   @person   [[Page title]]   https://links
enum LineKind { text, bullet, numbered, check, done, quote, stamp }

class NoteLine {
  final LineKind kind;
  /// The mark at the start of the line, as written ("- ", "[ ] ", "3. ").
  final String marker;
  /// The line without its mark (for a stamp, the time).
  final String text;
  /// For numbered items, the number written.
  final int number;
  /// Where the line starts in the body.
  final int start;
  const NoteLine(this.kind, this.marker, this.text, this.start, {this.number = 0});

  bool get isItem => kind == LineKind.bullet || kind == LineKind.numbered ||
      kind == LineKind.check || kind == LineKind.done;
}

final _bullet   = RegExp(r'^[-*•] (?!\[[ xX]\] )');
final _check    = RegExp(r'^(?:- )?\[ \] ');
final _done     = RegExp(r'^(?:- )?\[[xX]\] ');
final _numbered = RegExp(r'^(\d{1,3})[.)] ');
final _quote    = RegExp(r'^> ?');
final _stamp    = RegExp(r'^— (.+) —$');

/// What [line] is, and where its mark ends.
NoteLine parseLine(String line, [int start = 0]) {
  if (_stamp.firstMatch(line) case final m?) {
    return NoteLine(LineKind.stamp, line, m.group(1)!, start);
  }
  for (final (re, kind) in [
    (_check, LineKind.check),
    (_done, LineKind.done),
    (_bullet, LineKind.bullet),
    (_quote, LineKind.quote),
  ]) {
    if (re.matchAsPrefix(line) case final m?) {
      return NoteLine(kind, m.group(0)!, line.substring(m.end), start);
    }
  }
  if (_numbered.matchAsPrefix(line) case final m?) {
    return NoteLine(LineKind.numbered, m.group(0)!, line.substring(m.end), start,
        number: int.parse(m.group(1)!));
  }
  return NoteLine(LineKind.text, '', line, start);
}

List<NoteLine> noteLines(String body) {
  final out = <NoteLine>[];
  var start = 0;
  for (final line in body.split('\n')) {
    out.add(parseLine(line, start));
    start += line.length + 1;
  }
  return out;
}

/// The mark a new line of [kind] starts with.
String markerFor(LineKind kind, {int number = 1}) => switch (kind) {
      LineKind.bullet   => '- ',
      LineKind.numbered => '$number. ',
      LineKind.check    => '[ ] ',
      LineKind.done     => '[x] ',
      LineKind.quote    => '> ',
      _                 => '',
    };

/// A time stamp line for [at]: "— 5:40 PM —".
String stampFor(DateTime at) => '— ${DateFormat.jm().format(at)} —';

// ── Inline marks ─────────────────────────────────────────────────────────────

/// @name: letters first, then letters, digits, _ or -. Not inside an email.
final personPattern = RegExp(r'(?<![\w@.])@([A-Za-z][\w]*(?:-[\w]+)*)');
final tagPattern    = RegExp(r'#\w+');
final pagePattern   = RegExp(r'\[\[([^\[\]\n]+?)\]\]');

enum Mark { plain, tag, person, page, link }

class Token {
  final Mark mark;
  final String text;
  final int start, end;
  /// The person's name, the page reference, or the link, without its marks.
  final String value;
  const Token(this.mark, this.text, this.start, this.end, this.value);
}

/// [text] cut into plain runs and marks. Links and page references win over
/// anything inside them (a #fragment in a URL is not a tag).
List<Token> tokenize(String text) {
  final marks = <Token>[];
  void claim(Token t) {
    if (marks.any((m) => t.start < m.end && m.start < t.end)) return;
    marks.add(t);
  }

  for (final l in findLinks(text)) {
    claim(Token(Mark.link, l.text, l.start, l.end, l.text));
  }
  for (final m in pagePattern.allMatches(text)) {
    claim(Token(Mark.page, m.group(0)!, m.start, m.end, m.group(1)!.trim()));
  }
  for (final m in personPattern.allMatches(text)) {
    claim(Token(Mark.person, m.group(0)!, m.start, m.end, m.group(1)!.toLowerCase()));
  }
  for (final m in tagPattern.allMatches(text)) {
    claim(Token(Mark.tag, m.group(0)!, m.start, m.end, m.group(0)!.substring(1)));
  }
  marks.sort((a, b) => a.start.compareTo(b.start));

  final out = <Token>[];
  var cursor = 0;
  for (final m in marks) {
    if (m.start > cursor) {
      out.add(Token(Mark.plain, text.substring(cursor, m.start), cursor, m.start, ''));
    }
    out.add(m);
    cursor = m.end;
  }
  if (cursor < text.length) {
    out.add(Token(Mark.plain, text.substring(cursor), cursor, text.length, ''));
  }
  return out;
}

/// Everyone written about in [body], lowercased, first-seen order.
List<String> peopleIn(String body) => {
      for (final t in tokenize(body))
        if (t.mark == Mark.person) t.value,
    }.toList();

/// Every [[page]] [body] points to, as written.
List<String> pageRefsIn(String body) => [
      for (final m in pagePattern.allMatches(body)) m.group(1)!.trim(),
    ];

// ── Page references ──────────────────────────────────────────────────────────

final _refDate = DateFormat('MMM d, y');

/// How a page is pointed to: its title, or for an untitled page its day.
String pageRefFor(JournalEntry e) => e.title ?? _refDate.format(e.createdAt);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The page [ref] points to: the latest page with that title, else the first
/// page written on that day.
JournalEntry? resolvePageRef(String ref, Iterable<JournalEntry> entries) {
  final key = ref.trim().toLowerCase();
  JournalEntry? best;
  for (final e in entries) {
    if (e.title?.toLowerCase() == key &&
        (best == null || e.createdAt.isAfter(best.createdAt))) {
      best = e;
    }
  }
  if (best != null) return best;
  final day = () {
    try {
      return _refDate.parseLoose(ref.trim());
    } catch (_) {
      return null;
    }
  }();
  if (day == null) return null;
  for (final e in entries) {
    if (_sameDay(e.createdAt, day) &&
        (best == null || e.createdAt.isBefore(best.createdAt))) {
      best = e;
    }
  }
  return best;
}

/// The pages that point to [entry], newest first.
List<JournalEntry> mentionsOf(JournalEntry entry, Iterable<JournalEntry> entries) {
  final all = entries.toList();
  return [
    for (final e in all)
      if (e.id != entry.id &&
          pageRefsIn(e.body).any((r) => resolvePageRef(r, all)?.id == entry.id))
        e,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

/// [body] with every [[from]] pointing to [to] instead (titles are matched
/// regardless of case). Null when nothing changed.
String? renamePageRefs(String body, String from, String to) {
  final key = from.trim().toLowerCase();
  var changed = false;
  final out = body.replaceAllMapped(pagePattern, (m) {
    if (m.group(1)!.trim().toLowerCase() != key) return m.group(0)!;
    changed = true;
    return '[[$to]]';
  });
  return changed ? out : null;
}

// ── Plain reading ────────────────────────────────────────────────────────────

/// [body] without its marks: what's counted as words and shown as a lead.
String stripMarks(String body) => [
      for (final l in noteLines(body))
        if (l.kind != LineKind.stamp)
          l.text.replaceAllMapped(pagePattern, (m) => m.group(1)!),
    ].join('\n');

/// The body's first line as a one-line lead: no marks, and any link shown
/// as its site ("Read en.wikipedia.org"), since a whole address won't fit.
String leadLine(String body) {
  final line = stripMarks(body).trim().split('\n').first.trim();
  final out = StringBuffer();
  var cursor = 0;
  for (final l in findLinks(line)) {
    final host = linkUri(l.text)?.host.replaceFirst(RegExp(r'^www\.'), '');
    out
      ..write(line.substring(cursor, l.start))
      ..write(host ?? l.text);
    cursor = l.end;
  }
  return (out..write(line.substring(cursor))).toString();
}
