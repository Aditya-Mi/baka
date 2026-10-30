import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/providers/entries_provider.dart';
import 'package:baka/utils/export_import.dart';
import 'package:baka/features/settings/widgets/settings_row.dart';

class ExportImportTile extends ConsumerWidget {
  const ExportImportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export
        SettingsRow(
          icon: Icons.upload_rounded,
          title: 'Export journal',
          chevron: true,
          onTap: () async {
            final entries = ref.read(entriesProvider).valueOrNull ?? [];
            if (entries.isEmpty && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No entries to export.')),
              );
              return;
            }
            try {
              await ExportImport.exportEntries(entries);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Couldn't export. Check storage space and try again.")));
              }
            }
          },
        ),
        const SettingsDivider(),
        // Import
        SettingsRow(
          icon: Icons.download_rounded,
          title: 'Import journal',
          chevron: true,
          onTap: () => _handleImport(context, ref, errorColor),
        ),
      ],
    );
  }

  Future<void> _handleImport(
    BuildContext context, WidgetRef ref, Color errorColor,
  ) async {
    final ParsedImport? parsed;
    try {
      parsed = await ExportImport.pickAndParseImport();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't read that file. Pick a Baka export (.json).")));
      }
      return;
    }
    if (parsed == null || !context.mounted) return;
    final found = parsed; // non-null local so the dialog closure keeps promotion

    if (parsed.versionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file format or unsupported version.')),
      );
      return;
    }

    if (parsed.entries.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No valid entries found (${parsed.skipped} invalid).'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import journal'),
        content: Text(
          'Found ${found.entries.length} entr${found.entries.length == 1 ? 'y' : 'ies'}.'
          '${found.skipped > 0 ? ' (${found.skipped} skipped — invalid)' : ''}\n\n'
          'Merge adds new entries without touching existing ones.\n'
          'Replace deletes everything and imports fresh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('merge'),
            child: const Text('Merge'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('replace'),
            child: Text('Replace', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );

    if (action == null || !context.mounted) return;

    // Replace wipes the journal — make the user confirm the real cost.
    if (action == 'replace') {
      final current = ref.read(entriesProvider).valueOrNull?.length ?? 0;
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace your journal?'),
          content: Text(
            'This deletes all $current current entr${current == 1 ? 'y' : 'ies'} '
            "and can't be undone. Export first if you want a backup."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep my journal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Replace', style: TextStyle(color: errorColor)),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
    }

    final notifier = ref.read(entriesProvider.notifier);
    ImportResult result;

    try {
      if (action == 'replace') {
        await notifier.replaceAll(parsed.entries);
        result = ImportResult(imported: parsed.entries.length, skipped: parsed.skipped);
      } else {
        result = await notifier.merge(parsed.entries);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Import didn't finish. Please try again.")));
      }
      return;
    }

    if (context.mounted) {
      final total = result.imported + result.skipped;
      final msg = result.skipped > 0
          ? 'Welcomed back ${result.imported} of $total entries (${result.skipped} skipped — invalid format).'
          : 'Welcomed back ${result.imported} entr${result.imported == 1 ? 'y' : 'ies'}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
