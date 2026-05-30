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

  const Anchor({
    this.location,
    this.weatherCondition,
    this.weatherTemp,
    this.photoPath,
  });

  bool get isEmpty =>
      location == null &&
      weatherCondition == null &&
      weatherTemp == null &&
      photoPath == null;

  bool get hasLocation    => location != null;
  bool get hasWeather     => weatherCondition != null;
  bool get hasPhoto       => photoPath != null;

  Anchor copyWith({
    Object? location      = _sentinel,
    Object? weather       = _sentinel,
    Object? weatherTemp   = _sentinel,
    Object? photoPath     = _sentinel,
  }) =>
      Anchor(
        location:          location      == _sentinel ? this.location          : location as String?,
        weatherCondition:  weather       == _sentinel ? weatherCondition        : weather  as WeatherCondition?,
        weatherTemp:       weatherTemp   == _sentinel ? this.weatherTemp        : weatherTemp as int?,
        photoPath:         photoPath     == _sentinel ? this.photoPath          : photoPath as String?,
      );

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
        if (location != null)         'location': location,
        if (weatherCondition != null) 'weather': weatherCondition!.name,
        if (weatherTemp != null)      'temp': weatherTemp,
        if (photoPath != null)        'photo': photoPath,
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
