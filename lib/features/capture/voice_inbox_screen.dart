import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:baka/core/theme/app_theme.dart';
import 'package:baka/core/fonts/font_theme.dart';
import 'package:baka/models/voice_capture.dart';
import 'package:baka/providers/captures_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
    // Pick up any captures the native widget dropped since last scan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(capturesProvider.notifier).importPending();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(VoiceCapture c) async {
    if (_playingId == c.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    await _player.stop();
    if (!await File(c.audioPath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file missing')),
        );
      }
      return;
    }
    await _player.play(DeviceFileSource(c.audioPath));
    if (mounted) setState(() => _playingId = c.id);
  }

  Future<void> _confirmDelete(VoiceCapture c) async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete voice note?',
            style: TextStyle(fontFamily: context.fonts.display,
                fontSize: 18, fontWeight: FontWeight.w600, color: t.onBackground)),
        content: Text('The audio will be permanently removed.',
            style: TextStyle(fontFamily: context.fonts.accent,
                fontSize: 16, color: t.onSurfaceMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: TextStyle(fontFamily: context.fonts.accent,
                    fontSize: 16, color: t.onSurfaceMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(fontFamily: context.fonts.accent,
                    fontSize: 16, color: t.primary, fontWeight: FontWeight.w700)),
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
            style: TextStyle(fontFamily: context.fonts.display,
                fontSize: 22, fontWeight: FontWeight.w600, color: t.onBackground)),
      ),
      body: captures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? _EmptyState(t: t)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return _CaptureTile(
                    capture: c,
                    isPlaying: _playingId == c.id,
                    onPlay: () => _togglePlay(c),
                    onDelete: () => _confirmDelete(c),
                  );
                },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_none_rounded, size: 56, color: t.onSurfaceMuted),
          const SizedBox(height: 20),
          Text('No voice notes yet.',
              style: TextStyle(fontFamily: context.fonts.display,
                  fontSize: 20, fontWeight: FontWeight.w600, color: t.onBackground)),
          const SizedBox(height: 8),
          Text('Tap the Baka widget to record a thought.',
              style: TextStyle(fontFamily: context.fonts.accent,
                  fontSize: 16, color: t.onSurfaceMuted)),
        ],
      ),
    );
  }
}

// ── Capture tile ─────────────────────────────────────────────────────────────

class _CaptureTile extends StatelessWidget {
  final VoiceCapture capture;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  const _CaptureTile({
    required this.capture,
    required this.isPlaying,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.outline, width: 1),
      ),
      child: Row(
        children: [
          // Play / stop button
          Material(
            color: t.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPlay,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 22, color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _StatusChip(status: capture.status, t: t),
                    const SizedBox(width: 8),
                    Text(_relTime(capture.createdAt),
                        style: TextStyle(fontFamily: context.fonts.accent,
                            fontSize: 13, color: t.onSurfaceMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  capture.transcript?.trim().isNotEmpty == true
                      ? capture.transcript!.trim()
                      : 'Voice note · ${_fmtDuration(capture.durationMs)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: context.fonts.body,
                      fontSize: 14, color: t.onBackground),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: t.onSurfaceMuted),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  static String _fmtDuration(int ms) {
    final total = (ms / 1000).round();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

class _StatusChip extends StatelessWidget {
  final CaptureStatus status;
  final BakaTokens t;
  const _StatusChip({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      CaptureStatus.savedAudio          => ('New',        t.primaryContainer, t.primary),
      CaptureStatus.transcribing        => ('Transcribing…', t.primaryContainer, t.primary),
      CaptureStatus.transcribed         => ('Transcribed', t.primaryContainer, t.primary),
      CaptureStatus.analyzing           => ('Analyzing…', t.primaryContainer, t.primary),
      CaptureStatus.analyzed            => ('Ready',      t.secondary.withValues(alpha: 0.25), t.secondary),
      CaptureStatus.failedTranscription => ('Failed',     t.primaryContainer, t.primary),
      CaptureStatus.failedAnalysis      => ('Failed',     t.primaryContainer, t.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: context.fonts.accent, fontSize: 13, color: fg)),
    );
  }
}
