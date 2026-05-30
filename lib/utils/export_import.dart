import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:baka/models/journal_entry.dart';

class ExportImport {
  static Future<void> exportEntries(List<JournalEntry> entries) async {
    final now = DateTime.now().toUtc();
    final payload = {
      'exportedAt': now.toIso8601String(),
      'version': '1',
      'entryCount': entries.length,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final file = File('${dir.path}/journal_backup_$dateStr.json');
    await file.writeAsString(json, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], subject: 'Journal Backup');
  }

  static Future<ParsedImport?> pickAndParseImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;

    final content = await File(result.files.single.path!).readAsString(encoding: utf8);
    final Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const ParsedImport(entries: [], skipped: 0, totalAttempted: 0, versionError: true);
    }

    if (parsed['version'] != '1') {
      return const ParsedImport(entries: [], skipped: 0, totalAttempted: 0, versionError: true);
    }

    final rawEntries = parsed['entries'] as List<dynamic>? ?? [];
    final List<JournalEntry> entries = [];
    int skipped = 0;

    for (final raw in rawEntries) {
      try {
        entries.add(JournalEntry.fromJson(raw as Map<String, dynamic>));
      } catch (_) {
        skipped++;
      }
    }

    return ParsedImport(
      entries: entries,
      skipped: skipped,
      totalAttempted: rawEntries.length,
      versionError: false,
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
