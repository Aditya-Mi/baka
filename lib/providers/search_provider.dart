import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baka/core/db/database_helper.dart';
import 'package:baka/models/journal_entry.dart';

class SearchState {
  final String query;
  final AsyncValue<List<JournalEntry>> results;

  const SearchState({required this.query, required this.results});
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return const SearchState(query: '', results: AsyncData([]));
  }

  Future<void> search(String query) async {
    state = SearchState(query: query, results: const AsyncLoading());
    if (query.trim().isEmpty) {
      state = const SearchState(query: '', results: AsyncData([]));
      return;
    }
    try {
      final results = await DatabaseHelper.instance.searchEntries(query.trim());
      state = SearchState(query: query, results: AsyncData(results));
    } catch (e, st) {
      state = SearchState(query: query, results: AsyncError(e, st));
    }
  }

  void clear() {
    state = const SearchState(query: '', results: AsyncData([]));
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
