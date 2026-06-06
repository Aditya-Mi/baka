import 'dart:convert';

enum WeatherCondition {
  sunny,
  cloudy,
  partlyCloudy,
  rainy,
  stormy,
  snowy,
  foggy,
  windy;

  String get label => switch (this) {
    sunny        => 'Sunny',
    cloudy       => 'Cloudy',
    partlyCloudy => 'Partly cloudy',
    rainy        => 'Rainy',
    stormy       => 'Stormy',
    snowy        => 'Snowy',
    foggy        => 'Foggy',
    windy        => 'Windy',
  };
}

class Anchor {
  /// Display label for location e.g. "Café Blue, Mumbai"
  final String? location;

  final WeatherCondition? weatherCondition;

  /// °C or °F — user decides, just stored as int
  final int? weatherTemp;

  /// Relative path inside app documents dir e.g. "photos/abc123.jpg"
  final String? photoPath;

  /// Song name logged with this entry
  final String? songName;

  /// Artist name (optional)
  final String? songArtist;

  /// Spotify / YouTube / Apple Music URL (optional)
  final String? songUrl;

  const Anchor({
    this.location,
    this.weatherCondition,
    this.weatherTemp,
    this.photoPath,
    this.songName,
    this.songArtist,
    this.songUrl,
  });

  bool get isEmpty =>
      location == null &&
      weatherCondition == null &&
      weatherTemp == null &&
      photoPath == null &&
      songName == null;

  bool get hasLocation => location != null;
  bool get hasWeather  => weatherCondition != null;
  bool get hasPhoto    => photoPath != null;
  bool get hasSong     => songName != null && songName!.isNotEmpty;

  Anchor copyWith({
    Object? location    = _sentinel,
    Object? weather     = _sentinel,
    Object? weatherTemp = _sentinel,
    Object? photoPath   = _sentinel,
    Object? songName    = _sentinel,
    Object? songArtist  = _sentinel,
    Object? songUrl     = _sentinel,
  }) =>
      Anchor(
        location:         location    == _sentinel ? this.location         : location    as String?,
        weatherCondition: weather     == _sentinel ? weatherCondition       : weather     as WeatherCondition?,
        weatherTemp:      weatherTemp == _sentinel ? this.weatherTemp       : weatherTemp as int?,
        photoPath:        photoPath   == _sentinel ? this.photoPath         : photoPath   as String?,
        songName:         songName    == _sentinel ? this.songName          : songName    as String?,
        songArtist:       songArtist  == _sentinel ? this.songArtist        : songArtist  as String?,
        songUrl:          songUrl     == _sentinel ? this.songUrl           : songUrl     as String?,
      );

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        if (location != null)         'location': location,
        if (weatherCondition != null) 'weather': weatherCondition!.name,
        if (weatherTemp != null)      'temp': weatherTemp,
        if (photoPath != null)        'photo': photoPath,
        if (hasSong)                  'songName': songName,
        if (songArtist != null)       'songArtist': songArtist,
        if (songUrl != null)          'songUrl': songUrl,
      };

  factory Anchor.fromJson(Map<String, dynamic> j) => Anchor(
        location: j['location'] as String?,
        weatherCondition: j['weather'] != null
            ? WeatherCondition.values.firstWhere(
                (w) => w.name == j['weather'],
                orElse: () => WeatherCondition.sunny,
              )
            : null,
        weatherTemp: j['temp'] as int?,
        photoPath:   j['photo'] as String?,
        songName:    j['songName'] as String?,
        songArtist:  j['songArtist'] as String?,
        songUrl:     j['songUrl'] as String?,
      );

  /// Encode to JSON string for SQLite storage.
  String toDbString() => jsonEncode(toJson());

  /// Decode from SQLite JSON string. Returns null if empty/invalid.
  static Anchor? fromDbString(String? s) {
    if (s == null || s.isEmpty || s == '{}') return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final a = Anchor.fromJson(j);
      return a.isEmpty ? null : a;
    } catch (_) {
      return null;
    }
  }
}
