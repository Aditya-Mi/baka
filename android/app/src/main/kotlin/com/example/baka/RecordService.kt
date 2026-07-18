package com.example.baka

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.widget.RemoteViews
import android.widget.Toast
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

/**
 * Foreground service that records a voice capture in the background so the user
 * can keep using the phone. Control lives in an ongoing notification (live
 * timer + Stop + Discard); the home-screen widget toggles it.
 *
 * Audio is the source of truth: it is preserved on Stop and even if the service
 * is killed mid-recording. Only Discard (or a too-short clip) removes it.
 * On stop it drops `voice_captures/<id>.m4a` + `<id>.json` into the shared
 * external files dir for the Flutter side to import.
 */
class RecordService : Service() {

    companion object {
        const val ACTION_START = "com.example.baka.record.START"
        const val ACTION_STOP = "com.example.baka.record.STOP"
        const val ACTION_DISCARD = "com.example.baka.record.DISCARD"

        private const val CHANNEL_ID = "baka_recording"
        private const val NOTIF_ID = 4711
        private const val CAPTURES_SUBDIR = "voice_captures"
        private const val MIN_DURATION_MS = 500L
        private const val SAMPLE_MS = 100L
        private const val TARGET_BARS = 48
        private const val MAX_AMPLITUDE = 32767.0

        @Volatile
        var isRecording = false
            private set
    }

    private var recorder: MediaRecorder? = null
    private var audioFile: File? = null
    private var captureId: String? = null
    private var startedAt = 0L
    private var chronoBase = 0L

    private val amplitudes = ArrayList<Int>()

    private val handler = Handler(Looper.getMainLooper())
    private val ampTicker = object : Runnable {
        override fun run() {
            val amp = try { recorder?.maxAmplitude ?: 0 } catch (_: Exception) { 0 }
            amplitudes.add(amp)
            handler.postDelayed(this, SAMPLE_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> stopAndSave()
            ACTION_DISCARD -> discard()
            ACTION_START -> start()
            else -> if (isRecording) stopAndSave() else start()
        }
        return START_NOT_STICKY
    }

    // ── Recording lifecycle ──────────────────────────────────────────────────

    private fun start() {
        if (isRecording) return
        createChannel()
        chronoBase = SystemClock.elapsedRealtime()
        startForegroundCompat()

        val id = UUID.randomUUID().toString()
        val file = File(capturesDir(), "$id.m4a")
        val rec = buildRecorder()
        try {
            rec.setAudioSource(MediaRecorder.AudioSource.MIC)
            rec.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            rec.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            rec.setAudioEncodingBitRate(128000)
            rec.setAudioSamplingRate(44100)
            rec.setAudioChannels(1)
            rec.setOutputFile(file.absolutePath)
            rec.prepare()
            rec.start()
        } catch (e: Exception) {
            rec.release()
            file.delete()
            toast("Couldn't start recording")
            cleanup()
            return
        }

        recorder = rec
        audioFile = file
        captureId = id
        startedAt = SystemClock.elapsedRealtime()
        isRecording = true
        amplitudes.clear()
        handler.post(ampTicker)
    }

    private fun stopAndSave() {
        val waveform = computeWaveform()
        val duration = stopRecorder()
        val file = audioFile
        val id = captureId
        if (duration >= 0 && file != null && id != null) {
            writeSidecar(id, duration, waveform)
            toast("Saved to inbox")
        }
        cleanup()
    }

    private fun discard() {
        stopRecorder(forceDelete = true)
        cleanup()
    }

    /** Stops + releases the recorder. Returns duration ms, or -1 if the clip was
     *  invalid (too short / stop failed) and its file removed. */
    private fun stopRecorder(forceDelete: Boolean = false): Long {
        if (!isRecording) {
            if (forceDelete) audioFile?.delete()
            return -1
        }
        isRecording = false
        handler.removeCallbacks(ampTicker)
        val duration = SystemClock.elapsedRealtime() - startedAt
        val rec = recorder
        recorder = null
        try {
            rec?.stop()
        } catch (e: RuntimeException) {
            rec?.release()
            audioFile?.delete()
            return -1
        }
        rec?.release()
        if (forceDelete || duration < MIN_DURATION_MS) {
            audioFile?.delete()
            return -1
        }
        return duration
    }

    private fun cleanup() {
        isRecording = false
        handler.removeCallbacks(ampTicker)
        amplitudes.clear()
        stopForegroundCompat()
        stopSelf()
    }

    /** Downsamples the polled amplitudes to [TARGET_BARS] normalized samples
     *  (0..1), scaled to the loudest bar so quiet notes still show a shape. */
    private fun computeWaveform(): List<Double> {
        if (amplitudes.isEmpty()) return emptyList()
        val n = amplitudes.size
        val out = ArrayList<Double>(TARGET_BARS)
        for (i in 0 until TARGET_BARS) {
            val startI = i * n / TARGET_BARS
            val endI = (((i + 1) * n / TARGET_BARS).coerceAtLeast(startI + 1)).coerceAtMost(n)
            var sum = 0.0
            var count = 0
            for (j in startI until endI) {
                sum += amplitudes[j]
                count++
            }
            val avg = if (count > 0) sum / count else 0.0
            out.add((avg / MAX_AMPLITUDE).coerceIn(0.0, 1.0))
        }
        val peak = out.maxOrNull() ?: 0.0
        return if (peak > 0.0) out.map { (it / peak).coerceIn(0.0, 1.0) } else out
    }

    override fun onDestroy() {
        // Safety net: preserve audio if the service is torn down mid-recording.
        if (isRecording) stopAndSave()
        handler.removeCallbacks(ampTicker)
        super.onDestroy()
    }

    // ── Recorder / files ─────────────────────────────────────────────────────

    private fun buildRecorder(): MediaRecorder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(this)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

    private fun capturesDir(): File =
        File(getExternalFilesDir(null), CAPTURES_SUBDIR).apply { mkdirs() }

    private fun writeSidecar(id: String, durationMs: Long, waveform: List<Double>) {
        val fmt = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        val waveArray = JSONArray().apply { waveform.forEach { put(it) } }
        val json = JSONObject().apply {
            put("id", id)
            put("createdAt", fmt.format(Date()))
            put("durationMs", durationMs)
            put("waveform", waveArray)
        }
        try {
            File(capturesDir(), "$id.json").writeText(json.toString())
        } catch (_: Exception) {
            // Audio still exists; import skips until a sidecar appears.
        }
    }

    // ── Notification ─────────────────────────────────────────────────────────

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java)
        if (mgr.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID, "Voice recording", NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows while Baka is recording a voice note"
            setSound(null, null)
            enableVibration(false)
        }
        mgr.createNotificationChannel(channel)
    }

    private fun startForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIF_ID, buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(NOTIF_ID, buildNotification())
        }
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    /** Custom-styled notification. A [Chronometer] ticks the timer on its own,
     *  so the service never needs to push per-second updates. */
    private fun buildNotification(): Notification {
        val stopPi = servicePendingIntent(ACTION_STOP, 1)
        val discardPi = servicePendingIntent(ACTION_DISCARD, 2)

        val collapsed = RemoteViews(packageName, R.layout.notif_recording_collapsed).apply {
            setChronometer(R.id.notif_timer, chronoBase, null, true)
            setOnClickPendingIntent(R.id.notif_btn_stop, stopPi)
        }
        val expanded = RemoteViews(packageName, R.layout.notif_recording_expanded).apply {
            setChronometer(R.id.notif_timer, chronoBase, null, true)
            setOnClickPendingIntent(R.id.notif_btn_stop, stopPi)
            setOnClickPendingIntent(R.id.notif_btn_discard, discardPi)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_mic)
            .setContentTitle("Recording")
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    private fun servicePendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, RecordService::class.java).setAction(action)
        return PendingIntent.getService(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun toast(msg: String) =
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
}
