import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'dart:io';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/features/editor/widgets/page_header.dart';
import 'package:baka/features/capture/widgets/waveform.dart';
import 'package:baka/utils/song_preview.dart';
import 'package:baka/utils/tag_utils.dart';
import 'package:baka/widgets/tag_chip.dart';
import 'package:baka/models/tag.dart';
import 'package:baka/providers/entries_provider.dart';
import 'package:baka/providers/tags_provider.dart';
import 'package:baka/widgets/illustrations.dart';
import 'package:baka/widgets/state_views.dart';
import 'package:baka/widgets/weather_icon.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final ruleColor = t.rule;

    final entriesAsync = ref.watch(entriesProvider);
    final tagList      = ref.watch(tagsProvider).valueOrNull ?? <Tag>[];
    final entry = entriesAsync.valueOrNull?.where((e) => e.id == id).firstOrNull;

    if (entry == null) {
      // Loading, failed, or the entry was deleted — never spin forever.
      final Widget body;
      if (entriesAsync.hasError) {
        body = ErrorView(
          message: "Something went wrong loading this entry.",
          onRetry: () => ref.invalidate(entriesProvider));
      } else if (entriesAsync.isLoading && !entriesAsync.hasValue) {
        body = const Center(child: CircularProgressIndicator());
      } else {
        body = StateMessage(
          icon: Icons.menu_book_outlined,
          title: 'This entry no longer exists',
          body: 'It may have been deleted.',
          actionLabel: 'Back to your pages',
          onAction: () => context.canPop() ? context.pop() : context.go('/'),
        );
      }
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          leading: IconButton(
            tooltip: 'Back',
            icon: AppIcon(AppIconData.back, size: 22, color: onBg),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          tooltip: 'Back',
          icon: AppIcon(AppIconData.back, size: 22, color: onBg),
          onPressed: () => context.pop(),
        ),
        actions: [
          Center(
            child: Material(
              color: t.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/edit/${entry.id}'),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: t.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text('Edit',
                          style: AppText.handAction(context).copyWith(
                              color: t.onPrimaryContainer,
                            )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 22, color: muted),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
            PageHeader(date: entry.createdAt, mood: entry.mood),

            // Anchors (location / weather / song)
            if (entry.anchor != null &&
                (entry.anchor!.hasLocation || entry.anchor!.hasWeather ||
                 entry.anchor!.hasSong))
              _AnchorBar(anchor: entry.anchor!, t: t),

            // Tags (read-only)
            if (entry.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: entry.tags.map((tag) => TagChip(
                      tag: tag,
                      color: tagColorFor(tagList, tag),
                      textColor: t.onBackground,
                    )).toList(),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: t.outlineSoft, height: 1),
            ),

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
                        t.primaryText,
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
              color: bg,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: Text(
                    '${entry.wordCount} words',
                    style: AppText.counter(context).copyWith(
                        color: muted,
                      ),
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

  Widget _chip(BuildContext context, {required Widget icon, required String label,
      Color? color, bool link = false, VoidCallback? onTap}) {
    final c = color ?? t.onSurface;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: t.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta(context).copyWith(
                      color: c,
                      decoration: link ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: c,
                    )),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = anchor.hasSong && anchor.songUrl != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (anchor.hasLocation)
              _chip(context,
                icon: Icon(Icons.location_on_outlined, size: 16, color: t.onSurfaceMuted),
                label: anchor.location!),
            if (anchor.hasWeather)
              _chip(context,
                icon: WeatherIcon(anchor.weatherCondition!, size: 16, color: t.onSurfaceMuted),
                label: anchor.weatherTemp != null
                    ? '${anchor.weatherCondition!.label} · ${anchor.weatherTemp}°C'
                    : anchor.weatherCondition!.label),
            if (anchor.hasSong)
              _chip(context,
                icon: Icon(Icons.music_note_rounded, size: 16,
                    color: hasLink ? t.primary : t.onSurfaceMuted),
                label: anchor.songArtist != null
                    ? '${anchor.songName!} · ${anchor.songArtist!}'
                    : anchor.songName!,
                color: hasLink ? t.primary : null,
                link: hasLink,
                onTap: hasLink
                    ? () async {
                        final uri = Uri.tryParse(normalizeSongUrl(anchor.songUrl!));
                        final opened = uri != null &&
                            await launchUrl(uri, mode: LaunchMode.externalApplication)
                                .catchError((_) => false);
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text("Couldn't open this song link")));
                        }
                      }
                    : null),
            if (anchor.hasSong)
              _SongPreview(
                name: anchor.songName!,
                artist: anchor.songArtist,
                url: anchor.songUrl,
                t: t,
              ),
          ],
        ),
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
                        style: AppText.caption(context).copyWith(
                            color: widget.t.onSurfaceMuted,
                          )),
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
                        height: 220,
                        // Decode at display width, not the camera\'s 12MP.
                        cacheWidth: (640 * MediaQuery.devicePixelRatioOf(context)).round()),
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
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
      y += _spacing;
    }
  }

  @override
  bool shouldRepaint(_PageLinesPainter old) => old.color != color;
}

// ── Song preview (10s clip) ──────────────────────────────────────────────────

/// Small play button that streams the entry song's 30s iTunes preview,
/// skipping the first few seconds (previews often open on a quiet intro).
/// While playing, a mini waveform fills in primary as the clip progresses —
/// same play-button + waveform language as the Voice Inbox capture card.
class _SongPreview extends StatefulWidget {
  final String name;
  final String? artist;
  final String? url;
  final BakaTokens t;
  const _SongPreview({
    required this.name, this.artist, this.url, required this.t,
  });

  @override
  State<_SongPreview> createState() => _SongPreviewState();
}

class _SongPreviewState extends State<_SongPreview> {
  static const _startAt = Duration(seconds: 4);
  final _player = AudioPlayer();
  final _subs = <StreamSubscription<Object?>>[];
  Duration _duration = const Duration(seconds: 30);
  bool _loading = false;
  bool _playing = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _subs.addAll([
      _player.onDurationChanged.listen((d) {
        if (d > _startAt) _duration = d;
      }),
      _player.onPositionChanged.listen((p) {
        if (!mounted || !_playing) return;
        final played = (p - _startAt).inMilliseconds;
        final total  = (_duration - _startAt).inMilliseconds;
        setState(() => _progress = played / total);
      }),
      _player.onPlayerComplete.listen((_) => _stop()),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() { _playing = false; _progress = 0; });
  }

  Future<void> _toggle() async {
    if (_playing) return _stop();
    setState(() => _loading = true);
    final preview = await SongPreview.resolve(
        name: widget.name, artist: widget.artist, url: widget.url);
    if (!mounted) return;
    if (preview == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No preview found for this song')));
      return;
    }
    try {
      await _player.play(UrlSource(preview), position: _startAt);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t play preview')));
      return;
    }
    if (mounted) setState(() { _loading = false; _playing = true; });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final active = _playing || _loading;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      // 28px disc inside a 44px hit area.
      Semantics(
        button: true,
        label: _playing ? 'Stop preview' : 'Play preview',
        child: InkResponse(
          onTap: _loading ? null : _toggle,
          radius: 22,
          child: SizedBox(
            width: 44, height: 44,
            child: Center(
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                child: _loading
                    ? Padding(
                        padding: const EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: onPrimary),
                      )
                    : Icon(
                        _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 18, color: onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: active
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 110, height: 16,
                  child: Waveform(
                    samples: const [],
                    progress: _progress,
                    barColor: t.outline,
                    playedColor: t.primary,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      if (!active) ...[
        const SizedBox(width: 6),
        Text('Preview',
            style: AppText.caption(context).copyWith(
                color: t.onSurfaceMuted,
              )),
      ],
    ]);
  }
}
