import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baka/models/paper.dart';

const _kPaperKey = 'default_paper';

/// The paper new pages start on. Each page can still pick its own.
class DefaultPaperNotifier extends Notifier<Paper> {
  @override
  Paper build() {
    _load();
    return Paper.ruled;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Paper.fromName(prefs.getString(_kPaperKey));
  }

  Future<void> set(Paper p) async {
    state = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaperKey, p.name);
  }
}

final defaultPaperProvider =
    NotifierProvider<DefaultPaperNotifier, Paper>(DefaultPaperNotifier.new);
