import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// http(s) and www. links, plus bare domains on common endings
/// ("foo.com/bar"). Not after @, so email addresses stay text.
final _linkPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>"]+'
  r'|(?<![@\w.-])[a-z0-9][a-z0-9-]*(?:\.[a-z0-9-]+)*'
  r'\.(?:com|org|net|io|dev|app|in|co|me|ai|so|xyz|gg|tv|ly|be|fm|to|sh|page|blog|info)\b'
  r'(?:/[^\s<>"]*)?',
  caseSensitive: false,
);

const _trailing = '.,;:!?\'"';

/// The part of [s] that is the link: sentence punctuation after it stays
/// text, and a closing bracket only belongs if one opened inside it.
String _trim(String s) {
  while (s.isNotEmpty) {
    final last = s[s.length - 1];
    final unopened = last == ')' && '('.allMatches(s).length < ')'.allMatches(s).length;
    if (!_trailing.contains(last) && !unopened) break;
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Every link written in [text], in order.
Iterable<({int start, int end, String text})> findLinks(String text) sync* {
  for (final m in _linkPattern.allMatches(text)) {
    final s = _trim(m.group(0)!);
    if (s.isNotEmpty) yield (start: m.start, end: m.start + s.length, text: s);
  }
}

/// [link] as something to open: bare domains and www. get https.
Uri? linkUri(String link) {
  final full = RegExp(r'^https?://', caseSensitive: false).hasMatch(link)
      ? link
      : 'https://$link';
  final uri = Uri.tryParse(full);
  return uri != null && uri.host.contains('.') ? uri : null;
}

/// The links in [text] worth a card: one per address, at most [max].
List<Uri> distinctLinks(String text, {int max = 3}) {
  final seen = <String>{};
  return [
    for (final l in findLinks(text))
      if (linkUri(l.text) case final uri? when seen.add(uri.toString())) uri,
  ].take(max).toList();
}

/// Opens [uri] in the browser, or says so when it can't.
Future<void> openLink(BuildContext context, Uri? uri) async {
  final opened = uri != null &&
      await launchUrl(uri, mode: LaunchMode.externalApplication)
          .catchError((_) => false);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Couldn't open this link")));
  }
}
