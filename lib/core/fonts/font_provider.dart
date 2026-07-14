import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFontKey = 'body_font';

const kAvailableFonts = <String, String>{
  'lora':             'Lora',
  'playfairDisplay':  'Playfair Display',
  'crimsonPro':       'Crimson Pro',
  'ebGaramond':       'EB Garamond',
  'caveat':           'Caveat',
  'libreBaskerville': 'Libre Baskerville',
};

/// Maps a writing-font key to its bundled family name.
/// Returns null for an unknown key or for "match app font".
String? writingFamily(String? key) => switch (key) {
      'lora'             => 'Lora',
      'playfairDisplay'  => 'PlayfairDisplay',
      'crimsonPro'       => 'CrimsonPro',
      'ebGaramond'       => 'EBGaramond',
      'caveat'           => 'Caveat',
      'libreBaskerville' => 'LibreBaskerville',
      _                  => null,
    };

/// The user's writing-font override, layered on top of the app font preset.
/// null = "Match app font" — the body role follows the preset's own body font.
class FontNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kFontKey);
    if (stored != null && kAvailableFonts.containsKey(stored)) {
      state = stored;
    }
  }

  Future<void> setFont(String key) async {
    if (!kAvailableFonts.containsKey(key)) return;
    state = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFontKey, key);
  }

  /// Drop the override — body text goes back to following the app font preset.
  Future<void> clearFont() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFontKey);
  }
}

final fontProvider = NotifierProvider<FontNotifier, String?>(
  FontNotifier.new,
);
