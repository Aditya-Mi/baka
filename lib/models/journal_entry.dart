import 'dart:convert';

import 'package:baka/models/anchor.dart';
import 'package:baka/models/mood.dart';
import 'package:baka/models/paper.dart';

class JournalEntry {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String body;
  final Mood? mood;
  final List<String> tags;
  final int wordCount;
  final Anchor? anchor;
  /// Optional name the writer gives the page; shown on Home instead of text.
  final String? title;
  final Paper paper;

  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.body,
    this.mood,
    required this.tags,
    required this.wordCount,
    this.anchor,
    this.title,
    this.paper = Paper.ruled,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? body,
    Mood? mood,
    List<String>? tags,
    int? wordCount,
    Object? anchor = _sentinel,
    Object? title = _sentinel,
    Paper? paper,
  }) =>
      JournalEntry(
        id:        id        ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        body:      body      ?? this.body,
        mood:      mood      ?? this.mood,
        tags:      tags      ?? this.tags,
        wordCount: wordCount ?? this.wordCount,
        anchor:    anchor    == _sentinel ? this.anchor : anchor as Anchor?,
        title:     title     == _sentinel ? this.title  : title as String?,
        paper:     paper     ?? this.paper,
      );

  static const _sentinel = Object();

  Map<String, dynamic> toMap() => {
        'id':         id,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'body':       body,
        'mood':       mood?.name ?? '',
        'tags':       jsonEncode(tags),
        'word_count': wordCount,
        'anchors':    anchor?.toDbString() ?? '',
        'title':      title ?? '',
        'paper':      paper.name,
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
        id:        map['id']        as String,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
        body:      map['body']      as String,
        mood:      _moodFromString(map['mood'] as String?),
        tags:      List<String>.from(jsonDecode(map['tags'] as String) as List),
        wordCount: map['word_count'] as int,
        anchor:    Anchor.fromDbString(map['anchors'] as String?),
        title:     _blankToNull(map['title'] as String?),
        paper:     Paper.fromName(map['paper'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'body':      body,
        'mood':      mood?.name ?? '',
        'tags':      tags,
        'wordCount': wordCount,
        'anchors':   anchor?.toDbString() ?? '',
        'title':     title ?? '',
        'paper':     paper.name,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id:        json['id']        as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
        body:      json['body']      as String,
        mood:      _moodFromString(json['mood'] as String?),
        tags:      List<String>.from(json['tags'] as List),
        wordCount: json['wordCount'] as int,
        anchor:    Anchor.fromDbString(json['anchors'] as String?),
        title:     _blankToNull(json['title'] as String?),
        paper:     Paper.fromName(json['paper'] as String?),
      );

  static String? _blankToNull(String? s) =>
      s == null || s.trim().isEmpty ? null : s;

  static Mood? _moodFromString(String? s) {
    if (s == null || s.isEmpty) return null;
    return Mood.values.firstWhere((m) => m.name == s, orElse: () => Mood.calm);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
