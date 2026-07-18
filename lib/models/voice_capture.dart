/// A raw voice capture recorded from the home-screen widget (native side),
/// then imported into the app DB for later processing.
///
/// The audio file is always the source of truth — it is written to disk before
/// anything else and never overwritten. Transcript / analysis layers are added
/// beside it in later phases via [status].
library;

/// Processing state machine for a capture. Phase 1 only ever reaches
/// [savedAudio]; later phases advance through transcription and analysis.
enum CaptureStatus {
  savedAudio,
  transcribing,
  transcribed,
  analyzing,
  analyzed,
  failedTranscription,
  failedAnalysis;

  static CaptureStatus fromName(String? s) => CaptureStatus.values.firstWhere(
        (v) => v.name == s,
        orElse: () => CaptureStatus.savedAudio,
      );
}

class VoiceCapture {
  final String id;
  final DateTime createdAt;
  final String audioPath;
  final int durationMs;
  final CaptureStatus status;
  final String? transcript;
  final String? entryId;

  const VoiceCapture({
    required this.id,
    required this.createdAt,
    required this.audioPath,
    required this.durationMs,
    this.status = CaptureStatus.savedAudio,
    this.transcript,
    this.entryId,
  });

  VoiceCapture copyWith({
    String? id,
    DateTime? createdAt,
    String? audioPath,
    int? durationMs,
    CaptureStatus? status,
    Object? transcript = _sentinel,
    Object? entryId = _sentinel,
  }) =>
      VoiceCapture(
        id:         id         ?? this.id,
        createdAt:  createdAt  ?? this.createdAt,
        audioPath:  audioPath  ?? this.audioPath,
        durationMs: durationMs ?? this.durationMs,
        status:     status     ?? this.status,
        transcript: transcript == _sentinel ? this.transcript : transcript as String?,
        entryId:    entryId    == _sentinel ? this.entryId    : entryId as String?,
      );

  static const _sentinel = Object();

  Map<String, dynamic> toMap() => {
        'id':          id,
        'created_at':  createdAt.toUtc().toIso8601String(),
        'audio_path':  audioPath,
        'duration_ms': durationMs,
        'status':      status.name,
        'transcript':  transcript,
        'entry_id':    entryId,
      };

  factory VoiceCapture.fromMap(Map<String, dynamic> map) => VoiceCapture(
        id:         map['id']          as String,
        createdAt:  DateTime.parse(map['created_at'] as String).toLocal(),
        audioPath:  map['audio_path']  as String,
        durationMs: map['duration_ms'] as int,
        status:     CaptureStatus.fromName(map['status'] as String?),
        transcript: map['transcript']  as String?,
        entryId:    map['entry_id']    as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceCapture && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
