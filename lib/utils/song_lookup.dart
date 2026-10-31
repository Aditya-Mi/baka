import 'dart:convert';
import 'package:http/http.dart' as http;

/// What a song link says about itself.
class SongInfo {
  final String title;
  final String? artist;
  const SongInfo({required this.title, this.artist});
}

/// Turns a song link into a name and artist using each platform's own
/// keyless sources: iTunes lookup, YouTube oEmbed, Spotify's page tags,
/// and any other page's og:title. Never throws: null means type it in.
class SongLookup {
  static final _cache = <String, SongInfo?>{};
  static const _timeout = Duration(seconds: 6);

  /// True for anything worth sending out: an http(s) link with a real host.
  static bool looksLikeLink(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.contains('.');
  }

  static Future<SongInfo?> find(String url) async {
    url = url.trim();
    if (!looksLikeLink(url)) return null;
    if (_cache.containsKey(url)) return _cache[url];
    final info = await _platform(url);
    // Misses aren't cached: they're often a dropped connection.
    if (info != null) _cache[url] = info;
    return info;
  }

  static Future<http.Response?> _get(Uri uri) async {
    try {
      final res = await http
          .get(uri, headers: const {'User-Agent': 'Mozilla/5.0'})
          .timeout(_timeout);
      return res.statusCode == 200 ? res : null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _getJson(Uri uri) async {
    final res = await _get(uri);
    try {
      return res == null ? null : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<SongInfo?> _platform(String url) async {
    final host = Uri.parse(url).host.replaceFirst('www.', '');
    if (host == 'music.apple.com') return _apple(url);
    if (host.endsWith('youtube.com') || host == 'youtu.be') return _youtube(url);
    if (host == 'open.spotify.com' || host == 'spotify.link') return _spotify(url);
    return _page(url);
  }

  /// A page's own `<meta property="name" content="…">` value.
  static String? _meta(String html, String name) {
    final m = RegExp('<meta[^>]+(?:property|name)="${RegExp.escape(name)}"[^>]+content="([^"]*)"')
        .firstMatch(html);
    final v = m == null ? null : _unescape(m.group(1)!).trim();
    return v == null || v.isEmpty ? null : v;
  }

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  /// Any other music site: its og:title is usually the song.
  static Future<SongInfo?> _page(String url) async {
    final res = await _get(Uri.parse(url));
    final title = res == null ? null : _meta(res.body, 'og:title');
    return title == null ? null : SongInfo(title: title);
  }

  static Future<SongInfo?> _apple(String url) async {
    final uri = Uri.parse(url);
    final id = uri.queryParameters['i'] ??
        (uri.pathSegments.contains('song') ? uri.pathSegments.last : null);
    if (id == null) return null;
    final j = await _getJson(Uri.https('itunes.apple.com', '/lookup', {'id': id}));
    final r = (j?['results'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final title = r?['trackName'] as String?;
    if (title == null) return null;
    return SongInfo(title: title, artist: r?['artistName'] as String?);
  }

  static Future<SongInfo?> _spotify(String url) async {
    // The track page names the artist; Spotify's oEmbed doesn't.
    final res = await _get(Uri.parse(url));
    if (res == null) return null;
    final title = _meta(res.body, 'og:title');
    if (title == null) return null;
    // og:description reads "Artist · Album · Song · 2014".
    final artist = _meta(res.body, 'music:musician_description') ??
        _meta(res.body, 'og:description')?.split(' · ').first;
    return SongInfo(title: title, artist: artist);
  }

  static Future<SongInfo?> _youtube(String url) async {
    final j = await _getJson(Uri.https(
        'www.youtube.com', '/oembed', {'url': url, 'format': 'json'}));
    var title = j?['title'] as String?;
    if (title == null) return null;
    var artist = (j?['author_name'] as String?)
        ?.replaceAll(RegExp(r'\s*-\s*Topic$|VEVO$'), '')
        .trim();
    // "Cigarettes After Sex - Cry (Official Video) | 4K" → artist, "Cry"
    title = title
        .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '')
        .split(RegExp(r'\s+\|\s+'))
        .first
        .trim();
    final dash = RegExp(r'\s+[-–—]\s+').firstMatch(title);
    if (dash != null) {
      artist = title.substring(0, dash.start).trim();
      title = title.substring(dash.end).trim();
    }
    return SongInfo(title: title, artist: artist?.isEmpty == true ? null : artist);
  }
}
