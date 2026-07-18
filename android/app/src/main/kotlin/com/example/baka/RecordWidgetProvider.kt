package com.example.baka

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews

/**
 * Home-screen widget. Tapping it launches the invisible [RecordLauncherActivity]
 * (start when idle, stop when recording).
 *
 * The widget reflects three states, pushed by [RecordService] via [updateState]:
 * idle (mic + "Record thought"), recording (live timer + stop), and a brief
 * "Saved to inbox" confirmation that returns to idle.
 *
 * Idle uses responsive layouts (API 31+): compact (2x1), wide (4x1) and square
 * (2x2). Recording/saved use a single layout at any size.
 */
class RecordWidgetProvider : AppWidgetProvider() {

    companion object {
        const val STATE_IDLE = 0
        const val STATE_RECORDING = 1
        const val STATE_SAVED = 2

        /** Pushes [state] to every placed instance of this widget. */
        fun updateState(context: Context, state: Int, chronoBase: Long) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(
                ComponentName(context, RecordWidgetProvider::class.java),
            )
            for (id in ids) {
                mgr.updateAppWidget(id, viewsFor(context, state, chronoBase))
            }
        }

        private fun launchIntent(context: Context): PendingIntent {
            val intent = Intent(context, RecordLauncherActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            return PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun clickable(context: Context, layout: Int): RemoteViews =
            RemoteViews(context.packageName, layout).apply {
                setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
            }

        private fun idleViews(context: Context): RemoteViews {
            val square = clickable(context, R.layout.widget_record)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return square
            val compact = clickable(context, R.layout.widget_record_compact)
            val wide = clickable(context, R.layout.widget_record_wide)
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to compact,
                    SizeF(250f, 40f) to wide,
                    SizeF(120f, 100f) to square,
                ),
            )
        }

        private fun recordingLayout(context: Context, layout: Int, chronoBase: Long): RemoteViews =
            clickable(context, layout).apply {
                setChronometer(R.id.widget_timer, chronoBase, null, true)
            }

        private fun recordingViews(context: Context, chronoBase: Long): RemoteViews {
            val square = recordingLayout(context, R.layout.widget_recording_square, chronoBase)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return square
            val compact = recordingLayout(context, R.layout.widget_recording_compact, chronoBase)
            val wide = recordingLayout(context, R.layout.widget_recording_wide, chronoBase)
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to compact,
                    SizeF(250f, 40f) to wide,
                    SizeF(120f, 100f) to square,
                ),
            )
        }

        private fun savedViews(context: Context): RemoteViews {
            val square = clickable(context, R.layout.widget_saved_square)
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return square
            val row = clickable(context, R.layout.widget_saved)
            return RemoteViews(
                mapOf(
                    SizeF(110f, 40f) to row,
                    SizeF(250f, 40f) to row,
                    SizeF(120f, 100f) to square,
                ),
            )
        }

        fun viewsFor(context: Context, state: Int, chronoBase: Long): RemoteViews =
            when (state) {
                STATE_RECORDING -> recordingViews(context, chronoBase)
                STATE_SAVED -> savedViews(context)
                else -> idleViews(context)
            }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // On (re)bind, reflect whatever the service is currently doing.
        val state = if (RecordService.isRecording) STATE_RECORDING else STATE_IDLE
        val base = RecordService.chronoBaseOrZero()
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, viewsFor(context, state, base))
        }
    }
}
