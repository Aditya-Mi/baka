import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baka/core/audio/capture_importer.dart';
import 'package:baka/core/db/database_helper.dart';
import 'package:baka/models/voice_capture.dart';

class CapturesNotifier extends AsyncNotifier<List<VoiceCapture>> {
  @override
  Future<List<VoiceCapture>> build() async {
    return DatabaseHelper.instance.getAllCaptures();
  }

  /// Imports any pending native captures from disk, then refreshes state.
  /// Returns how many new captures were imported.
  Future<int> importPending() async {
    final count = await CaptureImporter.importPending();
    if (count > 0) {
      state = AsyncData(await DatabaseHelper.instance.getAllCaptures());
    }
    return count;
  }

  /// Reloads the list from the DB without scanning disk.
  Future<void> refresh() async {
    state = AsyncData(await DatabaseHelper.instance.getAllCaptures());
  }

  /// Deletes a capture row and its audio file from disk.
  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    final capture = current.where((c) => c.id == id).firstOrNull;
    await DatabaseHelper.instance.deleteCapture(id);
    if (capture != null) {
      try {
        final f = File(capture.audioPath);
        if (await f.exists()) await f.delete();
      } catch (_) {/* ignore — row already gone */}
    }
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  Future<void> updateCapture(VoiceCapture capture) async {
    await DatabaseHelper.instance.updateCapture(capture);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((c) => c.id == capture.id ? capture : c)
          .toList(),
    );
  }
}

final capturesProvider =
    AsyncNotifierProvider<CapturesNotifier, List<VoiceCapture>>(
  CapturesNotifier.new,
);

/// Count of captures still awaiting processing (Phase 1: freshly imported
/// audio). Drives the home-screen inbox badge.
final unprocessedCapturesCountProvider = Provider<int>((ref) {
  final list = ref.watch(capturesProvider).valueOrNull ?? const [];
  return list
      .where((c) => c.status == CaptureStatus.savedAudio)
      .length;
});
