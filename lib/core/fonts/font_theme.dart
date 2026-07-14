import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'app_font_theme';
const kDefaultPreset = 'classic';

/// A curated four-role pairing.
///
/// Roles never mix across presets, so any two fonts sharing a screen are ones
/// we chose to sit together. Users pick a pairing, not a font.
@immutable
class FontPreset {
  final String id;
  final String label;
  final String blurb;

  /// Headings, AppBar titles, dialog titles.
  final String display;

  /// Reading text, buttons, journal body.
  final String body;

  /// Chips, nav labels, dates, meta lines.
  final String accent;

  /// Word counters, timestamps.
  final String mono;

  /// Optical size correction.
  ///
  /// Two faces at the same `fontSize` do not read as the same size — what the
  /// eye measures is x-height, and it varies a lot. Against Lora (the Classic
  /// body face, x-height 0.500 em): Inter is 0.546, Courier Prime 0.451,
  /// EB Garamond 0.400. Set at ~80% of the raw x-height ratio, since perceived
  /// size does not track x-height alone. Applied globally as a text scale, so
  /// it reaches every font size in the app, not just the ones in the theme.
  final double scale;

  const FontPreset({
    required this.id,
    required this.label,
    required this.blurb,
    required this.display,
    required this.body,
    required this.accent,
    required this.mono,
    this.scale = 1.0,
  });
}

const kFontPresets = <String, FontPreset>{
  'classic': FontPreset(
    id: 'classic',
    label: 'Classic',
    blurb: 'Aged paper and ink.',
    display: 'PlayfairDisplay',
    body: 'Lora',
    accent: 'Caveat',
    mono: 'CourierPrime',
  ),
  // One superfamily across all four roles: the faces are guaranteed to sit
  // together by construction rather than by taste. Plex Sans holds up at 14px
  // and Plex Mono has tabular figures, which is what AI insight text needs.
  'field': FontPreset(
    id: 'field',
    label: 'Field',
    blurb: 'Clear lines, nothing spare.',
    display: 'IBMPlexSerif',
    body: 'IBMPlexSans',
    accent: 'IBMPlexSans',
    mono: 'IBMPlexMono',
    scale: 0.98,
  ),
  'warm': FontPreset(
    id: 'warm',
    label: 'Warm',
    blurb: 'Old books, soft light.',
    display: 'CormorantGaramond',
    body: 'EBGaramond',
    accent: 'Caveat',
    mono: 'CourierPrime',
    scale: 1.20,
  ),
  // The only preset that is deliberately one face: a typewriter has one face.
  'typewriter': FontPreset(
    id: 'typewriter',
    label: 'Typewriter',
    blurb: 'Every letter earns its place.',
    display: 'CourierPrime',
    body: 'CourierPrime',
    accent: 'Caveat',
    mono: 'CourierPrime',
    scale: 1.09,
  ),
  // Fraunces is cut at opsz 48 with SOFT=50, WONK=1 — its character lives in
  // the headings only, so it never costs body copy any readability.
  'letter': FontPreset(
    id: 'letter',
    label: 'Letter',
    blurb: 'Like writing to a friend.',
    display: 'Fraunces',
    body: 'NunitoSans',
    accent: 'NunitoSans',
    mono: 'IBMPlexMono',
    scale: 1.02,
  ),
};

/// The wordmark is the one thing that never changes with the preset — a logo
/// that reshapes itself per theme stops reading as a logo.
const kWordmarkFamily = 'Caveat';

/// Resolved families for the active preset — reach via `context.fonts`.
@immutable
class BakaFonts extends ThemeExtension<BakaFonts> {
  final String display;
  final String body;
  final String accent;
  final String mono;

  const BakaFonts({
    required this.display,
    required this.body,
    required this.accent,
    required this.mono,
  });

  /// [writingFont] is the user's optional body-font override; null means the
  /// body role follows the preset.
  factory BakaFonts.of(FontPreset p, {String? writingFont}) => BakaFonts(
        display: p.display,
        body: writingFont ?? p.body,
        accent: p.accent,
        mono: p.mono,
      );

  @override
  BakaFonts copyWith({String? display, String? body, String? accent, String? mono}) =>
      BakaFonts(
        display: display ?? this.display,
        body: body ?? this.body,
        accent: accent ?? this.accent,
        mono: mono ?? this.mono,
      );

  // Families are discrete — snap at the midpoint rather than interpolate.
  @override
  BakaFonts lerp(ThemeExtension<BakaFonts>? other, double t) =>
      (other is BakaFonts && t >= 0.5) ? other : this;
}

extension BakaFontsContext on BuildContext {
  BakaFonts get fonts => Theme.of(this).extension<BakaFonts>()!;
}

/// Layers a preset's optical correction on top of the device text scale.
///
/// It multiplies rather than replaces, so a user who has bumped their system
/// font size keeps that bump — the preset only nudges relative to it.
@immutable
class PresetTextScaler extends TextScaler {
  final TextScaler base;
  final double factor;

  const PresetTextScaler({required this.base, required this.factor});

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is PresetTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

class FontThemeNotifier extends Notifier<FontPreset> {
  @override
  FontPreset build() {
    _loadFromPrefs();
    return kFontPresets[kDefaultPreset]!;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kPrefKey);
    if (id != null && kFontPresets.containsKey(id)) {
      state = kFontPresets[id]!;
    }
  }

  Future<void> setPreset(String id) async {
    final preset = kFontPresets[id];
    if (preset == null) return;
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, id);
  }
}

final fontThemeProvider =
    NotifierProvider<FontThemeNotifier, FontPreset>(FontThemeNotifier.new);
