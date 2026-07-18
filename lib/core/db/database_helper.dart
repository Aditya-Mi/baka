import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:baka/models/journal_entry.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/models/voice_capture.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static const _dbName    = 'baka_journal.db';
  static const _dbVersion = 5; // bumped for voice_captures.waveform column
  static const tableEntries  = 'entries';
  static const tableTagsMeta = 'tags_meta';
  static const tableCaptures = 'voice_captures';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<void> initDb() async {
    _db = await _open();
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableEntries (
        id          TEXT PRIMARY KEY,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL,
        body        TEXT NOT NULL,
        mood        TEXT NOT NULL DEFAULT '',
        tags        TEXT NOT NULL DEFAULT '[]',
        word_count  INTEGER NOT NULL DEFAULT 0,
      anchors     TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_entries_created_at
      ON $tableEntries(created_at DESC)
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTagsMeta (
        name   TEXT PRIMARY KEY,
        color  TEXT NOT NULL
      )
    ''');
    await _createCapturesTable(db);
  }

  Future<void> _createCapturesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCaptures (
        id           TEXT PRIMARY KEY,
        created_at   TEXT NOT NULL,
        audio_path   TEXT NOT NULL,
        duration_ms  INTEGER NOT NULL DEFAULT 0,
        status       TEXT NOT NULL DEFAULT 'savedAudio',
        transcript   TEXT,
        entry_id     TEXT,
        waveform     TEXT
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_captures_created_at
      ON $tableCaptures(created_at DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableTagsMeta (
          name   TEXT PRIMARY KEY,
          color  TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE $tableEntries ADD COLUMN anchors TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 4) {
      await _createCapturesTable(db);
    }
    if (oldVersion < 5) {
      // Only alter if the table already existed at v4 (fresh v4→v5 upgrade).
      // A <4 upgrade just created the table above, already with the column.
      if (oldVersion >= 4) {
        await db.execute(
          "ALTER TABLE $tableCaptures ADD COLUMN waveform TEXT",
        );
      }
    }
  }

  // ── Entries CRUD ─────────────────────────────────────────────────────────────

  Future<List<JournalEntry>> getAllEntries() async {
    final db   = await database;
    final maps = await db.query(tableEntries, orderBy: 'created_at DESC');
    return maps.map(JournalEntry.fromMap).toList();
  }

  Future<JournalEntry?> getEntryById(String id) async {
    final db   = await database;
    final maps = await db.query(tableEntries,
        where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isEmpty ? null : JournalEntry.fromMap(maps.first);
  }

  Future<void> insertEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert(tableEntries, entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final db = await database;
    await db.update(tableEntries, entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete(tableEntries, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllEntries() async {
    final db = await database;
    await db.delete(tableEntries);
  }

  Future<void> insertOrIgnoreEntry(JournalEntry entry) async {
    final db = await database;
    await db.insert(tableEntries, entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<JournalEntry>> getEntriesInDateRange(
      DateTime from, DateTime to) async {
    final db   = await database;
    final maps = await db.query(
      tableEntries,
      where:     'created_at >= ? AND created_at <= ?',
      whereArgs: [from.toUtc().toIso8601String(), to.toUtc().toIso8601String()],
      orderBy:   'created_at DESC',
    );
    return maps.map(JournalEntry.fromMap).toList();
  }

  Future<List<JournalEntry>> searchEntries(String query) async {
    final db   = await database;
    final maps = await db.query(
      tableEntries,
      where:     'body LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy:   'created_at DESC',
    );
    return maps.map(JournalEntry.fromMap).toList();
  }

  // ── Voice captures CRUD ──────────────────────────────────────────────────────

  Future<List<VoiceCapture>> getAllCaptures() async {
    final db   = await database;
    final maps = await db.query(tableCaptures, orderBy: 'created_at DESC');
    return maps.map(VoiceCapture.fromMap).toList();
  }

  Future<bool> captureExists(String id) async {
    final db   = await database;
    final maps = await db.query(tableCaptures,
        columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty;
  }

  /// Inserts a capture, ignoring if the id already exists (idempotent import).
  Future<void> insertCaptureIfAbsent(VoiceCapture capture) async {
    final db = await database;
    await db.insert(tableCaptures, capture.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateCapture(VoiceCapture capture) async {
    final db = await database;
    await db.update(tableCaptures, capture.toMap(),
        where: 'id = ?', whereArgs: [capture.id]);
  }

  Future<void> deleteCapture(String id) async {
    final db = await database;
    await db.delete(tableCaptures, where: 'id = ?', whereArgs: [id]);
  }

  // ── Tags meta CRUD ───────────────────────────────────────────────────────────

  /// Returns all tags with their colors, sorted alphabetically.
  Future<List<Tag>> getAllTags() async {
    final db   = await database;
    final maps = await db.query(tableTagsMeta, orderBy: 'name ASC');
    return maps.map(Tag.fromMap).toList();
  }

  /// Inserts a tag with auto-assigned palette color if it doesn't exist yet.
  /// Ignores if already present (preserves user-customized color).
  Future<void> upsertTagMeta(String name) async {
    final db = await database;
    await db.insert(
      tableTagsMeta,
      {
        'name':  name,
        'color': TagPalette.toHex(TagPalette.forName(name)),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Batch-upserts all tag names in a list.
  Future<void> upsertTagsMeta(List<String> names) async {
    final db = await database;
    final batch = db.batch();
    for (final name in names) {
      batch.insert(
        tableTagsMeta,
        {
          'name':  name,
          'color': TagPalette.toHex(TagPalette.forName(name)),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Updates the color of an existing tag (user recolor from Tags screen).
  Future<void> updateTagColor(String name, String hexColor) async {
    final db = await database;
    await db.update(
      tableTagsMeta,
      {'color': hexColor},
      where:     'name = ?',
      whereArgs: [name],
    );
  }

  /// Returns a single tag's metadata, or null if not found.
  Future<Tag?> getTag(String name) async {
    final db   = await database;
    final maps = await db.query(tableTagsMeta,
        where: 'name = ?', whereArgs: [name], limit: 1);
    return maps.isEmpty ? null : Tag.fromMap(maps.first);
  }

  /// Deletes a tag from meta (e.g. when no entries use it anymore).
  Future<void> deleteTagMeta(String name) async {
    final db = await database;
    await db.delete(tableTagsMeta, where: 'name = ?', whereArgs: [name]);
  }
}
