import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baka/core/db/database_helper.dart';
import 'package:baka/models/tag.dart';

class TagsNotifier extends AsyncNotifier<List<Tag>> {
  @override
  Future<List<Tag>> build() => DatabaseHelper.instance.getAllTags();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(DatabaseHelper.instance.getAllTags);
  }

  /// Updates the color for a tag, inserting into tags_meta first if needed.
  Future<void> updateColor(String name, String hexColor) async {
    await DatabaseHelper.instance.upsertTagMeta(name); // ensure row exists
    await DatabaseHelper.instance.updateTagColor(name, hexColor);
    await reload();
  }
}

final tagsProvider = AsyncNotifierProvider<TagsNotifier, List<Tag>>(
  TagsNotifier.new,
);
