import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'dart:io';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/home/widgets/journal_card.dart' show buildTagSpan, tagColorFor;
import 'package:baka/models/tag.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/weather_icon.dart';
import 'package:path_provider/path_provider.dart';

class EntryDetailScreen extends HookConsumerWidget {
  final String id;
  const EntryDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t        = context.tokens;
    final bg       = t.background;
    final onBg     = t.onBackground;
    final muted    = t.onSurfaceMuted;
    final outline  = t.outline;
    final primary  = t.primary;
    final ruleColor = t.rule;

    final entriesAsync = ref.watch(entriesProvider);
    final tagList      = ref.watch(tagsProvider).valueOrNull ?? <Tag>[];
    final entry = entriesAsync.valueOrNull?.where((e) => e.id == id).firstOrNull;

    if (entriesAsync.isLoading || entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: AppIcon(AppIconData.back, size: 22, color: onBg),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: QuillIcon(size: 22, color: onBg),
            onPressed: () => context.push('/edit/${entry.id}'),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: muted),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
            // Stamp
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(entry.createdAt),
                    style: TextStyle(fontFamily: 'Caveat',
                      fontSize: 16, fontWeight: FontWeight.w500, color: onBg,
                    ),
                  ),
                  const Spacer(),
                  if (entry.mood != null)
                    MoodGlyph(mood: entry.mood!, size: 22, color: primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.jm().format(entry.createdAt),
                    style: TextStyle(fontFamily: 'Caveat', fontSize: 14, color: muted),
                  ),
                ],
              ),
            ),

            Divider(color: outline, height: 1),

            // Anchor bar (location + weather)
            if (entry.anchor != null &&
                (entry.anchor!.hasLocation || entry.anchor!.hasWeather))
              _AnchorBar(anchor: entry.anchor!, t: t),

            // Tags (read-only)
            if (entry.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6, runSpacing: 6,
                    children: entry.tags.map((tag) {
                      final c = tagColorFor(tagList, tag);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.12),
                          border: Border.all(
                              color: c.withValues(alpha: 0.30), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontFamily: 'Caveat',
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: t.onBackground,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (entry.tags.isNotEmpty) Divider(color: outline, height: 1),

            // Body — Stack fills the exact Expanded height so lines always
            // cover the full body area regardless of content length.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _PageLinesPainter(color: ruleColor)),
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: SelectableText.rich(
                      buildTagSpan(
                        entry.body,
                        primary,
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: onBg, height: 1.75, fontSize: 17,
                        ) ?? TextStyle(fontSize: 17, height: 1.75, color: onBg),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Photo (at bottom, after body — text is the highlight)
            if (entry.anchor?.hasPhoto == true)
              _PhotoView(photoPath: entry.anchor!.photoPath!, t: t),

            // Word count footer
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: outline, width: 0.8)),
                color: bg,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        '${entry.wordCount} words',
                        style: TextStyle(fontFamily: 'CourierPrime', fontSize: 12, color: muted),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${entry.body.length} chars',
                        style: TextStyle(fontFamily: 'CourierPrime', fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(entriesProvider.notifier).remove(id);
      if (context.mounted) context.go('/');
    }
  }
}

// ── Anchor bar (location + weather) ──────────────────────────────────────────

class _AnchorBar extends StatelessWidget {
  final dynamic anchor; // Anchor
  final BakaTokens t;
  const _AnchorBar({required this.anchor, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          if (anchor.hasLocation)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on_outlined, size: 16, color: t.onSurfaceMuted),
              const SizedBox(width: 4),
              Text(anchor.location!,
                  style: TextStyle(fontFamily: 'Caveat',
                    fontSize: 15, color: t.onSurfaceMuted)),
            ]),
          if (anchor.hasWeather)
            Row(mainAxisSize: MainAxisSize.min, children: [
              WeatherIcon(anchor.weatherCondition!, size: 18, color: t.onSurfaceMuted),
              const SizedBox(width: 4),
              Text(
                anchor.weatherTemp != null
                    ? '${anchor.weatherCondition!.label} · ${anchor.weatherTemp}°C'
                    : anchor.weatherCondition!.label,
                style: TextStyle(fontFamily: 'Caveat',
                  fontSize: 15, color: t.onSurfaceMuted),
              ),
            ]),
        ],
      ),
    );
  }
}

// ── Photo view ────────────────────────────────────────────────────────────────

/// Collapsed thumbnail by default (80px). Tap to expand (220px). Long-press → fullscreen.
class _PhotoView extends StatefulWidget {
  final String photoPath;
  final BakaTokens t;
  const _PhotoView({required this.photoPath, required this.t});

  @override
  State<_PhotoView> createState() => _PhotoViewState();
}

class _PhotoViewState extends State<_PhotoView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveFullPath(widget.photoPath),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final file = File(snap.data!);
        if (!file.existsSync()) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible, tap to toggle
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Row(
                  children: [
                    Icon(Icons.image_outlined, size: 16,
                        color: widget.t.onSurfaceMuted),
                    const SizedBox(width: 6),
                    Text('Photo',
                        style: TextStyle(fontFamily: 'Caveat',
                          fontSize: 15, color: widget.t.onSurfaceMuted)),
                    const Spacer(),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18, color: widget.t.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
            // Image — only when expanded
            if (_expanded)
              GestureDetector(
                onLongPress: () => _showFullscreen(context, file),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 220),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<String> _resolveFullPath(String rel) async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$rel';
  }

  void _showFullscreen(BuildContext context, File file) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: InteractiveViewer(child: Image.file(file))),
      ),
    ));
  }
}

/// Paints horizontal ruled lines across the full canvas area.
/// Used as a background for the entire body column so lines are always
/// full-screen regardless of text length.
class _PageLinesPainter extends CustomPainter {
  final Color color;
  static const _spacing = 29.0;
  static const _topOffset = 16.0;

  const _PageLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.6;
    var y = _topOffset + _spacing;
    while (y < size.height) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
      y += _spacing;
    }
  }

  @override
  bool shouldRepaint(_PageLinesPainter old) => old.color != color;
}
