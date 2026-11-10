import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/providers/entries_provider.dart';
import 'package:baka/utils/note_marks.dart';

/// Everyone written about, with how many pages they're in, most written
/// about first. Read from the pages themselves, like tags.
final peopleProvider = Provider<List<({String name, int pages})>>((ref) {
  final entries = ref.watch(entriesProvider).valueOrNull ?? const [];
  final counts = <String, int>{};
  for (final e in entries) {
    for (final p in peopleIn(e.body)) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
  }
  return [
    for (final MapEntry(:key, :value) in counts.entries) (name: key, pages: value),
  ]..sort((a, b) =>
      b.pages != a.pages ? b.pages.compareTo(a.pages) : a.name.compareTo(b.name));
});
