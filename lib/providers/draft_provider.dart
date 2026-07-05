import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:baka/models/draft.dart';

const _kDraftsKey = 'pending_drafts';

class DraftsNotifier extends AsyncNotifier<List<Draft>> {
  @override
  Future<List<Draft>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  List<Draft> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_kDraftsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Draft.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<Draft> drafts) async {
    drafts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kDraftsKey, jsonEncode(drafts.map((d) => d.toJson()).toList()));
    state = AsyncData(List<Draft>.from(drafts));
  }

  /// Upsert by id. Empty-body drafts are dropped instead of stored.
  Future<void> save(Draft draft) async {
    final list = List<Draft>.from(state.valueOrNull ?? [])
      ..removeWhere((d) => d.id == draft.id);
    if (draft.body.trim().isNotEmpty) list.add(draft);
    await _persist(list);
  }

  Future<void> clear(String id) async {
    await _persist(List<Draft>.from(state.valueOrNull ?? [])
      ..removeWhere((d) => d.id == id));
  }

  Draft? byId(String id) {
    for (final d in state.valueOrNull ?? const <Draft>[]) {
      if (d.id == id) return d;
    }
    return null;
  }
}

final draftsProvider =
    AsyncNotifierProvider<DraftsNotifier, List<Draft>>(DraftsNotifier.new);
