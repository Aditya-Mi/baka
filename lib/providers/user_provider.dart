import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUserName = 'user_name';

class UserNotifier extends Notifier<String> {
  // Prevents _load() completing late and overwriting a name set via setName()
  bool _explicitlySet = false;

  @override
  String build() {
    _load();
    return '';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_explicitlySet) {
      state = prefs.getString(_kUserName) ?? '';
    }
  }

  Future<void> setName(String name) async {
    _explicitlySet = true;
    state = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name.trim());
  }
}

final userProvider = NotifierProvider<UserNotifier, String>(UserNotifier.new);
