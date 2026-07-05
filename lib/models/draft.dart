import 'package:baka/models/anchor.dart';
import 'package:baka/models/mood.dart';

/// An unsaved editor session, persisted to SharedPreferences.
/// [id] namespaces it: new entries use a uuid; edit-drafts use "edit:<entryId>".
class Draft {
  final String id;
  final String? entryId;        // non-null → this is an edit-draft
  final DateTime entryDate;
  final String body;
  final Mood? mood;
  final List<String> tags;
  final Anchor? anchor;
  final DateTime savedAt;

  const Draft({
    required this.id,
    this.entryId,
    required this.entryDate,
    required this.body,
    this.mood,
    required this.tags,
    this.anchor,
    required this.savedAt,
  });

  bool get isEdit => entryId != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        if (entryId != null) 'entryId': entryId,
        'entryDate': entryDate.toUtc().toIso8601String(),
        'body': body,
        'mood': mood?.name ?? '',
        'tags': tags,
        'anchor': anchor?.toDbString() ?? '',
        'savedAt': savedAt.toUtc().toIso8601String(),
      };

  factory Draft.fromJson(Map<String, dynamic> j) {
    final m = j['mood'] as String?;
    return Draft(
      id: j['id'] as String,
      entryId: j['entryId'] as String?,
      entryDate: DateTime.parse(j['entryDate'] as String).toLocal(),
      body: j['body'] as String,
      mood: (m == null || m.isEmpty)
          ? null
          : Mood.values.firstWhere((x) => x.name == m, orElse: () => Mood.calm),
      tags: List<String>.from(j['tags'] as List),
      anchor: Anchor.fromDbString(j['anchor'] as String?),
      savedAt: DateTime.parse(j['savedAt'] as String).toLocal(),
    );
  }
}
