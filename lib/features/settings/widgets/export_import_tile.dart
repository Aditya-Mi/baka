import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/utils/export_import.dart';
import 'package:baka/widgets/illustrations.dart';

class ExportImportTile extends ConsumerWidget {
  const ExportImportTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t          = context.tokens;
    final onBg       = t.onBackground;
    final muted      = t.onSurfaceMuted;
    final outline    = t.outline;
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Export
        InkWell(
          onTap: () async {
            final entries = ref.read(entriesProvider).valueOrNull ?? [];
            if (entries.isEmpty && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No entries to export.')),
              );
              return;
            }
            await ExportImport.exportEntries(entries);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AppIcon(AppIconData.share, size: 20, color: onBg),
                const SizedBox(width: 12),
                Text('Export journal',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 16, fontWeight: FontWeight.w600, color: onBg,
                    )),
                const Spacer(),
                AppIcon(AppIconData.chevronRight, size: 18, color: muted),
              ],
            ),
          ),
        ),
        Divider(color: outline, height: 1),
        // Import
        InkWell(
          onTap: () => _handleImport(context, ref, errorColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AppIcon(AppIconData.download, size: 20, color: onBg),
                const SizedBox(width: 12),
                Text('Import journal',
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 16, fontWeight: FontWeight.w600, color: onBg,
                    )),
                const Spacer(),
                AppIcon(AppIconData.chevronRight, size: 18, color: muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleImport(
    BuildContext context, WidgetRef ref, Color errorColor,
  ) async {
    final parsed = await ExportImport.pickAndParseImport();
    if (parsed == null || !context.mounted) return;

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
          'Found ${parsed.entries.length} entr${parsed.entries.length == 1 ? 'y' : 'ies'}.'
          '${parsed.skipped > 0 ? ' (${parsed.skipped} skipped — invalid)' : ''}\n\n'
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

    final notifier = ref.read(entriesProvider.notifier);
    ImportResult result;

    if (action == 'replace') {
      await notifier.replaceAll(parsed.entries);
      result = ImportResult(imported: parsed.entries.length, skipped: parsed.skipped);
    } else {
      result = await notifier.merge(parsed.entries);
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
