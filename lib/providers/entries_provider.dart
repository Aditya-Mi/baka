import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baka/core/db/database_helper.dart';
import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/mood.dart';

class ImportResult {
  final int imported;
  final int skipped;
  const ImportResult({required this.imported, required this.skipped});
}

class EntriesNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    return DatabaseHelper.instance.getAllEntries();
  }

  Future<void> add(JournalEntry e) async {
    await DatabaseHelper.instance.insertEntry(e);
    if (e.tags.isNotEmpty) {
      await DatabaseHelper.instance.upsertTagsMeta(e.tags);
    }
    final updated = <JournalEntry>[e, ...state.valueOrNull ?? []]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(updated);
  }

  Future<void> updateEntry(JournalEntry e) async {
    await DatabaseHelper.instance.updateEntry(e);
    if (e.tags.isNotEmpty) {
      await DatabaseHelper.instance.upsertTagsMeta(e.tags);
    }
    final updated = <JournalEntry>[...(state.valueOrNull ?? [])]
        .map((x) => x.id == e.id ? e : x)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(updated);
  }

  Future<void> remove(String id) async {
    await DatabaseHelper.instance.deleteEntry(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((x) => x.id != id).toList(),
    );
  }

  Future<JournalEntry?> getById(String id) async {
    return DatabaseHelper.instance.getEntryById(id);
  }

  Future<List<JournalEntry>> recentDays(int n) async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).subtract(Duration(days: n - 1));
    return DatabaseHelper.instance.getEntriesInDateRange(from, now);
  }

  Future<List<JournalEntry>> byTag(String tag) async {
    final all = state.valueOrNull ?? await DatabaseHelper.instance.getAllEntries();
    return all.where((e) => e.tags.contains(tag.toLowerCase())).toList();
  }

  Future<void> replaceAll(List<JournalEntry> entries) async {
    await DatabaseHelper.instance.deleteAllEntries();
    for (final e in entries) {
      await DatabaseHelper.instance.insertEntry(e);
    }
    state = AsyncData(List<JournalEntry>.from(entries));
  }

  Future<ImportResult> merge(List<JournalEntry> entries) async {
    int imported = 0;
    int skipped = 0;
    for (final e in entries) {
      final existing = await DatabaseHelper.instance.getEntryById(e.id);
      if (existing == null) {
        await DatabaseHelper.instance.insertOrIgnoreEntry(e);
        imported++;
      } else {
        skipped++;
      }
    }
    state = AsyncData(await DatabaseHelper.instance.getAllEntries());
    return ImportResult(imported: imported, skipped: skipped);
  }

  // ── Static stats helpers ──────────────────────────────────────────────────

  static int computeCurrentStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    final today     = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final days = <DateTime>{};
    for (final e in entries) {
      days.add(DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day));
    }

    // If today has no entry yet, start counting from yesterday —
    // the user still has the rest of today to write.
    var check = days.contains(todayDate)
        ? todayDate
        : todayDate.subtract(const Duration(days: 1));

    if (!days.contains(check)) return 0;

    var streak = 0;
    while (days.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int computeLongestStreak(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0;
    final days = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort();
    var longest = 1, current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static Map<DateTime, int> computeEntriesPerDay(
    List<JournalEntry> entries, int pastDays,
  ) {
    final result = <DateTime, int>{};
    final cutoff = DateTime.now().subtract(Duration(days: pastDays));
    for (final e in entries) {
      if (e.createdAt.isBefore(cutoff)) continue;
      final key = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  static Map<DateTime, int> computeWordsPerDay(
    List<JournalEntry> entries, int pastDays,
  ) {
    final result = <DateTime, int>{};
    final cutoff = DateTime.now().subtract(Duration(days: pastDays));
    for (final e in entries) {
      if (e.createdAt.isBefore(cutoff)) continue;
      final key = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      result[key] = (result[key] ?? 0) + e.wordCount;
    }
    return result;
  }

  static Map<Mood, int> computeMoodCounts(
    List<JournalEntry> entries, int pastDays,
  ) {
    final result = <Mood, int>{};
    final cutoff = DateTime.now().subtract(Duration(days: pastDays));
    for (final e in entries) {
      if (e.createdAt.isBefore(cutoff)) continue;
      if (e.mood == null) continue;
      result[e.mood!] = (result[e.mood!] ?? 0) + 1;
    }
    return result;
  }
}

final entriesProvider =
    AsyncNotifierProvider<EntriesNotifier, List<JournalEntry>>(
  EntriesNotifier.new,
);
