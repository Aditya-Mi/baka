import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:baka/widgets/app_icon.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/widgets/ink_doodle.dart';
import 'package:baka/core/fonts/font_theme.dart';
import 'package:baka/features/capture/widgets/waveform.dart';
import 'package:baka/features/capture/widgets/permission_priming_sheet.dart';
import 'package:baka/models/voice_capture.dart';
import 'package:baka/providers/captures_provider.dart';
import 'package:baka/widgets/state_views.dart';

/// Voice Inbox — raw voice captures waiting to be processed. Phase 1 lets the
/// user play, review, and delete captures. Later phases add transcription and
/// publishing to the journal, driven by [VoiceCapture.status].
class VoiceInboxScreen extends ConsumerStatefulWidget {
  const VoiceInboxScreen({super.key});

  @override
  ConsumerState<VoiceInboxScreen> createState() => _VoiceInboxScreenState();
}

class _VoiceInboxScreenState extends ConsumerState<VoiceInboxScreen> {
  final _player = AudioPlayer();
  String? _playingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _importing = false;
  bool _micGranted = true;
  bool _primeShown = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingId = null;
          _position = Duration.zero;
        });
      }
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    // Pick up any captures the native widget dropped since last scan, then
    // prime the microphone permission if it hasn't been granted yet.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _import();
      await _checkPermission(prime: true);
    });
  }

  Future<void> _import() async {
    if (mounted) setState(() => _importing = true);
    await ref.read(capturesProvider.notifier).importPending();
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _checkPermission({bool prime = false}) async {
    final granted = await Permission.microphone.isGranted;
    if (mounted) setState(() => _micGranted = granted);
    if (!granted && prime && !_primeShown && mounted) {
      _primeShown = true;
      await _openPriming();
    }
  }

  Future<void> _openPriming() async {
    final granted = await showPermissionPrimingSheet(context);
    if (mounted) setState(() => _micGranted = granted);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(VoiceCapture c) async {
    if (_playingId == c.id) {
      await _player.stop();
      if (mounted) {
        setState(() {
          _playingId = null;
          _position = Duration.zero;
        });
      }
      return;
    }
    await _player.stop();
    if (!await File(c.audioPath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This recording's audio is missing — it may have been deleted.")),
        );
      }
      return;
    }
    if (mounted) {
      setState(() {
        _playingId = c.id;
        _position = Duration.zero;
        _duration = Duration(milliseconds: c.durationMs);
      });
    }
    try {
      await _player.play(DeviceFileSource(c.audioPath));
    } catch (_) {
      // Corrupt or unreadable file: reset the tile instead of a stuck "playing".
      if (mounted) {
        setState(() => _playingId = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't play this recording.")));
      }
    }
  }

  Future<void> _confirmDelete(VoiceCapture c) async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete voice note?'),
        content: const Text('The audio will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: t.onSurfaceMuted),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (_playingId == c.id) {
        await _player.stop();
        if (mounted) setState(() => _playingId = null);
      }
      await ref.read(capturesProvider.notifier).delete(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final captures = ref.watch(capturesProvider);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: Text('Voice Inbox',
            style: AppText.screenTitle(context).copyWith(color: t.primary)),
      ),
      body: captures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Something went wrong loading your voice notes.',
          onRetry: () => ref.invalidate(capturesProvider)),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_importing)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _ProcessingBanner(label: 'Importing voice notes…'),
              ),
            if (!_micGranted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: _MicCta(onTap: _openPriming),
              ),
            Expanded(
              child: list.isEmpty
                  ? _EmptyState(t: t)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final playing = _playingId == c.id;
                        return _CaptureTile(
                          capture: c,
                          isPlaying: playing,
                          position: playing ? _position : Duration.zero,
                          duration: playing ? _duration : Duration.zero,
                          onPlay: () => _togglePlay(c),
                          onDelete: () => _confirmDelete(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Processing banner ────────────────────────────────────────────────────────

class _ProcessingBanner extends StatelessWidget {
  final String label;
  const _ProcessingBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2, color: t.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AppText.label(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: t.onPrimaryContainer,
                  )),
          ),
        ],
      ),
    );
  }
}

// ── Microphone CTA ───────────────────────────────────────────────────────────

class _MicCta extends StatelessWidget {
  final VoidCallback onTap;
  const _MicCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AppIcon(AppIconData.micOff, size: 20, color: t.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Microphone off — tap to enable recording',
                    style: AppText.label(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: t.onPrimaryContainer,
                      )),
              ),
              AppIcon(AppIconData.chevronRight, size: 20, color: t.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final BakaTokens t;
  const _EmptyState({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const InkDoodle(Doodle.voice, width: 150),
            const SizedBox(height: 16),
            Text('No voice notes yet.',
                style: AppText.numeral(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: t.onBackground,
                  )),
            const SizedBox(height: 8),
            SizedBox(
              width: 260,
              child: Text(
                'Tap and hold the widget, or start a recording, to capture your first thought.',
                textAlign: TextAlign.center,
                style: AppText.label(context).copyWith(
                    height: 1.4,
                    color: t.onSurfaceMuted,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Capture tile ─────────────────────────────────────────────────────────────

class _CaptureTile extends StatelessWidget {
  final VoiceCapture capture;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  const _CaptureTile({
    required this.capture,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasTranscript = capture.transcript?.trim().isNotEmpty == true;
    final maxMs = (duration.inMilliseconds > 0
            ? duration.inMilliseconds
            : capture.durationMs)
        .toDouble();
    final progress = isPlaying && maxMs > 0
        ? (position.inMilliseconds / maxMs).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.outline, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play / stop button
          Material(
            color: t.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlay,
              child: SizedBox(
                width: 44, height: 44,
                child: AppIcon(
                  isPlaying ? AppIconData.stop : AppIconData.play,
                  size: 24, color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Middle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StatusChip(status: capture.status, t: t),
                    const SizedBox(width: 8),
                    if (isPlaying)
                      _Times(position: position, totalMs: maxMs.toInt(), t: t)
                    else
                      Text(_relTime(capture.createdAt),
                          style: AppText.small(context).copyWith(
                              color: t.onSurfaceMuted,
                            )),
                  ],
                ),
                const SizedBox(height: 8),
                if (hasTranscript) ...[
                  Text(
                    capture.transcript!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta(context).copyWith(
                        height: 1.35,
                        color: t.onSurface,
                      ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 16,
                    child: Waveform(
                      samples: capture.waveform,
                      progress: progress,
                      barColor: t.outline,
                      playedColor: t.primary,
                    ),
                  ),
                ] else
                  SizedBox(
                    height: 28,
                    child: Waveform(
                      samples: capture.waveform,
                      progress: progress,
                      barColor: t.outline,
                      playedColor: t.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Trash
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDelete,
              child: SizedBox(
                width: 36, height: 36,
                child: AppIcon(AppIconData.trash,
                    size: 20, color: t.onSurfaceMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _relTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(d);
  }
}

class _Times extends StatelessWidget {
  final Duration position;
  final int totalMs;
  final BakaTokens t;
  const _Times({required this.position, required this.totalMs, required this.t});

  @override
  Widget build(BuildContext context) {
    final mono = context.fonts.mono;
    return Row(
      children: [
        Text(_fmt(position),
            style: TextStyle(fontFamily: mono, fontSize: 11, color: t.onSurface)),
        Text(' / ',
            style: TextStyle(fontFamily: mono, fontSize: 11, color: t.onSurfaceMuted)),
        Text(_fmt(Duration(milliseconds: totalMs)),
            style: TextStyle(fontFamily: mono, fontSize: 11, color: t.onSurfaceMuted)),
      ],
    );
  }

  static String _fmt(Duration d) {
    final total = d.inSeconds;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final CaptureStatus status;
  final BakaTokens t;
  const _StatusChip({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final (label, bg, fg) = switch (status) {
      CaptureStatus.savedAudio          => ('New',           t.primaryContainer,     t.onPrimaryContainer),
      CaptureStatus.transcribing        => ('Transcribing…', t.primaryContainer,     t.onPrimaryContainer),
      CaptureStatus.transcribed         => ('Transcribed',   t.primaryContainer,     t.onPrimaryContainer),
      CaptureStatus.analyzing           => ('Analyzing…',    t.primaryContainer,     t.onPrimaryContainer),
      CaptureStatus.analyzed            => ('Ready',         t.secondaryContainer,   t.onSecondaryContainer),
      CaptureStatus.failedTranscription => ('Failed',        error.withValues(alpha: 0.15), error),
      CaptureStatus.failedAnalysis      => ('Failed',        error.withValues(alpha: 0.15), error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: AppText.small(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: fg,
                )),
        ],
      ),
    );
  }
}
