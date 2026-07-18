import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:baka/core/db/database_helper.dart';
import 'package:baka/models/voice_capture.dart';

/// Bridges native voice captures (written by the home-screen widget's
/// [RecordActivity]) into the app DB.
///
/// The native side drops two files per capture into the shared external
/// files dir: `<id>.m4a` (audio) and `<id>.json` (metadata). Both sides
/// resolve the *same* directory — Flutter via [getExternalStorageDirectory],
/// Kotlin via `getExternalFilesDir(null)` — so no path handoff is needed.
///
/// Import is idempotent: a capture already in the DB is skipped, and the
/// `.json` sidecar is deleted once its row exists. The `.m4a` is kept as the
/// source of truth and its path stored on the row.
class CaptureImporter {
  CaptureImporter._();

  static const _subdir = 'voice_captures';

  /// Resolves (and creates) the shared captures directory. Returns null on
  /// platforms without app-external storage (e.g. iOS in this phase).
  static Future<Directory?> capturesDir() async {
    final base = await getExternalStorageDirectory();
    if (base == null) return null;
    final dir = Directory(p.join(base.path, _subdir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Scans for new `<id>.json` sidecars and inserts their captures into the DB.
  /// Returns the number of newly imported captures.
  static Future<int> importPending() async {
    final dir = await capturesDir();
    if (dir == null) return 0;

    var imported = 0;
    final files = await dir.list().toList();
    for (final f in files) {
      if (f is! File || p.extension(f.path) != '.json') continue;
      try {
        final capture = await _readSidecar(f, dir.path);
        if (capture == null) {
          await _safeDelete(f); // malformed sidecar — drop it
          continue;
        }
        if (!await DatabaseHelper.instance.captureExists(capture.id)) {
          await DatabaseHelper.instance.insertCaptureIfAbsent(capture);
          imported++;
        }
        await _safeDelete(f); // row exists — sidecar no longer needed
      } catch (_) {
        // Leave the sidecar in place so the next scan can retry.
      }
    }
    return imported;
  }

  static Future<VoiceCapture?> _readSidecar(File json, String dirPath) async {
    final raw = jsonDecode(await json.readAsString());
    if (raw is! Map) return null;

    final id = raw['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final audioPath = p.join(dirPath, '$id.m4a');
    if (!await File(audioPath).exists()) return null; // audio missing — skip

    final createdAtRaw = raw['createdAt'] as String?;
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return VoiceCapture(
      id: id,
      createdAt: createdAt,
      audioPath: audioPath,
      durationMs: (raw['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  static Future<void> _safeDelete(FileSystemEntity f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {/* ignore */}
  }
}
