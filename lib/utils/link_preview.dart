import 'package:baka/core/db/database_helper.dart';
import 'package:baka/utils/web_page.dart';

/// What a linked page says about itself. [title] is null when the page
/// couldn't be read; [site] always has something, at worst the host.
class LinkPreview {
  final String? title;
  final String site;
  const LinkPreview({this.title, required this.site});
}

/// Reads a page once and keeps what it said, so opening an entry again
/// doesn't go back out. Never throws.
class LinkPreviews {
  static final _memory = <String, LinkPreview>{};
  /// A page that couldn't be read is tried again after this long.
  static const _retryAfter = Duration(days: 1);

  static String _host(Uri uri) => uri.host.replaceFirst(RegExp(r'^www\.'), '');

  /// Already read this session, so a card can start filled in.
  static LinkPreview? known(Uri uri) => _memory[uri.toString()];

  static Future<LinkPreview> find(Uri uri) async {
    final key = uri.toString();
    if (_memory[key] case final p?) return p;

    final saved = await DatabaseHelper.instance.getLinkPreview(key);
    if (saved != null) {
      final title = saved['title'] as String?;
      final age = DateTime.now().millisecondsSinceEpoch - (saved['fetched_at'] as int);
      if (title != null || age < _retryAfter.inMilliseconds) {
        return _memory[key] =
            LinkPreview(title: title, site: (saved['site'] as String?) ?? _host(uri));
      }
    }

    final html = await fetchHtml(uri);
    final title = html == null
        ? null
        : pageMeta(html, 'og:title') ?? pageMeta(html, 'twitter:title') ?? pageTitle(html);
    final site = (html == null ? null : pageMeta(html, 'og:site_name')) ?? _host(uri);
    await DatabaseHelper.instance.putLinkPreview(key, title, site);
    return _memory[key] = LinkPreview(title: title, site: site);
  }
}
