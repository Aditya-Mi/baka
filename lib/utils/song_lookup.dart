import 'package:baka/utils/web_page.dart';

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

  static Future<SongInfo?> _platform(String url) async {
    final host = Uri.parse(url).host.replaceFirst('www.', '');
    if (host == 'music.apple.com') return _apple(url);
    if (host.endsWith('youtube.com') || host == 'youtu.be') return _youtube(url);
    if (host == 'open.spotify.com' || host == 'spotify.link') return _spotify(url);
    return _page(url);
  }

  /// Any other music site: its og:title is usually the song.
  static Future<SongInfo?> _page(String url) async {
    final html = await fetchHtml(Uri.parse(url));
    final title = html == null ? null : pageMeta(html, 'og:title');
    return title == null ? null : SongInfo(title: title);
  }

  static Future<SongInfo?> _apple(String url) async {
    final uri = Uri.parse(url);
    final id = uri.queryParameters['i'] ??
        (uri.pathSegments.contains('song') ? uri.pathSegments.last : null);
    if (id == null) return null;
    final j = await fetchJson(Uri.https('itunes.apple.com', '/lookup', {'id': id}));
    final r = (j?['results'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final title = r?['trackName'] as String?;
    if (title == null) return null;
    return SongInfo(title: title, artist: r?['artistName'] as String?);
  }

  static Future<SongInfo?> _spotify(String url) async {
    // The track page names the artist; Spotify's oEmbed doesn't.
    final html = await fetchHtml(Uri.parse(url));
    if (html == null) return null;
    final title = pageMeta(html, 'og:title');
    if (title == null) return null;
    // og:description reads "Artist · Album · Song · 2014".
    final artist = pageMeta(html, 'music:musician_description') ??
        pageMeta(html, 'og:description')?.split(' · ').first;
    return SongInfo(title: title, artist: artist);
  }

  static Future<SongInfo?> _youtube(String url) async {
    final j = await fetchJson(Uri.https(
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
