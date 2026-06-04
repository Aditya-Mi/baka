import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system; // follows device until prefs load
  }

  Future<void> _loadFromPrefs() async {
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeKey);
    state = switch (stored) {
      'dark'   => ThemeMode.dark,
      'light'  => ThemeMode.light,
      _        => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, switch (mode) {
      ThemeMode.dark   => 'dark',
      ThemeMode.light  => 'light',
      ThemeMode.system => 'system',
    });
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
