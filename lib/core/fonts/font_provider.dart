import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFontKey = 'body_font';
const kDefaultFont = 'lora';

const kAvailableFonts = <String, String>{
  'lora':             'Lora',
  'playfairDisplay':  'Playfair Display',
  'crimsonPro':       'Crimson Pro',
  'ebGaramond':       'EB Garamond',
  'caveat':           'Caveat',
  'libreBaskerville': 'Libre Baskerville',
};

class FontNotifier extends Notifier<String> {
  @override
  String build() {
    _loadFromPrefs();
    return kDefaultFont;
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
}

final fontProvider = NotifierProvider<FontNotifier, String>(
  FontNotifier.new,
);
