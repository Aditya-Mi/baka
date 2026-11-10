import 'dart:convert';

import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 6);

/// GETs [uri] as a browser would. Null on any failure or non-200.
Future<http.Response?> fetchUrl(Uri uri) async {
  try {
    final res = await http
        .get(uri, headers: const {'User-Agent': 'Mozilla/5.0'})
        .timeout(_timeout);
    return res.statusCode == 200 ? res : null;
  } catch (_) {
    return null;
  }
}

/// [res]'s body as UTF-8, whatever charset the server claims (or doesn't).
String bodyText(http.Response res) => utf8.decode(res.bodyBytes, allowMalformed: true);

Future<Map<String, dynamic>?> fetchJson(Uri uri) async {
  final res = await fetchUrl(uri);
  try {
    return res == null ? null : jsonDecode(bodyText(res)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<String?> fetchHtml(Uri uri) async {
  final res = await fetchUrl(uri);
  return res == null ? null : bodyText(res);
}

/// A page's own `<meta property|name="[name]" content="…">` value, in
/// whichever order the page writes the attributes.
String? pageMeta(String html, String name) {
  for (final m in RegExp(r'<meta\b[^>]*>', caseSensitive: false).allMatches(html)) {
    final tag = m.group(0)!;
    final key = _attr(tag, 'property') ?? _attr(tag, 'name');
    if (key?.toLowerCase() != name) continue;
    final v = _attr(tag, 'content');
    final clean = v == null ? null : unescapeHtml(v).trim();
    if (clean != null && clean.isNotEmpty) return clean;
  }
  return null;
}

/// The page's `<title>`, for pages without og tags.
String? pageTitle(String html) {
  final m = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false).firstMatch(html);
  final v = m == null ? null : unescapeHtml(m.group(1)!).replaceAll(RegExp(r'\s+'), ' ').trim();
  return v == null || v.isEmpty ? null : v;
}

String? _attr(String tag, String name) {
  final m = RegExp('(?:^|\\s)$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')', caseSensitive: false)
      .firstMatch(tag);
  return m == null ? null : (m.group(1) ?? m.group(2));
}

String unescapeHtml(String s) => s
    .replaceAllMapped(RegExp(r'&#x([0-9a-f]+);', caseSensitive: false),
        (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&');
