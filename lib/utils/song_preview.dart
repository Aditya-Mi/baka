import 'dart:convert';
import 'package:http/http.dart' as http;

/// Rewrites an Apple Music album link with `?i=<trackId>` to a direct
/// song link so it opens the song, not the album. Other URLs pass through.
String normalizeSongUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'music.apple.com') return url;
  final trackId = uri.queryParameters['i'];
  final segs = uri.pathSegments;
  if (trackId == null || !segs.contains('album')) return url;
  final country = segs.isNotEmpty && segs.first.length == 2 ? segs.first : 'us';
  return 'https://music.apple.com/$country/song/$trackId';
}

/// Resolves a ~30s iTunes preview clip URL for a song. Uses the Apple Music
/// track id when the link has one, else searches by name + artist.
class SongPreview {
  static final _cache = <String, String?>{};

  static Future<String?> resolve({
    required String name,
    String? artist,
    String? url,
  }) async {
    final key = '$name|$artist|$url';
    if (_cache.containsKey(key)) return _cache[key];

    String? preview;
    try {
      final trackId = _appleTrackId(url);
      final Uri query = trackId != null
          ? Uri.https('itunes.apple.com', '/lookup', {'id': trackId})
          : Uri.https('itunes.apple.com', '/search', {
              'term': [name, if (artist != null) artist].join(' '),
              'entity': 'song',
              'limit': '1',
            });
      final res = await http.get(query).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final results = (jsonDecode(res.body)['results'] as List?) ?? const [];
        preview = results
            .map((r) => (r as Map<String, dynamic>)['previewUrl'] as String?)
            .firstWhere((p) => p != null, orElse: () => null);
      }
    } catch (_) {
      preview = null;
    }
    if (preview != null) _cache[key] = preview;
    return preview;
  }

  static String? _appleTrackId(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.host != 'music.apple.com') return null;
    final i = uri.queryParameters['i'];
    if (i != null) return i;
    final segs = uri.pathSegments;
    final idx = segs.indexOf('song');
    return idx >= 0 && segs.isNotEmpty ? segs.last : null;
  }
}
