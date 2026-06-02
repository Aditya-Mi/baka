import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:baka/models/journal_entry.dart';

class ExportImport {
  static Future<void> exportEntries(List<JournalEntry> entries) async {
    final now     = DateTime.now().toUtc();
    final docsDir = await getApplicationDocumentsDirectory();
    final archive = Archive();

    // ── journal.json ──────────────────────────────────────────────────────────
    final payload = {
      'exportedAt': now.toIso8601String(),
      'version':    '2',
      'entryCount': entries.length,
      'entries':    entries.map((e) => e.toJson()).toList(),
    };
    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
    archive.addFile(ArchiveFile('journal.json', jsonBytes.length, jsonBytes));

    // ── photos ────────────────────────────────────────────────────────────────
    for (final entry in entries) {
      final photoPath = entry.anchor?.photoPath;
      if (photoPath == null) continue;
      final file = File('${docsDir.path}/$photoPath');
      if (!file.existsSync()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(photoPath, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive)!;
    final tmpDir  = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final outFile = File('${tmpDir.path}/journal_backup_$dateStr.zip');
    await outFile.writeAsBytes(zipBytes);
    await Share.shareXFiles([XFile(outFile.path)], subject: 'Journal Backup');
  }

  static Future<ParsedImport?> pickAndParseImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
    );
    if (result == null || result.files.single.path == null) return null;

    final path = result.files.single.path!;
    return path.endsWith('.json') ? _parseJsonFile(path) : _parseZipFile(path);
  }

  // ── v1 legacy: plain .json ─────────────────────────────────────────────────

  static Future<ParsedImport> _parseJsonFile(String path) async {
    final content = await File(path).readAsString(encoding: utf8);
    return _parseJsonContent(content);
  }

  // ── v2: .zip with journal.json + photos/ ──────────────────────────────────

  static Future<ParsedImport> _parseZipFile(String path) async {
    final bytes   = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract photos before parsing entries so paths resolve immediately.
    final docsDir = await getApplicationDocumentsDirectory();
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('photos/')) continue;
      final out = File('${docsDir.path}/${file.name}');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(file.content as List<int>);
    }

    final jsonFile = archive.findFile('journal.json');
    if (jsonFile == null) {
      return const ParsedImport(
          entries: [], skipped: 0, totalAttempted: 0, versionError: true);
    }

    final content = utf8.decode(jsonFile.content as List<int>);
    return _parseJsonContent(content, acceptVersion: '2');
  }

  static ParsedImport _parseJsonContent(String content,
      {String acceptVersion = '1'}) {
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const ParsedImport(
          entries: [], skipped: 0, totalAttempted: 0, versionError: true);
    }

    final version = parsed['version'] as String?;
    if (version != '1' && version != '2') {
      return const ParsedImport(
          entries: [], skipped: 0, totalAttempted: 0, versionError: true);
    }

    final rawEntries = parsed['entries'] as List<dynamic>? ?? [];
    final entries    = <JournalEntry>[];
    var   skipped    = 0;

    for (final raw in rawEntries) {
      try {
        entries.add(JournalEntry.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        skipped++;
      }
    }

    return ParsedImport(
      entries:        entries,
      skipped:        skipped,
      totalAttempted: rawEntries.length,
      versionError:   false,
    );
  }
}

class ParsedImport {
  final List<JournalEntry> entries;
  final int skipped;
  final int totalAttempted;
  final bool versionError;

  const ParsedImport({
    required this.entries,
    required this.skipped,
    required this.totalAttempted,
    required this.versionError,
  });
}
