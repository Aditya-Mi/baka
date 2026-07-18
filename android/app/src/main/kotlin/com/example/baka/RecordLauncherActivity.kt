package com.example.baka

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

/**
 * Invisible entry point launched by the home-screen widget. It exists only to
 * hold the runtime-permission prompt (a foreground service can't request one)
 * and to start/stop [RecordService], then finish immediately — nothing is drawn.
 *
 * Tap while idle → start recording. Tap while recording → stop and save.
 */
class RecordLauncherActivity : Activity() {

    companion object {
        private const val REQ_PERMS = 202
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Toggle: a tap while already recording stops and saves.
        if (RecordService.isRecording) {
            sendServiceAction(RecordService.ACTION_STOP)
            finish()
            return
        }

        val missing = missingPermissions()
        if (missing.isEmpty()) {
            startRecording()
            finish()
        } else {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQ_PERMS)
        }
    }

    private fun missingPermissions(): List<String> {
        val needed = mutableListOf(Manifest.permission.RECORD_AUDIO)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            needed.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        return needed.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_PERMS) {
            val micIndex = permissions.indexOf(Manifest.permission.RECORD_AUDIO)
            val micGranted = micIndex >= 0 &&
                grantResults.getOrNull(micIndex) == PackageManager.PERMISSION_GRANTED
            if (micGranted) {
                startRecording()
            } else {
                Toast.makeText(this, "Enable microphone in Baka to record", Toast.LENGTH_SHORT).show()
            }
            finish()
        }
    }

    private fun startRecording() =
        sendServiceAction(RecordService.ACTION_START, foreground = true)

    private fun sendServiceAction(action: String, foreground: Boolean = false) {
        val intent = Intent(this, RecordService::class.java).setAction(action)
        if (foreground) {
            ContextCompat.startForegroundService(this, intent)
        } else {
            startService(intent)
        }
    }
}
